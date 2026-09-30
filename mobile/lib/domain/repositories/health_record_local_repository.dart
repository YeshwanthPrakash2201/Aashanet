import 'package:drift/drift.dart';

import '../../infrastructure/database/app_database.dart';

class HealthRecordLocalRepository {
  final AppDatabase database;

  HealthRecordLocalRepository(
    this.database,
  );

  Future<void> saveHealthRecord({
    required String id,
    String? workerId,
    required String rawInput,
    String? inputLanguage,
    String? audioPath,
  }) async {
    await database.insertHealthRecord(
      HealthRecordsCompanion.insert(
        id: id,
        workerId: Value(workerId),
        rawInput: rawInput,
        inputLanguage: Value(inputLanguage),
        audioPath: Value(audioPath),
      ),
    );
  }

  Future<List<HealthRecord>> getAllRecords() {
    return database.getAllHealthRecords();
  }

  // ==========================================================
  // LINK LOCAL RECORD TO SERVER RECORD
  // ==========================================================

  Future<void> linkServerRecord({
    required String localRecordId,
    required String serverRecordId,
    required String workerId,
  }) async {
    await database.linkServerRecord(
      localRecordId,
      serverRecordId,
      workerId,
    );
  }

  // ==========================================================
  // MARK RECORD AS SYNCED
  // ==========================================================

  Future<void> markAsSynced(
    String recordId,
  ) async {
    await database.updateSyncStatus(
      recordId,
      'synced',
    );
  }

  // ==========================================================
  // MARK RECORD AS FAILED
  // ==========================================================

  Future<void> markAsFailed(
    String recordId,
  ) async {
    await database.updateSyncStatus(
      recordId,
      'failed',
    );
  }
}