import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/application/sync_service.dart';
import 'package:mobile/domain/record_status.dart';
import 'package:mobile/domain/repositories/health_record_local_repository.dart';
import 'package:mobile/infrastructure/api/api_client.dart';
import 'package:mobile/infrastructure/connectivity/connectivity_service.dart';
import 'package:mobile/infrastructure/database/app_database.dart';

// ============================================================
// FAKE SERVER
// Behaves like the FastAPI backend: create is idempotent per
// client_record_id, confirm is idempotent / 409 on different data.
// ============================================================

class FakeServer implements ApiClient {
  final Map<String, Map<String, dynamic>> records = {};
  final Map<String, String> byClientId = {};
  final List<String> calls = [];

  bool offline = false;
  bool loginExpired = false;

  /// Next N calls to [endpoint] fail with this error.
  final Map<String, List<Object>> failures = {};

  /// Simulates "the server did the work but the reply never arrived".
  bool loseNextCreateResponse = false;

  int _nextId = 1;

  void failNext(String endpoint, Object error, {int times = 1}) {
    failures.putIfAbsent(endpoint, () => []).addAll(List.filled(times, error));
  }

  void _enter(String endpoint) {
    calls.add(endpoint);

    if (offline) {
      throw NetworkException(const SocketException('offline'));
    }
    if (loginExpired) {
      throw const LoginRequiredException();
    }

    final queued = failures[endpoint];
    if (queued != null && queued.isNotEmpty) {
      throw queued.removeAt(0);
    }
  }

  Map<String, dynamic> _bump(String id, Map<String, dynamic> changes) {
    final record = records[id]!..addAll(changes);
    record['version'] = (record['version'] as int) + 1;
    return Map.of(record);
  }

  @override
  Future<Map<String, dynamic>> createRecord({
    required String clientRecordId,
    required String rawInput,
    String? inputLanguage,
  }) async {
    _enter('create');

    final existing = byClientId[clientRecordId];
    if (existing != null) {
      return Map.of(records[existing]!);
    }

    final id = 'srv-${_nextId++}';
    records[id] = {
      'id': id,
      'worker_id': 'worker-1',
      'client_record_id': clientRecordId,
      'raw_input': rawInput,
      'record_status': 'draft',
      'confirmed_data': null,
      'version': 1,
    };
    byClientId[clientRecordId] = id;

    if (loseNextCreateResponse) {
      loseNextCreateResponse = false;
      throw NetworkException(const SocketException('reply lost'));
    }

    return Map.of(records[id]!);
  }

  @override
  Future<Map<String, dynamic>> processAudio({
    required String serverRecordId,
    required File audioFile,
    required String language,
  }) async {
    _enter('process-audio');
    final updated = _bump(serverRecordId, {
      'ai_suggested_data': {'patient_name': 'Ravi', 'age': 35},
    });
    return {
      ...updated,
      'transcript': 'ರವಿ',
      'english': 'Ravi, 35',
      'analyzed': {'patient_name': 'Ravi', 'age': 35},
    };
  }

  @override
  Future<Map<String, dynamic>> processText(String serverRecordId) async {
    _enter('process');
    return {
      ..._bump(serverRecordId, {}),
      'ai_suggested_data': {'age': 42},
    };
  }

  @override
  Future<Map<String, dynamic>> confirm({
    required String serverRecordId,
    required Map<String, dynamic> confirmedData,
  }) async {
    _enter('confirm');
    final record = records[serverRecordId]!;

    if (record['record_status'] == 'confirmed') {
      if (_sameData(record['confirmed_data'], confirmedData)) {
        return Map.of(record);
      }
      throw ApiException(409, {
        'message': 'conflict',
        'server_record': Map.of(record),
      });
    }

    return _bump(serverRecordId, {
      'record_status': 'confirmed',
      'confirmed_data': confirmedData,
    });
  }

  @override
  Future<Map<String, dynamic>> getRecord(String serverRecordId) async {
    _enter('get');
    return Map.of(records[serverRecordId]!);
  }

  @override
  Future<bool> ping() async => !offline;

  static bool _sameData(Object? a, Map<String, dynamic> b) =>
      a is Map && a.length == b.length && b.keys.every((k) => '${a[k]}' == '${b[k]}');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

// ============================================================
// TESTS
// ============================================================

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late HealthRecordLocalRepository repo;
  late FakeServer server;
  late ConnectivityService connectivity;
  late SyncService sync;
  late DateTime now;
  late Directory tempDir;
  late String audioPath;

