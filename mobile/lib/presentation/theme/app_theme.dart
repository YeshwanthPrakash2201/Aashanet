import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

// ============================================================
// AASHANet design language
// ============================================================
//
// Built for ASHA workers on village visits: often outdoors, on mid-range
// Android phones, reading in Kannada, Hindi or English.
//
//  * Deep teal  - health, calm, trust (primary).
//  * Marigold   - warmth and care; the colour of the marigold garlands and
//                 rangoli found at every doorstep the worker visits (accent,
//                 used sparingly for the main action and highlights).
//  * Warm cream - softer than clinical white, easier on the eyes in sunlight.
//
// No custom font files are bundled: the app must work offline, and the
// system fonts already render Kannada and Devanagari correctly.

class AppColors {
  AppColors._();

  // Primary - teal family
  static const forest = Color(0xFF083D3A); // deepest, text on cream / hero
  static const teal = Color(0xFF0F6E66); // primary
  static const tealBright = Color(0xFF14958A);
  static const tealMist = Color(0xFFE3F1EE); // tinted surfaces

  // Accent - marigold family
  static const marigold = Color(0xFFF2A516);
  static const saffron = Color(0xFFE07A10);
  static const marigoldMist = Color(0xFFFFF1D6);

  // Neutrals
  static const cream = Color(0xFFFBF7F0); // page background
  static const sand = Color(0xFFF1EAE0); // dividers, subtle fills
  static const ink = Color(0xFF17262A); // body text
  static const inkMuted = Color(0xFF5D6B6E);
  static const line = Color(0xFFE4DCD0);

  // Status
  static const success = Color(0xFF1B7F4B);
  static const successMist = Color(0xFFE2F3E9);
  static const info = Color(0xFF1F5FB8);
  static const infoMist = Color(0xFFE4EDFA);
  static const warning = Color(0xFFB45309);
  static const warningMist = Color(0xFFFDF0DC);
  static const danger = Color(0xFFB42318);
  static const dangerMist = Color(0xFFFCE8E6);
  static const idle = Color(0xFF6B7476);
  static const idleMist = Color(0xFFEEEDEA);

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [forest, teal, tealBright],
    stops: [0, 0.6, 1],
  );

  static const actionGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [marigold, saffron],
  );

  static const tealGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [tealBright, teal],
  );
}

class AppRadii {
  AppRadii._();

  static const sm = 12.0;
  static const md = 18.0;
  static const lg = 26.0;
  static const xl = 34.0;
}

/// Layout breakpoints shared by every screen.
class Breakpoints {
  Breakpoints._();

  static const tablet = 640.0;
  static const desktop = 1000.0;

}

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.teal,
      onPrimary: Colors.white,
      primaryContainer: AppColors.tealMist,
      onPrimaryContainer: AppColors.forest,
      secondary: AppColors.saffron,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.marigoldMist,
      onSecondaryContainer: const Color(0xFF5A3200),
      tertiary: AppColors.tealBright,
      surface: Colors.white,
      onSurface: AppColors.ink,
      onSurfaceVariant: AppColors.inkMuted,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFFDFBF7),
      surfaceContainer: AppColors.cream,
      surfaceContainerHigh: AppColors.sand,
      outline: const Color(0xFFCFC5B6),
      outlineVariant: AppColors.line,
      error: AppColors.danger,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.cream,
      visualDensity: VisualDensity.standard,
    );

    final text = base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );

    final textTheme = text.copyWith(
      displaySmall: text.displaySmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        height: 1.1,
      ),
      headlineMedium: text.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        height: 1.15,
      ),
      headlineSmall: text.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        height: 1.2,
      ),
      titleLarge: text.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: text.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      titleSmall: text.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
      ),
      bodyLarge: text.bodyLarge?.copyWith(height: 1.45),
      bodyMedium: text.bodyMedium?.copyWith(
        height: 1.45,
        color: AppColors.inkMuted,
      ),
      labelLarge: text.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
    );

    final roundedField = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
      borderSide: const BorderSide(color: AppColors.line),
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadii.md),
    );

    const buttonText = TextStyle(
      fontSize: 17,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.2,
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: AppColors.forest,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.forest,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
          side: const BorderSide(color: AppColors.line),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
        border: roundedField,
        enabledBorder: roundedField,
        focusedBorder: roundedField.copyWith(
          borderSide: const BorderSide(color: AppColors.teal, width: 2),
        ),
        prefixIconColor: WidgetStateColor.resolveWith(
          (states) => states.contains(WidgetState.focused)
              ? AppColors.teal
              : AppColors.inkMuted,
        ),
        labelStyle: const TextStyle(color: AppColors.inkMuted),
        floatingLabelStyle: const TextStyle(
          color: AppColors.teal,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyle(color: AppColors.inkMuted.withValues(alpha: 0.7)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(58),
          shape: buttonShape,
          textStyle: buttonText,
          backgroundColor: AppColors.teal,
          disabledBackgroundColor: AppColors.sand,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(58),
          shape: buttonShape,
          textStyle: buttonText,
          backgroundColor: AppColors.teal,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: buttonShape,
          foregroundColor: AppColors.teal,
          side: const BorderSide(color: AppColors.line, width: 1.5),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.teal,
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      chipTheme: ChipThemeData(
        shape: const StadiumBorder(),
        side: BorderSide.none,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600),
        backgroundColor: AppColors.sand,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.forest,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.lg),
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.forest,
          fontWeight: FontWeight.w800,
        ),
      ),
      bannerTheme: const MaterialBannerThemeData(
        backgroundColor: AppColors.marigoldMist,
        surfaceTintColor: Colors.transparent,
        dividerColor: Colors.transparent,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.teal,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, space: 1),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
