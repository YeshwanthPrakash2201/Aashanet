// Renders every screen to PNG at phone and desktop sizes, for visual
// review of the design. Skipped unless SCREENSHOTS_DIR is set:
//
//   $env:SCREENSHOTS_DIR = "C:\temp\shots"
//   flutter test test/screenshots/screenshots_test.dart
//
// Uses the real Roboto / Material Icons fonts from the Flutter SDK (and
// Windows' Nirmala UI for Kannada/Devanagari) so text renders as on a
// device instead of as test boxes. Records shown are test fixtures.

import 'dart:io';
import 'dart:ui' as ui;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/application/app_services.dart';
import 'package:mobile/application/sync_service.dart';
import 'package:mobile/domain/repositories/health_record_local_repository.dart';
import 'package:mobile/infrastructure/connectivity/connectivity_service.dart';
import 'package:mobile/infrastructure/database/app_database.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/main.dart';
import 'package:mobile/presentation/screens/language_selection_screen.dart';
import 'package:mobile/presentation/screens/local_records_screen.dart';
import 'package:mobile/presentation/theme/app_theme.dart';

import '../sync_service_test.dart' show FakeServer;

final _outDir = Platform.environment['SCREENSHOTS_DIR'];

const _sizes = {
  'phone': Size(390, 844),
  'desktop': Size(1280, 800),
};

Future<void> _loadFonts() async {
  final flutterRoot = Platform.environment['FLUTTER_ROOT'] ??
      '${Platform.environment['USERPROFILE']}\\flutter';
  final material = '$flutterRoot\\bin\\cache\\artifacts\\material_fonts';

  Future<ByteData> read(String path) async =>
      ByteData.view(Uint8List.fromList(await File(path).readAsBytes()).buffer);

  final roboto = FontLoader('Roboto');
  for (final w in ['regular', 'medium', 'bold', 'black']) {
    roboto.addFont(read('$material\\roboto-$w.ttf'));
  }
  await roboto.load();

  await (FontLoader('MaterialIcons')
        ..addFont(read('$material\\materialicons-regular.otf')))
      .load();

  final nirmala = FontLoader('Nirmala');
  for (final f in ['Nirmala.ttf', 'NirmalaB.ttf']) {
    final path = 'C:\\Windows\\Fonts\\$f';
    if (File(path).existsSync()) {
      nirmala.addFont(read(path));
    }
  }
  await nirmala.load();
}

ThemeData _theme() {
  final theme = AppTheme.light();
  return theme.copyWith(
    textTheme: theme.textTheme.apply(fontFamilyFallback: const ['Nirmala']),
  );
}

Widget _app(Widget home) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _theme(),
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('kn'), Locale('hi')],
      home: home,
    );

Future<void> _shoot(
  WidgetTester tester,
  String name,
  Widget home, {
  Future<void> Function()? before,
}) async {
  for (final entry in _sizes.entries) {
    tester.view.physicalSize = entry.value * 2;
    tester.view.devicePixelRatio = 2;

    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(key: key, child: _app(home)));

    // Let streams deliver (real async) and animations finish (fake time).
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 60)),
      );
      await tester.pump(const Duration(seconds: 1));
    }
    if (before != null) {
      await before();
    }

    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1.5);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final file = File('$_outDir/${name}_${entry.key}.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List());
    });

    // Unmount so drift streams are cancelled before the next shot.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  }

  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
}

