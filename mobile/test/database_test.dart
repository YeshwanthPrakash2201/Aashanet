import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:mobile/infrastructure/database/app_database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Health record can be saved and retrieved locally', () async {
    final database = AppDatabase(testMode: true);

    final recordId = 'test-record-001';

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
    expect(
      records.first.rawInput,
      'Ramesh is 42 years old and has fever',
    );
    expect(records.first.workerId, null);
    expect(records.first.syncStatus, 'pending');

    await database.close();
  });
}