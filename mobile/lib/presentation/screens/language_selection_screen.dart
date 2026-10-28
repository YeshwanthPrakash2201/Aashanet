import 'package:flutter/material.dart';

import '../../infrastructure/settings/language_storage.dart';
import '../../l10n/app_localizations.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({
    super.key,
    required this.onLanguageSelected,
  });

  final ValueChanged<Locale> onLanguageSelected;

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends State<LanguageSelectionScreen> {
  String? _selectedLanguage;

  final LanguageStorage _languageStorage = LanguageStorage();

  Future<void> _continue() async {
    if (_selectedLanguage == null) {
      return;
    }

    await _languageStorage.saveLanguage(_selectedLanguage!);

    if (!mounted) {
      return;
    }

    widget.onLanguageSelected(
      Locale(_selectedLanguage!),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.language),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 30),

              const Icon(
                Icons.language,
                size: 70,
              ),

              const SizedBox(height: 24),

              Text(
                l10n.selectLanguage,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),

              const SizedBox(height: 32),

              _buildLanguageOption(
                languageCode: 'kn',
                title: l10n.kannada,
                subtitle: 'ಕನ್ನಡ',
              ),

              const SizedBox(height: 12),

              _buildLanguageOption(
                languageCode: 'hi',
                title: l10n.hindi,
                subtitle: 'हिंदी',
              ),

              const SizedBox(height: 12),

              _buildLanguageOption(
                languageCode: 'en',
                title: l10n.english,
                subtitle: 'English',
              ),

              const Spacer(),

              ElevatedButton(
                onPressed:
                    _selectedLanguage == null ? null : _continue,
                child: Text(l10n.continueText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption({
    required String languageCode,
    required String title,
    required String subtitle,
  }) {
    final isSelected = _selectedLanguage == languageCode;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedLanguage = languageCode;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
           RadioGroup<String>(
              groupValue: _selectedLanguage,
              onChanged: (value) {
                setState(() {
                  _selectedLanguage = value;
                });
              },
              child: Column(
                children: [
                  // language options here
                ],
              ),
            ),

            const SizedBox(width: 8),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}