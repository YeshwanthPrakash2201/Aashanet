import '../domain/repositories/health_record_local_repository.dart';
import '../infrastructure/database/app_database.dart';

/// The map the review screen reads, built from the locally stored
/// record (same keys the backend responses used), so a record can be
/// reviewed any time after its AI processing finished - including
/// later, from the records list, without contacting the server.
Map<String, dynamic> reviewDataFor(HealthRecord record) {
  return {
    'id': record.serverRecordId,
    'raw_input': record.rawInput,
    'transcript': record.aiTranscript,
    'english': record.aiTranslation,
    'ai_suggested_data':
        HealthRecordLocalRepository.decodeJson(record.aiSuggestedData) ??
            <String, dynamic>{},
    'ai_status': record.aiStatus,
    'record_status': record.recordStatus,
  };
}
