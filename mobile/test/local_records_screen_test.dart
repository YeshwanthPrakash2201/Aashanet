import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/application/app_services.dart';
import 'package:mobile/application/sync_service.dart';
import 'package:mobile/domain/repositories/health_record_local_repository.dart';
import 'package:mobile/infrastructure/connectivity/connectivity_service.dart';
import 'package:mobile/infrastructure/database/app_database.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/presentation/screens/local_records_screen.dart';

import 'sync_service_test.dart' show FakeServer;

void main() {
  late AppDatabase database;
  late HealthRecordLocalRepository repo;
  late FakeServer server;
  late ConnectivityService connectivity;
  late AppServices services;
  final reviewed = <String>[];

  setUp(() async {
    database = AppDatabase(testMode: true);
    repo = HealthRecordLocalRepository(database);
    server = FakeServer()..offline = true;
    connectivity = ConnectivityService(
      probe: server.ping,
      networkChanges: const Stream.empty(),
      currentNetwork: () async => [ConnectivityResult.none],
    );
    final sync = SyncService(
      username: 'asha_demo',
      repository: repo,
      api: server,
      connectivity: connectivity,
    );
    services = AppServices.forTesting(
      username: 'asha_demo',
      records: repo,
      api: server,
      connectivity: connectivity,
      sync: sync,
    );
    reviewed.clear();
  });

  // Drift's stream queries clean up with timers, which never fire inside
  // the widget test's fake clock. Unmount the screen, let those timers
  // run, and close the database on the real clock.
  Future<void> cleanUp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    services.sync.dispose();
    connectivity.dispose();
    await tester.runAsync(() => database.close());
  }

  Widget app() => MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('en'), Locale('kn'), Locale('hi')],
        home: LocalRecordsScreen(
          services: services,
          onReview: (context, record) => reviewed.add(record.id),
        ),
      );

  // Drift streams use timers; run them inside runAsync and let the UI settle.
  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
  }

  testWidgets('offline record shows Saved offline and AI pending',
      (tester) async {
    await tester.runAsync(() => repo.saveNewRecord(
          ownerUsername: 'asha_demo',
          rawInput: 'Ravi has fever',
        ));

    await tester.pumpWidget(app());
    await settle(tester);

    expect(find.text('Ravi has fever'), findsOneWidget);
    expect(find.text('Saved offline'), findsOneWidget);
    expect(find.text('AI processing pending (needs internet)'), findsOneWidget);

    await cleanUp(tester);
  });

  testWidgets('after sync the list shows Synced and review needed',
      (tester) async {
    final id = await tester.runAsync(() => repo.saveNewRecord(
          ownerUsername: 'asha_demo',
          rawInput: 'Ramesh is 42 years old',
        ));

    server.offline = false;
    await tester.runAsync(() async {
      await connectivity.checkNow();
      await services.sync.syncAll();
    });

    await tester.pumpWidget(app());
    await settle(tester);

    expect(find.text('Synced'), findsOneWidget);
    expect(find.text('AI processing completed – review needed'), findsOneWidget);

    await tester.tap(find.text('Ramesh is 42 years old'));
    await tester.pump();

    expect(reviewed, [id], reason: 'tapping opens the review screen');

    await cleanUp(tester);
  });

  testWidgets('another user\'s records are not listed', (tester) async {
    await tester.runAsync(() => repo.saveNewRecord(
          ownerUsername: 'someone_else',
          rawInput: 'Private note',
        ));

    await tester.pumpWidget(app());
    await settle(tester);

    expect(find.text('Private note'), findsNothing);
    expect(find.text('No local health records yet.'), findsOneWidget);

    await cleanUp(tester);
  });
}
