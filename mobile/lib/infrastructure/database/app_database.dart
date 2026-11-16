import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../domain/record_status.dart';
import '../ids.dart';

part 'app_database.g.dart';

// ============================================================
// HEALTH RECORDS TABLE
// ============================================================

class HealthRecords extends Table {
  // Local ID (primary key). New records use a random UUID, which is
  // also sent to the server as clientRecordId. Never replaced by the
  // server ID.
  TextColumn get id => text()();

  // UUID the server uses to recognise retries of the same record, so
  // an upload repeated after a lost response never creates a duplicate.
  TextColumn get clientRecordId => text().nullable()();

  // Username of the ASHA worker who created the record on this phone.
  // Only that user's login is used to sync it.
  TextColumn get ownerUsername => text().nullable()();

  // PostgreSQL health_records.id. Null until the server has the record.
  TextColumn get serverRecordId => text().nullable()();

  // PostgreSQL users.id of the worker. Null until first upload.
  TextColumn get workerId => text().nullable()();

  TextColumn get rawInput => text()();

  TextColumn get inputLanguage => text().nullable()();

  // Original recording in the app's private storage. Kept after sync.
  TextColumn get audioPath => text().nullable()();

  // ----- AI processing (needs internet) --------------------------

  TextColumn get aiStatus =>
      text().withDefault(const Constant(AiStatus.pending))();

  TextColumn get aiTranscript => text().nullable()();

  TextColumn get aiTranslation => text().nullable()();

  // JSON: {patient_name, age, symptoms, duration}
  TextColumn get aiSuggestedData => text().nullable()();

  // ----- Worker review -------------------------------------------

  TextColumn get recordStatus =>
      text().withDefault(const Constant(RecordStatus.draft))();

  // JSON confirmed by the worker: {patient_name, age, symptoms, duration}
  TextColumn get confirmedData => text().nullable()();

  // ----- Sync bookkeeping ----------------------------------------

  TextColumn get syncStatus =>
      text().withDefault(const Constant(SyncStatus.pendingSync))();

  IntColumn get syncAttempts => integer().withDefault(const Constant(0))();

  // Earliest time the next automatic retry may run (backoff).
  DateTimeColumn get nextSyncAt => dateTime().nullable()();

  // Short reason code from SyncError; never patient data.
  TextColumn get lastSyncError => text().nullable()();

  // Server-side `version` last seen for this record.
  IntColumn get serverVersion => integer().nullable()();

  // Conflict handling: the server's confirmed data (JSON) while in
  // conflict, and the worker's version kept after choosing the server's.
  TextColumn get conflictServerData => text().nullable()();

  TextColumn get conflictLocalData => text().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// DATABASE
// ============================================================

@DriftDatabase(
  tables: [HealthRecords],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase({
    bool testMode = false,
  }) : super(
          testMode ? NativeDatabase.memory() : _openConnection(),
        );

  /// For tests: open the database on a specific executor (for example
  /// a temporary file, to check data survives closing and reopening).
  AppDatabase.forExecutor(super.executor);

  /// The one database connection the app uses. Screens and the sync
  /// service share it; opening several connections to the same file
  /// makes drift warn and can race. Never closed while the app runs.
  static final AppDatabase instance = AppDatabase();

  // ==========================================================
  // DATABASE VERSION
  // ==========================================================
  //
  // 1-3: early versions (sync status only).
  // 4:   offline-first sync (owner, client UUID, AI results, review
  //      data, retry/backoff and conflict columns).

  @override
  int get schemaVersion => 4;

  // ==========================================================
  // DATABASE MIGRATION
  // ==========================================================

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 4) {
            await _upgradeToV4(m, from);
          }
        },
      );

  Future<void> _upgradeToV4(Migrator m, int from) async {
    // Rebuild the table once with the v4 schema, translating the old
    // status values. Old rows keep every value they had.
    await m.alterTable(
      TableMigration(
        healthRecords,
        columnTransformer: {
          healthRecords.syncStatus: const CustomExpression<String>(
            "CASE sync_status "
            "WHEN 'pending' THEN 'pending_sync' "
            "WHEN 'failed' THEN 'sync_failed' "
            "ELSE sync_status END",
          ),
          // Before v4, a record became 'synced' only after the worker
          // confirmed it, so synced rows were reviewed and AI had run.
          healthRecords.aiStatus: const CustomExpression<String>(
            "CASE WHEN sync_status = 'synced' "
            "THEN 'ai_completed' ELSE 'ai_pending' END",
          ),
          healthRecords.recordStatus: const CustomExpression<String>(
            "CASE WHEN sync_status = 'synced' "
            "THEN 'confirmed' ELSE 'draft' END",
          ),
        },
        newColumns: [
          if (from < 3) healthRecords.serverRecordId,
          healthRecords.clientRecordId,
          healthRecords.ownerUsername,
          healthRecords.aiTranscript,
          healthRecords.aiTranslation,
          healthRecords.aiSuggestedData,
          healthRecords.confirmedData,
          healthRecords.syncAttempts,
          healthRecords.nextSyncAt,
          healthRecords.lastSyncError,
          healthRecords.serverVersion,
          healthRecords.conflictServerData,
          healthRecords.conflictLocalData,
        ],
      ),
    );

    // Old IDs look like "local-1793875597333", which the server cannot
    // use for duplicate protection. Give each old row a UUID.
    final rows = await customSelect(
      'SELECT id FROM health_records WHERE client_record_id IS NULL',
    ).get();

    for (final row in rows) {
      await customUpdate(
        'UPDATE health_records SET client_record_id = ? WHERE id = ?',
        variables: [
          Variable.withString(generateUuidV4()),
          Variable.withString(row.read<String>('id')),
        ],
        updates: {healthRecords},
      );
    }
  }

  // ==========================================================
  // BASIC QUERIES (kept for existing callers and tests)
  // ==========================================================

  Future<List<HealthRecord>> getAllHealthRecords() {
    return select(healthRecords).get();
  }

  Future<List<HealthRecord>> getPendingHealthRecords() {
    return (select(healthRecords)
          ..where((table) => table.syncStatus.isIn(SyncStatus.needsSync)))
        .get();
  }

  Future<void> insertHealthRecord(HealthRecordsCompanion record) async {
    await into(healthRecords).insert(record);
  }
}

// ============================================================
// DATABASE CONNECTION
// ============================================================

QueryExecutor _openConnection() {
  return driftDatabase(
    name: 'aashanet_database',
  );
}
