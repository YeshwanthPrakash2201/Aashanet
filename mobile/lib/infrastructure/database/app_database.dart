import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// ============================================================
// HEALTH RECORDS TABLE
// ============================================================

class HealthRecords extends Table {
  // Local ID.
  //
  // This remains the primary key of the local SQLite record.
  // It must NOT be replaced by the server ID.
  TextColumn get id => text()();

  // PostgreSQL server-side health record ID.
  //
  // Null while the record exists only locally/offline.
  TextColumn get serverRecordId =>
      text().nullable()();

  // Worker/user ID.
  //
  // Null while the record exists only locally/offline.
  TextColumn get workerId =>
      text().nullable()();

  TextColumn get rawInput => text()();

  TextColumn get inputLanguage =>
      text().nullable()();

  TextColumn get audioPath =>
      text().nullable()();

  TextColumn get aiStatus =>
      text().withDefault(
        const Constant('pending_review'),
      )();

  TextColumn get recordStatus =>
      text().withDefault(
        const Constant('draft'),
      )();

  TextColumn get syncStatus =>
      text().withDefault(
        const Constant('pending'),
      )();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(
        currentDateAndTime,
      )();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(
        currentDateAndTime,
      )();

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
          testMode
              ? NativeDatabase.memory()
              : _openConnection(),
        );

  // ==========================================================
  // DATABASE VERSION
  // ==========================================================

  @override
  int get schemaVersion => 3;

  // ==========================================================
  // DATABASE MIGRATION
  // ==========================================================

  @override
  MigrationStrategy get migration =>
      MigrationStrategy(
        // ----------------------------------------------------
        // NEW DATABASE
        // ----------------------------------------------------

        onCreate: (Migrator m) async {
          await m.createAll();
        },

        // ----------------------------------------------------
        // EXISTING DATABASE
        // ----------------------------------------------------

        onUpgrade:
            (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.alterTable(
              TableMigration(
                healthRecords,
              ),
            );
          }

          if (from < 3) {
            await m.addColumn(
              healthRecords,
              healthRecords.serverRecordId,
            );
          }
        },
      );

  // ==========================================================
  // GET ALL HEALTH RECORDS
  // ==========================================================

  Future<List<HealthRecord>>
      getAllHealthRecords() {
    return select(
      healthRecords,
    ).get();
  }

  // ==========================================================
  // INSERT HEALTH RECORD
  // ==========================================================

  Future<void> insertHealthRecord(
    HealthRecordsCompanion record,
  ) async {
    await into(
      healthRecords,
    ).insert(record);
  }

  // ==========================================================
  // LINK LOCAL RECORD TO SERVER RECORD
  // ==========================================================
  //
  // Called after the backend successfully creates the
  // PostgreSQL health record.
  //
  // IMPORTANT:
  // This does NOT mark the record as synced.
  // The record is only synced after Confirm & Save succeeds.
  //
  // localRecordId:
  //   Local SQLite primary key.
  //
  // serverRecordId:
  //   PostgreSQL health_records.id.
  //
  // workerId:
  //   PostgreSQL users.id belonging to the logged-in ASHA.
  // ==========================================================

  Future<void> linkServerRecord(
    String localRecordId,
    String serverRecordId,
    String workerId,
  ) async {
    await (
      update(healthRecords)
        ..where(
          (table) =>
              table.id.equals(localRecordId),
        )
    ).write(
      HealthRecordsCompanion(
        serverRecordId: Value(serverRecordId),
        workerId: Value(workerId),
        updatedAt: Value(
          DateTime.now(),
        ),
      ),
    );
  }

  // ==========================================================
  // UPDATE SYNC STATUS
  // ==========================================================

  Future<void> updateSyncStatus(
    String recordId,
    String status,
  ) async {
    await (
      update(healthRecords)
        ..where(
          (table) =>
              table.id.equals(recordId),
        )
    ).write(
      HealthRecordsCompanion(
        syncStatus: Value(status),
        updatedAt: Value(
          DateTime.now(),
        ),
      ),
    );
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