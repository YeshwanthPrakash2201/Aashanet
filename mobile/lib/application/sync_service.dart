import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../domain/record_status.dart';
import '../domain/repositories/health_record_local_repository.dart';
import '../infrastructure/api/api_client.dart';
import '../infrastructure/connectivity/connectivity_service.dart';
import '../infrastructure/database/app_database.dart';

/// What the sync service is doing, for the UI.
enum SyncActivity { idle, syncing, loginRequired }

enum _Outcome { done, stopOffline, stopLoginRequired }

/// Sends locally saved records to the backend whenever it is reachable.
///
/// Each record moves through up to three server steps, and each step is
/// safe to repeat, so an attempt interrupted at any point (lost
/// connection, app closed, phone switched off) is simply run again:
///
///   1. create  - POST /health-records with the record's client UUID
///                (the server returns the same record on a retry)
///   2. AI      - process-audio / process (needs internet; the result is
///                a suggestion for the worker to review)
///   3. confirm - POST /confirm with the worker's reviewed details
///                (same data again is accepted; different data -> conflict)
///
/// A record is marked synced only after the server has answered
/// successfully. Failures never delete anything: the record stays on
/// the phone and is retried with an increasing wait.
class SyncService {
  SyncService({
    required this.username,
    required this.repository,
    required this.api,
    required this.connectivity,
    DateTime Function()? clock,
    this.periodicInterval = const Duration(minutes: 1),
  }) : _clock = clock ?? DateTime.now;

  final String username;
  final HealthRecordLocalRepository repository;
  final ApiClient api;
  final ConnectivityService connectivity;
  final DateTime Function() _clock;
  final Duration periodicInterval;

  final ValueNotifier<SyncActivity> activity =
      ValueNotifier<SyncActivity>(SyncActivity.idle);

  Timer? _timer;
  Future<void> _queue = Future.value();
  bool _started = false;

  // ==========================================================
  // LIFECYCLE
  // ==========================================================

  /// Prepares local data and starts syncing automatically: now, whenever
  /// the server becomes reachable, and every [periodicInterval] while
  /// online (to pick up records whose retry wait has passed).
  Future<void> start() async {
    if (_started) {
      return;
    }

    _started = true;

    await repository.claimUnownedRecords(username);
    await repository.resetInterruptedUploads();

    connectivity.isOnline.addListener(_onConnectivityChanged);
    _timer = Timer.periodic(periodicInterval, (_) {
      if (connectivity.isOnline.value) {
        syncAll();
      }
    });

    if (connectivity.isOnline.value) {
      unawaited(syncAll());
    }
  }

  void _onConnectivityChanged() {
    if (connectivity.isOnline.value) {
      syncAll();
    }
  }

  void dispose() {
    connectivity.isOnline.removeListener(_onConnectivityChanged);
    _timer?.cancel();
    _timer = null;
    _started = false;
  }

  // ==========================================================
  // PUBLIC ENTRY POINTS
  // ==========================================================

  /// Syncs every record that is due. Calls made while a sync is running
  /// wait for it, so two runs never upload the same record at once.
  Future<void> syncAll() => _serialized(_syncAllNow);

  /// Syncs one record immediately (ignoring its retry wait), e.g. right
  /// after the worker saves or confirms it. Returns the updated record.
  Future<HealthRecord?> syncRecord(String id) {
    return _serialized(() async {
      final record = await repository.getRecord(id);

      if (record != null && SyncStatus.needsSync.contains(record.syncStatus)) {
        final outcome = await _syncOne(record);
        _applyOutcome(outcome);
      }

      return repository.getRecord(id);
    });
  }

