// End-to-end check of the phone's sync engine against a REAL running
// backend (FastAPI + PostgreSQL + Gemini). Skipped unless configured:
//
//   $env:LIVE_API_URL = "http://127.0.0.1:8000"
//   $env:LIVE_TOKEN   = "<access token of an asha_worker account>"
//   $env:LIVE_AUDIO   = "C:\path\to\sample.m4a"     (optional)
//   flutter test test/live/live_sync_test.dart
//
// It creates real records on the server. The client ids it used are
// printed (LIVE_CLIENT_IDS=...) so they can be cleaned up afterwards.
//
// Note: TestWidgetsFlutterBinding is deliberately NOT initialised here,
// because it blocks real HTTP requests.

import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/application/sync_service.dart';
import 'package:mobile/domain/record_status.dart';
import 'package:mobile/domain/repositories/health_record_local_repository.dart';
import 'package:mobile/infrastructure/api/api_client.dart';
import 'package:mobile/infrastructure/connectivity/connectivity_service.dart';
import 'package:mobile/infrastructure/database/app_database.dart';

void main() {
  final env = Platform.environment;
  final apiUrl = env['LIVE_API_URL'];
  final token = env['LIVE_TOKEN'];
  final audio = env['LIVE_AUDIO'];
  final skip = apiUrl == null || token == null
      ? 'set LIVE_API_URL and LIVE_TOKEN to run against a real backend'
      : null;

  test('offline save -> reconnect -> upload, AI, confirm, no duplicates',
      () async {
    final database = AppDatabase(testMode: true);
    final repo = HealthRecordLocalRepository(database);
    final clientIds = <String>[];

    SyncService serviceFor(String url) {
      final api = ApiClient(baseUrl: url, tokenProvider: () async => token);
      final connectivity = ConnectivityService(
        probe: api.ping,
        networkChanges: const Stream.empty(),
        currentNetwork: () async => [ConnectivityResult.wifi],
      );
      return SyncService(
        username: 'asha_demo',
        repository: repo,
        api: api,
        connectivity: connectivity,
      );
    }

    // ---- 1. Offline: server unreachable ---------------------------
    final offline = serviceFor('http://127.0.0.1:9');
    final id = await repo.saveNewRecord(
      ownerUsername: 'asha_demo',
      rawInput: '[Voice recording]',
      inputLanguage: 'Kannada',
      audioPath: audio,
    );
    final typedId = await repo.saveNewRecord(
      ownerUsername: 'asha_demo',
      rawInput: 'Ramesh is 42 years old and has fever',
      inputLanguage: 'en',
    );
    clientIds.addAll([id, typedId]);

    await offline.syncAll();
    var record = (await repo.getRecord(id))!;
    stdout.writeln('offline  : sync=${record.syncStatus} ai=${record.aiStatus} '
        'error=${record.lastSyncError} server=${record.serverRecordId}');
    expect(record.syncStatus, SyncStatus.pendingSync);
    expect(record.serverRecordId, isNull);

    // ---- 2. Connection back: upload + AI --------------------------
    final online = serviceFor(apiUrl!);
    final watch = Stopwatch()..start();
    await online.syncAll();
    watch.stop();

    record = (await repo.getRecord(id))!;
    final typed = (await repo.getRecord(typedId))!;
    stdout.writeln('online   : sync=${record.syncStatus} ai=${record.aiStatus} '
        'server=${record.serverRecordId} (${watch.elapsed.inSeconds}s)');
    stdout.writeln('ai fields: ${record.aiSuggestedData}');
    stdout.writeln('typed    : sync=${typed.syncStatus} ai=${typed.aiStatus} '
        'fields=${typed.aiSuggestedData}');
    expect(record.serverRecordId, isNotNull);
    expect(record.syncStatus, SyncStatus.synced);
    expect(typed.aiStatus, AiStatus.completed);

    // ---- 3. Lost reply: retry create with the same client id ------
    final api = ApiClient(baseUrl: apiUrl, tokenProvider: () async => token);
    final again = await api.createRecord(
      clientRecordId: record.clientRecordId!,
      rawInput: record.rawInput,
      inputLanguage: record.inputLanguage,
    );
    stdout.writeln('retry    : same server id = ${again['id'] == record.serverRecordId}');
    expect(again['id'], record.serverRecordId);

    // ---- 4. Worker confirms; sent to the server -------------------
    await repo.saveConfirmation(id: typedId, confirmedData: {
      'patient_name': 'Ramesh',
      'age': 42,
      'symptoms': ['fever'],
      'duration': null,
    });
    final confirmed = (await online.syncRecord(typedId))!;
    final server = await api.getRecord(confirmed.serverRecordId!);
    stdout.writeln('confirm  : local=${confirmed.syncStatus} '
        'server=${server['record_status']} v${server['version']}');
    expect(confirmed.syncStatus, SyncStatus.synced);
    expect(server['record_status'], 'confirmed');

    // ---- 5. Same confirmation again is safe; different is a conflict
    await api.confirm(
      serverRecordId: confirmed.serverRecordId!,
      confirmedData: {
        'patient_name': 'Ramesh',
        'age': 42,
        'symptoms': ['fever'],
        'duration': null,
      },
    );
    Object? conflictError;
    try {
      await api.confirm(
        serverRecordId: confirmed.serverRecordId!,
        confirmedData: {'patient_name': 'Ramesh', 'age': 43},
      );
    } on ApiException catch (e) {
      conflictError = e.statusCode;
    }
    stdout.writeln('conflict : status=$conflictError');
    expect(conflictError, 409);

    stdout.writeln('LIVE_CLIENT_IDS=${clientIds.join(',')}');
    await database.close();
  }, skip: skip, timeout: const Timeout(Duration(minutes: 5)));
}
