import 'dart:convert';

import 'package:drift/drift.dart';

import '../../infrastructure/database/app_database.dart';
import '../../infrastructure/ids.dart';
import '../record_status.dart';

/// All reads and writes of locally stored health records.
///
/// Every change is written to SQLite immediately, so nothing is lost if
/// the app is closed or the phone dies mid-way. Nothing here ever
/// deletes a record or its audio file.
class HealthRecordLocalRepository {
  final AppDatabase database;

  HealthRecordLocalRepository(this.database);

  $HealthRecordsTable get _table => database.healthRecords;

  // ==========================================================
  // CREATE
  // ==========================================================

  /// Saves a new record on the phone and returns its ID. Works offline.
  /// The record starts as pending sync with AI processing pending.
  Future<String> saveNewRecord({
    required String ownerUsername,
    required String rawInput,
    String? inputLanguage,
    String? audioPath,
  }) async {
    final id = generateUuidV4();

    await database.insertHealthRecord(
      HealthRecordsCompanion.insert(
        id: id,
        clientRecordId: Value(id),
        ownerUsername: Value(ownerUsername),
        rawInput: rawInput,
        inputLanguage: Value(inputLanguage),
        audioPath: Value(audioPath),
      ),
    );

    return id;
  }

  // ==========================================================
  // READ
  // ==========================================================

