// Status values stored in the local HealthRecords table.
//
// A record has three independent statuses:
//
//   SyncStatus   - is the server up to date with this phone?
//   AiStatus     - has Gemini (or the typed-text analyser) run yet?
//   RecordStatus - has the ASHA worker reviewed and confirmed it?
//
// AI output is always a *suggestion* for the worker to review; it is
// never treated as medically verified.

class SyncStatus {
  SyncStatus._();

  /// Saved on the phone; the server does not have the latest version.
  static const pendingSync = 'pending_sync';

  /// A sync attempt is running right now.
  static const uploading = 'uploading';

  /// The server has confirmed it stores everything this phone has.
  static const synced = 'synced';

  /// The last attempt failed; it will be retried automatically.
  static const syncFailed = 'sync_failed';

  /// The server already holds a different confirmed version. Both
  /// versions are kept until the worker chooses.
  static const conflict = 'conflict';

  static const needsSync = [pendingSync, syncFailed];
}

class AiStatus {
  AiStatus._();

  /// Waiting for internet: AI processing runs on the server.
  static const pending = 'ai_pending';

  /// Suggestions are ready for the worker to review.
  static const completed = 'ai_completed';

  /// The AI could not process this record (e.g. unreadable audio).
  static const failed = 'ai_failed';
}

class RecordStatus {
  RecordStatus._();

  static const draft = 'draft';

  /// Reviewed and confirmed by the worker (on the phone; it may still
  /// be waiting to reach the server, see SyncStatus).
  static const confirmed = 'confirmed';
}

/// Short, non-identifying reasons for the last failed sync attempt.
/// Never store server messages or patient data here.
class SyncError {
  SyncError._();

  static const network = 'network';
  static const loginRequired = 'login_required';
  static const aiBusy = 'ai_busy';
  static const aiRejected = 'ai_rejected';
  static const audioMissing = 'audio_missing';
  static const server = 'server';
  static const rejected = 'rejected';
}
