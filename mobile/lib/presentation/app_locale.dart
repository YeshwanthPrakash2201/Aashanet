import 'package:flutter/material.dart';

import '../infrastructure/settings/language_storage.dart';
import '../l10n/app_localizations.dart';
import 'theme/app_theme.dart';

/// The app's current language. The root widget listens to it, so setting
/// a new value re-draws every screen in that language immediately.
/// `null` means no language has been chosen yet (first launch).
final ValueNotifier<Locale?> appLocale = ValueNotifier<Locale?>(null);

/// Saves [locale] as the default language and switches the app to it.
Future<void> changeAppLanguage(Locale locale) async {
  await LanguageStorage().saveLanguage(locale.languageCode);
  appLocale.value = locale;
}

/// The language name the backend's AI expects for the spoken audio,
/// based on the app language (Kannada by default, as most workers in
/// Karnataka speak it).
String spokenLanguageFor(Locale locale) => switch (locale.languageCode) {
  'hi' => 'Hindi',
  'en' => 'English',
  _ => 'Kannada',
};

/// Bottom sheet listing English, Kannada and Hindi; picking one switches
/// the app language at once and remembers it.
Future<void> showLanguageSheet(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  final current = Localizations.localeOf(context).languageCode;

  final options = [
    ('kn', 'ಕ', l10n.kannada, 'ಕನ್ನಡ'),
    ('hi', 'अ', l10n.hindi, 'हिंदी'),
    ('en', 'A', l10n.english, 'English'),
  ];

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.lg)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.changeLanguage,
              style: Theme.of(sheetContext).textTheme.titleLarge
                  ?.copyWith(color: AppColors.forest),
            ),
            const SizedBox(height: 12),
            for (final (code, glyph, title, native) in options)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Semantics(
                  selected: code == current,
                  inMutuallyExclusiveGroup: true,
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.md),
                      side: BorderSide(
                        color: code == current
                            ? AppColors.teal
                            : AppColors.line,
                        width: code == current ? 2 : 1,
                      ),
                    ),
                    tileColor: code == current
                        ? AppColors.tealMist
                        : Colors.white,
                    minVerticalPadding: 14,
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor: code == current
                          ? AppColors.teal
                          : AppColors.cream,
                      child: Text(
                        glyph,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: code == current
                              ? Colors.white
                              : AppColors.teal,
                        ),
                      ),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(native),
                    trailing: code == current
                        ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.teal,
                          )
                        : null,
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      await changeAppLanguage(Locale(code));
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