  Future<HealthRecord?> getRecord(String id) {
    return (database.select(_table)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  Stream<HealthRecord?> watchRecord(String id) {
    return (database.select(_table)..where((t) => t.id.equals(id)))
        .watchSingleOrNull();
  }

  /// Records belonging to [username], newest first. Updates live while
  /// the sync service changes statuses.
  Stream<List<HealthRecord>> watchRecordsForOwner(String username) {
    return (database.select(_table)
          ..where((t) => t.ownerUsername.equals(username))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  /// Records of [username] that still need to reach the server and
  /// whose retry wait (if any) has passed.
  Future<List<HealthRecord>> getRecordsDueForSync(
    String username, {
    DateTime? now,
  }) {
    final time = now ?? DateTime.now();

    return (database.select(_table)
          ..where(
            (t) =>
                t.ownerUsername.equals(username) &
                t.syncStatus.isIn(SyncStatus.needsSync) &
                (t.nextSyncAt.isNull() |
                    t.nextSyncAt.isSmallerOrEqualValue(time)),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
  }

  Stream<int> watchUnsyncedCount(String username) {
    final count = _table.id.count();

    return (database.selectOnly(_table)
          ..addColumns([count])
          ..where(
            _table.ownerUsername.equals(username) &
                _table.syncStatus.isIn([
                  ...SyncStatus.needsSync,
                  SyncStatus.uploading,
                ]),
          ))
        .map((row) => row.read(count) ?? 0)
        .watchSingle();
  }

  // ==========================================================
  // OWNERSHIP AND RECOVERY
  // ==========================================================

  /// Records saved before v4 have no owner. They were created by
  /// whoever used this phone, so the first user to log in after the
  /// upgrade takes them over. Returns how many were claimed.
  Future<int> claimUnownedRecords(String username) {
    return (database.update(_table)..where((t) => t.ownerUsername.isNull()))
        .write(HealthRecordsCompanion(ownerUsername: Value(username)));
  }

  /// If the app was closed during an upload, the record is left as
  /// "uploading". Put it back in the queue (server calls are safe to
  /// repeat, so nothing is duplicated).
  Future<int> resetInterruptedUploads() {
    return (database.update(_table)
          ..where((t) => t.syncStatus.equals(SyncStatus.uploading)))
        .write(
      const HealthRecordsCompanion(
        syncStatus: Value(SyncStatus.pendingSync),
      ),
    );
  }

  // ==========================================================
  // SYNC STATE CHANGES
  // ==========================================================

  Future<void> _write(String id, HealthRecordsCompanion changes) {
    return (database.update(_table)..where((t) => t.id.equals(id))).write(
      changes.copyWith(updatedAt: Value(DateTime.now())),
    );
  }

  Future<void> markUploading(String id) {
    return _write(
      id,
      const HealthRecordsCompanion(syncStatus: Value(SyncStatus.uploading)),
    );
  }

  /// Back in the queue without counting a failure (e.g. the connection
  /// dropped or the login expired; nothing was wrong with the record).
  Future<void> markPendingSync(String id, {String? reason}) {
    return _write(
      id,
      HealthRecordsCompanion(
        syncStatus: const Value(SyncStatus.pendingSync),
        lastSyncError: Value(reason),
      ),
    );
  }

  Future<void> linkServerRecord({
    required String localRecordId,
    required String serverRecordId,
    required String workerId,
    int? serverVersion,
  }) {
    return _write(
      localRecordId,
      HealthRecordsCompanion(
        serverRecordId: Value(serverRecordId),
        workerId: Value(workerId),
        serverVersion: Value(serverVersion),
      ),
    );
  }

  Future<void> saveAiResult({
    required String id,
    required Map<String, dynamic> suggestedData,
    String? transcript,
    String? translation,
    int? serverVersion,
  }) {
    return _write(
      id,
      HealthRecordsCompanion(
        aiStatus: const Value(AiStatus.completed),
        aiSuggestedData: Value(jsonEncode(suggestedData)),
        aiTranscript: Value(transcript),
        aiTranslation: Value(translation),
        serverVersion: Value(serverVersion),
      ),
    );
  }

  Future<void> markAiFailed(String id) {
    return _write(
      id,
      const HealthRecordsCompanion(aiStatus: Value(AiStatus.failed)),
    );
  }

  /// The worker reviewed and confirmed the details. Saved on the phone
  /// first; the sync service sends it to the server.
  Future<void> saveConfirmation({
    required String id,
    required Map<String, dynamic> confirmedData,
  }) {
    return _write(
      id,
      HealthRecordsCompanion(
        recordStatus: const Value(RecordStatus.confirmed),
        confirmedData: Value(jsonEncode(confirmedData)),
        syncStatus: const Value(SyncStatus.pendingSync),
        syncAttempts: const Value(0),
        nextSyncAt: const Value(null),
        lastSyncError: const Value(null),
      ),
    );
  }

  /// The server confirmed it stores everything this phone has.
  Future<void> markSynced(String id, {int? serverVersion}) {
    return _write(
      id,
      HealthRecordsCompanion(
        syncStatus: const Value(SyncStatus.synced),
        syncAttempts: const Value(0),
        nextSyncAt: const Value(null),
        lastSyncError: const Value(null),
        serverVersion: Value(serverVersion),
      ),
    );
  }

  /// A failed attempt. The record stays on the phone and is retried
  /// automatically after [retryAt].
  Future<void> markSyncFailed({
    required String id,
    required String reason,
    required int attempts,
    required DateTime retryAt,
  }) {
    return _write(
      id,
      HealthRecordsCompanion(
        syncStatus: const Value(SyncStatus.syncFailed),
        syncAttempts: Value(attempts),
        nextSyncAt: Value(retryAt),
        lastSyncError: Value(reason),
      ),
    );
  }

  // ==========================================================
  // CONFLICTS
  // ==========================================================

  /// The server already has a different confirmed version. Keep both;
  /// do not retry until the worker decides.
  Future<void> markConflict({
    required String id,
    required Map<String, dynamic> serverConfirmedData,
    int? serverVersion,
  }) {
    return _write(
      id,
      HealthRecordsCompanion(
        syncStatus: const Value(SyncStatus.conflict),
        conflictServerData: Value(jsonEncode(serverConfirmedData)),
        serverVersion: Value(serverVersion),
        nextSyncAt: const Value(null),
      ),
    );
  }

  /// The worker chose the server's version. The server record is final,
  /// so it becomes the record's confirmed data; the worker's own version
  /// is kept in conflictLocalData rather than thrown away.
  Future<void> resolveConflictWithServerVersion(String id) async {
    final record = await getRecord(id);

    if (record == null || record.conflictServerData == null) {
      return;
    }

    await _write(
      id,
      HealthRecordsCompanion(
        conflictLocalData: Value(record.confirmedData),
        confirmedData: Value(record.conflictServerData),
        conflictServerData: const Value(null),
        syncStatus: const Value(SyncStatus.synced),
        lastSyncError: const Value(null),
      ),
    );
  }

  // ==========================================================
  // JSON HELPERS
  // ==========================================================

  static Map<String, dynamic>? decodeJson(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }

    final decoded = jsonDecode(value);
    return decoded is Map<String, dynamic> ? decoded : null;
  }

  // ==========================================================
  // OLDER API (still used by screens until they move to the above)
  // ==========================================================

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
        clientRecordId: Value(isUuid(id) ? id : generateUuidV4()),
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

  Future<List<HealthRecord>> getPendingRecords() {
    return database.getPendingHealthRecords();
  }

  Future<void> markAsSynced(String recordId) => markSynced(recordId);

  Future<void> markAsFailed(String recordId) {
    return markSyncFailed(
      id: recordId,
      reason: SyncError.server,
      attempts: 1,
      retryAt: DateTime.now(),
    );
  }
}