void main() {
  late AppDatabase database;
  late HealthRecordLocalRepository repo;
  late AppServices services;

  setUpAll(() async {
    // The audio recorder plugin has no implementation in widget tests.
    TestWidgetsFlutterBinding.ensureInitialized();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.record/messages'),
      (call) async => null,
    );

    if (_outDir != null) {
      Directory(_outDir!).createSync(recursive: true);
      await _loadFonts();
    }
  });

  Future<void> setUpServices(WidgetTester tester) async {
    database = AppDatabase(testMode: true);
    repo = HealthRecordLocalRepository(database);
    final server = FakeServer();
    final connectivity = ConnectivityService(
      probe: server.ping,
      networkChanges: const Stream.empty(),
      currentNetwork: () async => [ConnectivityResult.wifi],
    );
    services = AppServices.forTesting(
      username: 'asha_demo',
      records: repo,
      api: server,
      connectivity: connectivity,
      sync: SyncService(
        username: 'asha_demo',
        repository: repo,
        api: server,
        connectivity: connectivity,
      ),
    );

    await tester.runAsync(() async {
      await connectivity.checkNow();

      // Test fixtures in different states.
      final reviewed = await repo.saveNewRecord(
        ownerUsername: 'asha_demo',
        rawInput: 'Ramesh is 42 years old and has fever',
        inputLanguage: 'en',
      );
      await repo.linkServerRecord(
          localRecordId: reviewed, serverRecordId: 's1', workerId: 'w');
      await repo.saveAiResult(
        id: reviewed,
        suggestedData: {'patient_name': 'Ramesh', 'age': 42, 'symptoms': ['fever']},
      );
      await repo.markSynced(reviewed);

      final voice = await repo.saveNewRecord(
        ownerUsername: 'asha_demo',
        rawInput: '[Voice recording]',
        inputLanguage: 'Kannada',
        audioPath: '/nonexistent/note.m4a',
      );
      await repo.markPendingSync(voice);

      final confirmed = await repo.saveNewRecord(
        ownerUsername: 'asha_demo',
        rawInput: 'Lakshmi, 28, cough for one week',
        inputLanguage: 'en',
      );
      await repo.saveConfirmation(id: confirmed, confirmedData: {
        'patient_name': 'Lakshmi',
        'age': 28,
        'symptoms': ['cough'],
        'duration': '1 week',
      });
      await repo.markSynced(confirmed);
    });
  }

  Future<void> tearDownServices(WidgetTester tester) async {
    services.sync.dispose();
    services.connectivity.dispose();
    await tester.runAsync(() => database.close());
  }

  final skip = _outDir == null ? 'set SCREENSHOTS_DIR to render screens' : null;

  testWidgets('language selection', (tester) async {
    await _shoot(
      tester,
      '1_language',
      LanguageSelectionScreen(onLanguageSelected: (_) {}),
      before: () async {
        await tester.tap(find.text('Kannada'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
      },
    );
  }, skip: skip != null);

  testWidgets('login', (tester) async {
    await _shoot(tester, '2_login', const LoginScreen());
  }, skip: skip != null);

  testWidgets('home', (tester) async {
    await setUpServices(tester);
    await _shoot(
      tester,
      '3_home',
      HomeScreen(
        username: 'asha_demo',
        role: 'asha_worker',
        fullName: 'Demo ASHA Worker',
        accessToken: 'test',
        servicesForTesting: services,
      ),
    );
    await tearDownServices(tester);
  }, skip: skip != null);

  testWidgets('record', (tester) async {
    await _shoot(tester, '4_record', const RecordScreen(accessToken: 'test'));
  }, skip: skip != null);

  testWidgets('review', (tester) async {
    await _shoot(
      tester,
      '5_review',
      const ReviewRecordScreen(
        localRecordId: 'x',
        recordData: {
          'raw_input': '[Voice recording]',
          'transcript': 'ರವಿ ಕುಮಾರ್, ವಯಸ್ಸು 35. ಎರಡು ದಿನಗಳಿಂದ ಜ್ವರ.',
          'ai_suggested_data': {
            'patient_name': 'Ravi Kumar',
            'age': 35,
            'symptoms': ['fever'],
            'duration': '2 days',
          },
          'ai_status': 'ai_completed',
          'record_status': 'draft',
        },
      ),
    );
  }, skip: skip != null);

  testWidgets('records list', (tester) async {
    await setUpServices(tester);
    await _shoot(
      tester,
      '6_records',
      LocalRecordsScreen(services: services, onReview: (_, _) {}),
    );
    await tearDownServices(tester);
  }, skip: skip != null);
}
