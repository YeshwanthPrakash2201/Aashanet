import 'dart:io';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/domain/record_status.dart';
import 'package:mobile/domain/repositories/health_record_local_repository.dart';
import 'package:mobile/infrastructure/database/app_database.dart';
import 'package:mobile/infrastructure/ids.dart';

// Schema exactly as app versions with database version 3 created it.
const _v3Table = '''
CREATE TABLE health_records (
  id TEXT NOT NULL,
  server_record_id TEXT NULL,
  worker_id TEXT NULL,
  raw_input TEXT NOT NULL,
  input_language TEXT NULL,
  audio_path TEXT NULL,
  ai_status TEXT NOT NULL DEFAULT 'pending_review',
  record_status TEXT NOT NULL DEFAULT 'draft',
  sync_status TEXT NOT NULL DEFAULT 'pending',
  created_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
  updated_at INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)),
  PRIMARY KEY (id)
)''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Health record can be saved and retrieved locally', () async {
    final database = AppDatabase(testMode: true);
    const recordId = 'test-record-001';

    await database.insertHealthRecord(
      HealthRecordsCompanion.insert(
        id: recordId,
        workerId: const Value(null),
        rawInput: 'Ramesh is 42 years old and has fever',
        inputLanguage: const Value('en'),
        audioPath: const Value('/local/audio/test.m4a'),
      ),
    );

    final records = await database.getAllHealthRecords();

    expect(records.length, 1);
    expect(records.first.id, recordId);
    expect(records.first.rawInput, 'Ramesh is 42 years old and has fever');
    expect(records.first.workerId, null);
    expect(records.first.syncStatus, SyncStatus.pendingSync);
    expect(records.first.aiStatus, AiStatus.pending);

    await database.close();
  });

  group('migration to v4', () {
    test('upgrades a v3 database and keeps every record', () async {
      final database = AppDatabase.forExecutor(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute(_v3Table);
            raw.execute(
              "INSERT INTO health_records (id, raw_input, sync_status, audio_path) "
              "VALUES ('local-1', 'offline note', 'pending', '/a.m4a')",
            );
            raw.execute(
              "INSERT INTO health_records (id, server_record_id, raw_input, sync_status) "
              "VALUES ('local-2', 'srv-2', 'failed note', 'failed')",
            );
            raw.execute(
              "INSERT INTO health_records (id, server_record_id, raw_input, sync_status) "
              "VALUES ('local-3', 'srv-3', 'done note', 'synced')",
            );
            raw.execute('PRAGMA user_version = 3');
          },
        ),
      );

      final records = {
        for (final r in await database.getAllHealthRecords()) r.id: r,
      };

      expect(records.length, 3);

      expect(records['local-1']!.syncStatus, SyncStatus.pendingSync);
      expect(records['local-1']!.aiStatus, AiStatus.pending);
      expect(records['local-1']!.recordStatus, RecordStatus.draft);
      expect(records['local-1']!.audioPath, '/a.m4a');

      expect(records['local-2']!.syncStatus, SyncStatus.syncFailed);
      expect(records['local-2']!.serverRecordId, 'srv-2');

      expect(records['local-3']!.syncStatus, SyncStatus.synced);
      expect(records['local-3']!.aiStatus, AiStatus.completed);
      expect(records['local-3']!.recordStatus, RecordStatus.confirmed);

      for (final record in records.values) {
        expect(isUuid(record.clientRecordId!), isTrue,
            reason: 'every old record needs a UUID for duplicate protection');
        expect(record.ownerUsername, isNull);
        expect(record.syncAttempts, 0);
      }

      final ids = records.values.map((r) => r.clientRecordId).toSet();
      expect(ids.length, 3, reason: 'UUIDs must be unique');

      await database.close();
    });

    test('upgrades a v2 database (no server_record_id column)', () async {
      final database = AppDatabase.forExecutor(
        NativeDatabase.memory(
          setup: (raw) {
            raw.execute(
              _v3Table.replaceFirst('server_record_id TEXT NULL,', ''),
            );
            raw.execute(
              "INSERT INTO health_records (id, raw_input) VALUES ('old', 'x')",
            );
            raw.execute('PRAGMA user_version = 2');
          },
        ),
      );

      final records = await database.getAllHealthRecords();

      expect(records.single.id, 'old');
      expect(records.single.serverRecordId, isNull);
      expect(records.single.syncStatus, SyncStatus.pendingSync);

      await database.close();
    });
  });

  test('records survive closing and reopening the database', () async {
    final dir = await Directory.systemTemp.createTemp('aashanet_db_test');
    final file = File('${dir.path}/test.sqlite');
    addTearDown(() => dir.delete(recursive: true));

    var database = AppDatabase.forExecutor(NativeDatabase(file));
    final id = await HealthRecordLocalRepository(database).saveNewRecord(
      ownerUsername: 'asha_demo',
      rawInput: '[Voice recording]',
      inputLanguage: 'Kannada',
      audioPath: '/rec.m4a',
    );
    await database.close();

    database = AppDatabase.forExecutor(NativeDatabase(file));
    final record = await HealthRecordLocalRepository(database).getRecord(id);

    expect(record, isNotNull);
    expect(record!.audioPath, '/rec.m4a');
    expect(record.syncStatus, SyncStatus.pendingSync);
    expect(record.aiStatus, AiStatus.pending);
    await database.close();
  });

  group('HealthRecordLocalRepository', () {
    late AppDatabase database;
    late HealthRecordLocalRepository repo;

    setUp(() {
      database = AppDatabase(testMode: true);
      repo = HealthRecordLocalRepository(database);
    });

    tearDown(() => database.close());

    test('new records get a UUID used as the client record id', () async {
      final id = await repo.saveNewRecord(
        ownerUsername: 'a',
        rawInput: 'note',
      );
      final record = await repo.getRecord(id);

      expect(isUuid(id), isTrue);
      expect(record!.clientRecordId, id);
      expect(record.ownerUsername, 'a');
    });

    test('sync queue only contains the owner\'s due records', () async {
      final mine = await repo.saveNewRecord(ownerUsername: 'a', rawInput: '1');
      final waiting =
          await repo.saveNewRecord(ownerUsername: 'a', rawInput: '2');
      final synced = await repo.saveNewRecord(ownerUsername: 'a', rawInput: '3');
      await repo.saveNewRecord(ownerUsername: 'b', rawInput: 'other user');

      await repo.markSyncFailed(
        id: waiting,
        reason: SyncError.server,
        attempts: 1,
        retryAt: DateTime.now().add(const Duration(minutes: 5)),
      );
      await repo.markSynced(synced);

      final due = await repo.getRecordsDueForSync('a');
      expect(due.map((r) => r.id), [mine]);

      final later = await repo.getRecordsDueForSync(
        'a',
        now: DateTime.now().add(const Duration(minutes: 10)),
      );
      expect(later.map((r) => r.id).toSet(), {mine, waiting});
    });

    test('unowned (pre-upgrade) records are claimed by the first user',
        () async {
      await database.insertHealthRecord(
        HealthRecordsCompanion.insert(id: 'legacy', rawInput: 'old'),
      );

      expect(await repo.claimUnownedRecords('asha_demo'), 1);
      expect(await repo.claimUnownedRecords('someone_else'), 0);
      expect((await repo.getRecord('legacy'))!.ownerUsername, 'asha_demo');
    });

    test('interrupted uploads go back to the queue on restart', () async {
      final id = await repo.saveNewRecord(ownerUsername: 'a', rawInput: 'x');
      await repo.markUploading(id);

      expect(await repo.resetInterruptedUploads(), 1);
      expect((await repo.getRecord(id))!.syncStatus, SyncStatus.pendingSync);
    });

    test('confirming saves locally and queues the record again', () async {
      final id = await repo.saveNewRecord(ownerUsername: 'a', rawInput: 'x');
      await repo.markSynced(id);

      await repo.saveConfirmation(id: id, confirmedData: {'age': 30});
      final record = (await repo.getRecord(id))!;

      expect(record.recordStatus, RecordStatus.confirmed);
      expect(record.syncStatus, SyncStatus.pendingSync);
      expect(
        HealthRecordLocalRepository.decodeJson(record.confirmedData),
        {'age': 30},
      );
    });

    test('resolving a conflict keeps both versions', () async {
      final id = await repo.saveNewRecord(ownerUsername: 'a', rawInput: 'x');
      await repo.saveConfirmation(id: id, confirmedData: {'age': 30});
      await repo.markConflict(id: id, serverConfirmedData: {'age': 31});

      expect((await repo.getRecord(id))!.syncStatus, SyncStatus.conflict);
      expect(await repo.getRecordsDueForSync('a'), isEmpty,
          reason: 'a conflict waits for the worker, it is not retried');

      await repo.resolveConflictWithServerVersion(id);
      final record = (await repo.getRecord(id))!;

      expect(record.syncStatus, SyncStatus.synced);
      expect(HealthRecordLocalRepository.decodeJson(record.confirmedData),
          {'age': 31});
      expect(HealthRecordLocalRepository.decodeJson(record.conflictLocalData),
          {'age': 30});
    });
  });
}
