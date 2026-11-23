import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const double micro = 10;
  static const double caption = 12;
  static const double body = 14;
  static const double bodyLarge = 16;
  static const double title = 18;
  static const double heading = 22;
  static const double headline = 28;
  static const double display = 36;
}

abstract final class AppSpacing {
  static const double xSmall = 4;
  static const double small = 8;
  static const double medium = 12;
  static const double large = 16;
  static const double xLarge = 24;
  static const double xxLarge = 32;

  static const double controlHeight = 48;
  static const double controlRadius = 14;
  static const double cardRadius = 16;
  static const double pageHorizontal = 16;
}

class AppTheme {
  AppTheme._();

  static const Color primary = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFFF59E0B);
  static const Color lightPageBackground = Color(0xFFF7F7FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF1B2130);
  static const Color lightMutedText = Color(0xFF626B7C);
  static const Color pageBackground = Color(0xFF0B1020);
  static const Color surface = Color(0xFF131C2E);
  static const Color fieldBackground = Color(0xFF182237);
  static const Color border = Color(0xFF26334A);
  static const Color text = Color(0xFFF5F4FB);
  static const Color mutedText = Color(0xFF9A9BAD);

  static ThemeData get light {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
        ).copyWith(
          primary: primary,
          onPrimary: Colors.white,
          secondary: accent,
          onSecondary: lightText,
          surface: lightSurface,
          onSurface: lightText,
          error: const Color(0xFFB3261E),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: lightPageBackground,
      canvasColor: lightPageBackground,
      cardColor: lightSurface,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: lightPageBackground,
        foregroundColor: lightText,
        elevation: 0,
        toolbarHeight: 56,
      ),
      dividerColor: const Color(0xFFE1E4EC),
      iconTheme: const IconThemeData(color: lightMutedText),
      textTheme: ThemeData.light().textTheme.apply(
        bodyColor: lightText,
        displayColor: lightText,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F1F6),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          borderSide: const BorderSide(color: Color(0xFFD6DAE4)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          borderSide: const BorderSide(color: Color(0xFFD6DAE4)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: const BorderSide(color: Color(0xFFE1E4EC)),
        ),
      ),
    );
  }

  static ThemeData get dark {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.dark,
        ).copyWith(
          primary: primary,
          onPrimary: Colors.white,
          secondary: accent,
          onSecondary: pageBackground,
          surface: surface,
          onSurface: text,
          error: const Color(0xFFFF6B79),
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: pageBackground,
      canvasColor: pageBackground,
      cardColor: surface,
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        backgroundColor: pageBackground,
        foregroundColor: text,
        elevation: 0,
        toolbarHeight: 56,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: AppTypography.title,
          fontWeight: FontWeight.w700,
        ),
      ),
      dividerColor: border,
      iconTheme: const IconThemeData(color: mutedText),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: text,
          fontSize: AppTypography.display,
          height: 1.15,
          fontWeight: FontWeight.w700,
        ),
        headlineLarge: TextStyle(
          color: text,
          fontSize: AppTypography.headline,
          height: 1.2,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: TextStyle(
          color: text,
          fontSize: AppTypography.heading,
          height: 1.2,
          fontWeight: FontWeight.w700,
        ),
        titleLarge: TextStyle(
          color: text,
          fontSize: AppTypography.heading,
          height: 1.25,
          fontWeight: FontWeight.w700,
        ),
        titleMedium: TextStyle(
          color: text,
          fontSize: AppTypography.title,
          height: 1.3,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: TextStyle(
          color: text,
          fontSize: AppTypography.bodyLarge,
          height: 1.3,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: text,
          fontSize: AppTypography.bodyLarge,
          height: 1.5,
        ),
        bodyMedium: TextStyle(
          color: text,
          fontSize: AppTypography.body,
          height: 1.45,
        ),
        bodySmall: TextStyle(
          color: mutedText,
          fontSize: AppTypography.caption,
          height: 1.4,
        ),
        labelLarge: TextStyle(
          color: text,
          fontSize: AppTypography.body,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: TextStyle(
          color: mutedText,
          fontSize: AppTypography.caption,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: TextStyle(
          color: mutedText,
          fontSize: AppTypography.micro,
          fontWeight: FontWeight.w500,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldBackground,
        labelStyle: const TextStyle(color: mutedText),
        hintStyle: const TextStyle(color: mutedText),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.large,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          borderSide: const BorderSide(color: Color(0xFFFF6B79)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          borderSide: const BorderSide(color: Color(0xFFFF6B79), width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
          backgroundColor: primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSpacing.controlHeight),
          foregroundColor: text,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.controlRadius),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          side: const BorderSide(color: border),
        ),
      ),
    );
  }
}
