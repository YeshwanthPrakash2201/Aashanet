import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/l10n/app_localizations.dart';
import 'package:mobile/presentation/screens/language_selection_screen.dart';
import 'package:mobile/presentation/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('language screen offers three languages and saves the choice',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    Locale? chosen;

    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      locale: const Locale('en'),
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('kn'), Locale('hi')],
      home: LanguageSelectionScreen(onLanguageSelected: (l) => chosen = l),
    ));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Kannada'), findsOneWidget);
    expect(find.text('Hindi'), findsOneWidget);
    expect(find.text('English'), findsWidgets);

    await tester.tap(find.text('Hindi'));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.text('Continue'));
    await tester.pump(const Duration(seconds: 1));

    expect(chosen, const Locale('hi'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isNotEmpty, reason: 'choice is remembered');
  });
}