  setUp(() async {
    database = AppDatabase(testMode: true);
    repo = HealthRecordLocalRepository(database);
    server = FakeServer();
    now = DateTime(2026, 11, 16, 10);

    connectivity = ConnectivityService(
      probe: server.ping,
      networkChanges: const Stream.empty(),
      currentNetwork: () async => [ConnectivityResult.wifi],
    );
    await connectivity.checkNow();

    sync = SyncService(
      username: 'asha_demo',
      repository: repo,
      api: server,
      connectivity: connectivity,
      clock: () => now,
    );

    tempDir = await Directory.systemTemp.createTemp('aashanet_sync_test');
    audioPath = '${tempDir.path}/note.m4a';
    await File(audioPath).writeAsBytes([1, 2, 3]);
  });

  tearDown(() async {
    sync.dispose();
    connectivity.dispose();
    await database.close();
    await tempDir.delete(recursive: true);
  });

  Future<String> saveVoiceNote() => repo.saveNewRecord(
        ownerUsername: 'asha_demo',
        rawInput: '[Voice recording]',
        inputLanguage: 'Kannada',
        audioPath: audioPath,
      );

  Future<HealthRecord> reload(String id) async => (await repo.getRecord(id))!;

  test('1. online: record is uploaded and AI suggestions come back', () async {
    final id = await saveVoiceNote();

    await sync.syncAll();
    final record = await reload(id);

    expect(record.serverRecordId, 'srv-1');
    expect(record.aiStatus, AiStatus.completed);
    expect(record.aiTranscript, 'ರವಿ');
    expect(HealthRecordLocalRepository.decodeJson(record.aiSuggestedData),
        {'patient_name': 'Ravi', 'age': 35});
    expect(record.syncStatus, SyncStatus.synced);
    expect(record.recordStatus, RecordStatus.draft,
        reason: 'AI output still needs the worker to review it');
  });

  test('2. offline: record stays on the phone, pending, nothing lost',
      () async {
    server.offline = true;
    final id = await saveVoiceNote();

    await sync.syncAll();
    final record = await reload(id);

    expect(record.syncStatus, SyncStatus.pendingSync);
    expect(record.lastSyncError, SyncError.network);
    expect(record.aiStatus, AiStatus.pending);
    expect(record.serverRecordId, isNull);
    expect(record.audioPath, audioPath);
    expect(await File(audioPath).exists(), isTrue);
  });

  test('5/6/9. connectivity returns: pending record syncs and AI resumes',
      () async {
    server.offline = true;
    final id = await saveVoiceNote();
    await sync.syncAll();

    server.offline = false;
    await sync.syncAll();
    final record = await reload(id);

    expect(record.syncStatus, SyncStatus.synced);
    expect(record.aiStatus, AiStatus.completed);
    expect(server.records.length, 1);
  });

  test('7. failed upload keeps the record and schedules a retry', () async {
    server.failNext('create', const ApiException(500, 'boom'));
    final id = await saveVoiceNote();

    await sync.syncAll();
    final record = await reload(id);

    expect(record.syncStatus, SyncStatus.syncFailed);
    expect(record.syncAttempts, 1);
    expect(record.nextSyncAt, now.add(const Duration(seconds: 30)));
    expect(record.lastSyncError, SyncError.server);

    // Not retried before the wait is over.
    server.calls.clear();
    await sync.syncAll();
    expect(server.calls, isEmpty);
  });

  test('8. retry after a lost reply does not create a duplicate', () async {
    server.loseNextCreateResponse = true;
    final id = await saveVoiceNote();

    await sync.syncAll(); // server created it, but the phone never heard
    expect((await reload(id)).serverRecordId, isNull);

    await sync.syncAll(); // retry with the same client id
    final record = await reload(id);

    expect(server.records.length, 1, reason: 'no duplicate on the server');
    expect(record.serverRecordId, 'srv-1');
    expect(record.syncStatus, SyncStatus.synced);
  });

  test('8b. retry after failure succeeds once the wait has passed', () async {
    server.failNext('create', const ApiException(503, 'busy'));
    final id = await saveVoiceNote();
    await sync.syncAll();

    now = now.add(const Duration(minutes: 1));
    await sync.syncAll();

    expect((await reload(id)).syncStatus, SyncStatus.synced);
    expect(server.records.length, 1);
  });

  test('AI busy: record reaches the server, AI is retried later', () async {
    server.failNext('process-audio', const ApiException(503, 'busy'));
    final id = await saveVoiceNote();

    await sync.syncAll();
    var record = await reload(id);

    expect(record.serverRecordId, 'srv-1');
    expect(record.aiStatus, AiStatus.pending);
    expect(record.syncStatus, SyncStatus.syncFailed);
    expect(record.lastSyncError, SyncError.aiBusy);

    now = now.add(const Duration(minutes: 1));
    await sync.syncAll();
    record = await reload(id);

    expect(record.aiStatus, AiStatus.completed);
    expect(server.calls.where((c) => c == 'create').length, 1,
        reason: 'already on the server, so the retry goes straight to AI');
    expect(server.records.length, 1);
  });