  Future<T> _serialized<T>(Future<T> Function() task) {
    final result = _queue.then((_) => task());
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<void> _syncAllNow() async {
    final due = await repository.getRecordsDueForSync(username, now: _clock());

    if (due.isEmpty) {
      if (activity.value == SyncActivity.syncing) {
        activity.value = SyncActivity.idle;
      }
      return;
    }

    activity.value = SyncActivity.syncing;
    var outcome = _Outcome.done;

    for (final record in due) {
      outcome = await _syncOne(record);

      if (outcome != _Outcome.done) {
        break;
      }
    }

    _applyOutcome(outcome);
  }

  void _applyOutcome(_Outcome outcome) {
    activity.value = outcome == _Outcome.stopLoginRequired
        ? SyncActivity.loginRequired
        : SyncActivity.idle;

    if (outcome == _Outcome.stopOffline) {
      // Let the indicator catch up; the next connectivity change or
      // periodic check restarts the sync.
      unawaited(connectivity.checkNow());
    }
  }

  // ==========================================================
  // ONE RECORD
  // ==========================================================

  Future<_Outcome> _syncOne(HealthRecord record) async {
    final id = record.id;
    await repository.markUploading(id);

    try {
      var current = record;

      // ---- Step 1: make sure the server has the record ----------
      if (current.serverRecordId == null) {
        final created = await api.createRecord(
          clientRecordId: current.clientRecordId ?? current.id,
          rawInput: current.rawInput,
          inputLanguage: current.inputLanguage,
        );

        await repository.linkServerRecord(
          localRecordId: id,
          serverRecordId: created['id'].toString(),
          workerId: created['worker_id'].toString(),
          serverVersion: created['version'] as int?,
        );

        current = (await repository.getRecord(id))!;
      }

      final serverId = current.serverRecordId!;

      // ---- Step 2: AI processing (only before confirmation) -----
      if (current.recordStatus != RecordStatus.confirmed &&
          current.aiStatus == AiStatus.pending) {
        final aiOutcome = await _runAi(current, serverId);

        if (aiOutcome != null) {
          return aiOutcome;
        }

        current = (await repository.getRecord(id))!;
      }

      // ---- Step 3: send the worker's confirmation ---------------
      if (current.recordStatus == RecordStatus.confirmed) {
        final confirmed = HealthRecordLocalRepository.decodeJson(
              current.confirmedData,
            ) ??
            const <String, dynamic>{};

        try {
          final result = await api.confirm(
            serverRecordId: serverId,
            confirmedData: confirmed,
          );

          await repository.markSynced(
            id,
            serverVersion: result['version'] as int?,
          );
        } on ApiException catch (e) {
          if (e.statusCode == 409) {
            await _recordConflict(id, e);
            return _Outcome.done;
          }
          rethrow;
        }

        return _Outcome.done;
      }

      // Not confirmed yet: the server now has everything the phone has
      // (the record and, if available, the AI suggestions). It goes
      // back in the queue when the worker confirms it.
      await repository.markSynced(id, serverVersion: current.serverVersion);
      return _Outcome.done;
    } on LoginRequiredException {
      await repository.markPendingSync(id, reason: SyncError.loginRequired);
      return _Outcome.stopLoginRequired;
    } on NetworkException {
      await repository.markPendingSync(id, reason: SyncError.network);
      return _Outcome.stopOffline;
    } on ApiException catch (e) {
      await _scheduleRetry(
        record,
        e.isServerError ? SyncError.server : SyncError.rejected,
      );
      return _Outcome.done;
    } catch (e) {
      debugPrint('SYNC: unexpected error ${e.runtimeType}');
      await _scheduleRetry(record, SyncError.server);
      return _Outcome.done;
    }
  }

  /// Runs AI processing. Returns null to continue with the next step,
  /// or an outcome to stop here for this record.
  Future<_Outcome?> _runAi(HealthRecord record, String serverId) async {
    final audioPath = record.audioPath;

    try {
      if (audioPath != null) {
        final file = File(audioPath);

        if (!await file.exists()) {
          // The recording is gone; AI cannot run. The worker can still
          // review and enter the details by hand.
          await repository.markAiFailed(record.id);
          return null;
        }

        final result = await api.processAudio(
          serverRecordId: serverId,
          audioFile: file,
          language: record.inputLanguage ?? 'Kannada',
        );

        await repository.saveAiResult(
          id: record.id,
          suggestedData: _asMap(result['analyzed']),
          transcript: result['transcript'] as String?,
          translation: result['english'] as String?,
          serverVersion: result['version'] as int?,
        );
      } else {
        final result = await api.processText(serverId);

        await repository.saveAiResult(
          id: record.id,
          suggestedData: _asMap(result['ai_suggested_data']),
          serverVersion: result['version'] as int?,
        );
      }

      return null;
    } on ApiException catch (e) {
      if (e.statusCode == 503 || e.statusCode == 504) {
        // AI busy: the record is safely on the server; try AI later.
        await _scheduleRetry(record, SyncError.aiBusy);
        return _Outcome.done;
      }

      if (e.statusCode == 409) {
        // Already confirmed on the server (e.g. from another device).
        await _adoptServerConfirmation(record.id, serverId);
        return _Outcome.done;
      }

      if (e.statusCode == 400 ||
          e.statusCode == 413 ||
          e.statusCode == 415 ||
          e.statusCode == 502) {
        // The AI cannot use this input; retrying will not help. The
        // worker can review and type the details instead.
        await repository.markAiFailed(record.id);
        return null;
      }

      rethrow;
    }
  }

  // ==========================================================
  // CONFLICTS
  // ==========================================================

  Future<void> _recordConflict(String id, ApiException e) async {
    final detail = e.detail;
    final serverRecord = detail is Map<String, dynamic>
        ? detail['server_record']
        : null;

    Map<String, dynamic> serverData = const {};
    int? serverVersion;

    if (serverRecord is Map<String, dynamic>) {
      serverData = _asMap(serverRecord['confirmed_data']);
      serverVersion = serverRecord['version'] as int?;
    }

    await repository.markConflict(
      id: id,
      serverConfirmedData: serverData,
      serverVersion: serverVersion,
    );
  }

  Future<void> _adoptServerConfirmation(String id, String serverId) async {
    final server = await api.getRecord(serverId);

    await repository.markConflict(
      id: id,
      serverConfirmedData: _asMap(server['confirmed_data']),
      serverVersion: server['version'] as int?,
    );
  }

  // ==========================================================
  // RETRIES
  // ==========================================================

  /// Wait before the next automatic attempt: 30 s, 1 min, 2 min, 4 min
  /// ... up to 1 hour.
  static Duration backoffFor(int attempts) {
    final seconds = 30 * pow(2, max(0, attempts - 1)).toInt();
    return Duration(seconds: min(seconds, 3600));
  }

  Future<void> _scheduleRetry(HealthRecord record, String reason) async {
    final attempts = record.syncAttempts + 1;

    await repository.markSyncFailed(
      id: record.id,
      reason: reason,
      attempts: attempts,
      retryAt: _clock().add(backoffFor(attempts)),
    );
  }

  static Map<String, dynamic> _asMap(Object? value) {
    return value is Map<String, dynamic> ? value : <String, dynamic>{};
  }
}
