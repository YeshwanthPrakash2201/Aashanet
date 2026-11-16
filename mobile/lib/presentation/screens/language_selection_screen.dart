import 'package:flutter/material.dart';

import '../../infrastructure/settings/language_storage.dart';
import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/design.dart';

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
    final textTheme = Theme.of(context).textTheme;

    final options = [
      _LanguageOption(
        code: 'kn',
        glyph: 'ಕ',
        title: l10n.kannada,
        subtitle: 'ಕನ್ನಡ',
      ),
      _LanguageOption(
        code: 'hi',
        glyph: 'अ',
        title: l10n.hindi,
        subtitle: 'हिंदी',
      ),
      _LanguageOption(
        code: 'en',
        glyph: 'A',
        title: l10n.english,
        subtitle: 'English',
      ),
    ];

    return Scaffold(
      body: Column(
        children: [
          // ---------------- Hero -----------------------------------
          HeroSurface(
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(AppRadii.xl),
            ),
            child: SafeArea(
              bottom: false,
              child: ResponsiveCenter(
                maxWidth: 560,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
                child: FadeSlideIn(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const BrandMark(size: 52, onDark: true),
                          const SizedBox(width: 14),
                          Text(
                            l10n.appName,
                            style: textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        children: [
                          Icon(
                            Icons.translate_rounded,
                            color: AppColors.marigold,
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            l10n.language,
                            style: textTheme.titleSmall?.copyWith(
                              color: AppColors.marigold,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        l10n.selectLanguage,
                        style: textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ---------------- Options --------------------------------
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 24, bottom: 16),
              child: ResponsiveCenter(
                maxWidth: 560,
                child: Column(
                  children: [
                    for (var i = 0; i < options.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: FadeSlideIn(
                          delay: Duration(milliseconds: 120 + 90 * i),
                          child: _buildLanguageOption(options[i]),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // ---------------- Continue -------------------------------
          SafeArea(
            top: false,
            child: ResponsiveCenter(
              maxWidth: 560,
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: GradientButton(
                label: l10n.continueText,
                icon: Icons.arrow_forward_rounded,
                onPressed: _selectedLanguage == null ? null : _continue,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(_LanguageOption option) {
    final isSelected = _selectedLanguage == option.code;
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      child: Pressable(
        semanticLabel: option.title,
        onTap: () {
          setState(() {
            _selectedLanguage = option.code;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.tealMist : Colors.white,
            borderRadius: BorderRadius.circular(AppRadii.lg),
            border: Border.all(
              color: isSelected ? AppColors.teal : AppColors.line,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.forest
                    .withValues(alpha: isSelected ? 0.10 : 0.04),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: isSelected ? AppColors.tealGradient : null,
                  color: isSelected ? null : AppColors.cream,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                alignment: Alignment.center,
                child: Text(
                  option.glyph,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppColors.teal,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      option.subtitle,
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: isSelected
                    ? const Icon(
                        Icons.check_circle_rounded,
                        key: ValueKey('on'),
                        color: AppColors.teal,
                        size: 30,
                      )
                    : const Icon(
                        Icons.circle_outlined,
                        key: ValueKey('off'),
                        color: AppColors.line,
                        size: 30,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOption {
  const _LanguageOption({
    required this.code,
    required this.glyph,
    required this.title,
    required this.subtitle,
  });

  final String code;
  final String glyph;
  final String title;
  final String subtitle;
}