  test('worker confirmation is sent and the record ends synced', () async {
    final id = await saveVoiceNote();
    await sync.syncAll();

    await repo.saveConfirmation(id: id, confirmedData: {'age': 35});
    final record = await sync.syncRecord(id);

    expect(record!.syncStatus, SyncStatus.synced);
    expect(server.records['srv-1']!['record_status'], 'confirmed');
  });

  test('confirmation made offline is sent later', () async {
    final id = await saveVoiceNote();
    await sync.syncAll();

    server.offline = true;
    await repo.saveConfirmation(id: id, confirmedData: {'age': 35});
    await sync.syncRecord(id);
    expect((await reload(id)).syncStatus, SyncStatus.pendingSync);

    server.offline = false;
    await sync.syncAll();
    expect((await reload(id)).syncStatus, SyncStatus.synced);
  });

  test('conflict: different confirmed data on the server is not overwritten',
      () async {
    final id = await saveVoiceNote();
    await sync.syncAll();
    server.records['srv-1']!
      ..['record_status'] = 'confirmed'
      ..['confirmed_data'] = {'age': 36};

    await repo.saveConfirmation(id: id, confirmedData: {'age': 35});
    await sync.syncRecord(id);
    final record = await reload(id);

    expect(record.syncStatus, SyncStatus.conflict);
    expect(HealthRecordLocalRepository.decodeJson(record.confirmedData),
        {'age': 35}, reason: 'local version kept');
    expect(HealthRecordLocalRepository.decodeJson(record.conflictServerData),
        {'age': 36}, reason: 'server version kept');
    expect(server.records['srv-1']!['confirmed_data'], {'age': 36});
  });

  test('expired login: sync stops, records stay queued, UI is told', () async {
    server.loginExpired = true;
    final id = await saveVoiceNote();

    await sync.syncAll();
    final record = await reload(id);

    expect(record.syncStatus, SyncStatus.pendingSync);
    expect(record.lastSyncError, SyncError.loginRequired);
    expect(record.syncAttempts, 0, reason: 'not counted as a failure');
    expect(sync.activity.value, SyncActivity.loginRequired);
  });

  test('missing audio file: AI marked failed, worker can still review',
      () async {
    final id = await saveVoiceNote();
    await File(audioPath).delete();

    await sync.syncAll();
    final record = await reload(id);

    expect(record.aiStatus, AiStatus.failed);
    expect(record.syncStatus, SyncStatus.synced);
    expect(server.calls, isNot(contains('process-audio')));
  });

  test('typed record is analysed by the server text endpoint', () async {
    final id = await repo.saveNewRecord(
      ownerUsername: 'asha_demo',
      rawInput: 'Ramesh is 42 years old',
      inputLanguage: 'en',
    );

    await sync.syncAll();
    final record = await reload(id);

    expect(record.aiStatus, AiStatus.completed);
    expect(HealthRecordLocalRepository.decodeJson(record.aiSuggestedData),
        {'age': 42});
  });

  test('3/4. app restart: interrupted upload is resumed without duplicates',
      () async {
    final id = await saveVoiceNote();
    await repo.markUploading(id); // app was killed mid-upload

    sync.dispose();
    final restarted = SyncService(
      username: 'asha_demo',
      repository: repo,
      api: server,
      connectivity: connectivity,
      clock: () => now,
    );
    await restarted.start();
    await restarted.syncAll();
    restarted.dispose();

    expect((await reload(id)).syncStatus, SyncStatus.synced);
    expect(server.records.length, 1);
  });

  test('10. overlapping sync requests never upload a record twice', () async {
    await saveVoiceNote();

    await Future.wait([sync.syncAll(), sync.syncAll(), sync.syncAll()]);

    expect(server.calls.where((c) => c == 'process-audio').length, 1);
    expect(server.records.length, 1);
  });

  test('another user\'s records are never synced with this login', () async {
    await repo.saveNewRecord(ownerUsername: 'someone_else', rawInput: 'x');

    await sync.syncAll();

    expect(server.calls, isEmpty);
  });

  test('backoff grows and is capped at one hour', () {
    expect(SyncService.backoffFor(1), const Duration(seconds: 30));
    expect(SyncService.backoffFor(2), const Duration(minutes: 1));
    expect(SyncService.backoffFor(3), const Duration(minutes: 2));
    expect(SyncService.backoffFor(20), const Duration(hours: 1));
  });
}
