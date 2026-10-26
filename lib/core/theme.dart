import 'package:flutter/material.dart';

abstract final class AppColors {
  static const ink = Color(0xFF0F172A);
  static const inkSoft = Color(0xFF1E293B);
  static const accent = Color(0xFFF97316);
  static const accentDark = Color(0xFFEA580C);
  static const accentSoft = Color(0xFFFFEDD5);
  static const canvas = Color(0xFFF6F7F9);
  static const line = Color(0xFFE2E8F0);
  static const muted = Color(0xFF64748B);
  static const success = Color(0xFF15803D);
  static const successSoft = Color(0xFFDCFCE7);
  static const warning = Color(0xFFB45309);
  static const warningSoft = Color(0xFFFEF3C7);
  static const danger = Color(0xFFDC2626);
  static const dangerSoft = Color(0xFFFEE2E2);
}

ThemeData buildTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.accent,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.ink,
        onPrimary: Colors.white,
        primaryContainer: const Color(0xFFE2E8F0),
        onPrimaryContainer: AppColors.ink,
        secondary: AppColors.accent,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.accentSoft,
        onSecondaryContainer: const Color(0xFF7C2D12),
        tertiary: AppColors.accentDark,
        onTertiary: Colors.white,
        tertiaryContainer: AppColors.accentSoft,
        onTertiaryContainer: const Color(0xFF7C2D12),
        error: AppColors.danger,
        onError: Colors.white,
        errorContainer: AppColors.dangerSoft,
        onErrorContainer: const Color(0xFF991B1B),
        surface: Colors.white,
        onSurface: AppColors.ink,
        onSurfaceVariant: AppColors.muted,
        surfaceDim: const Color(0xFFE2E8F0),
        surfaceBright: Colors.white,
        surfaceContainerLowest: Colors.white,
        surfaceContainerLow: const Color(0xFFF8FAFC),
        surfaceContainer: const Color(0xFFF1F5F9),
        surfaceContainerHigh: const Color(0xFFE8EDF3),
        surfaceContainerHighest: const Color(0xFFE2E8F0),
        surfaceTint: Colors.transparent,
        outline: const Color(0xFF94A3B8),
        outlineVariant: AppColors.line,
        inverseSurface: AppColors.inkSoft,
        onInverseSurface: const Color(0xFFF8FAFC),
        inversePrimary: AppColors.accent,
        shadow: Colors.black,
        scrim: Colors.black,
      );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.canvas,
  );

  OutlineInputBorder border(Color color, {double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    iconTheme: const IconThemeData(color: AppColors.inkSoft),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 1,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 12,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
        color: AppColors.ink,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      contentTextStyle: const TextStyle(
        color: AppColors.muted,
        fontSize: 14,
        height: 1.5,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: Colors.white,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      textStyle: const TextStyle(color: AppColors.ink, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.inkSoft,
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      actionTextColor: AppColors.accent,
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    badgeTheme: const BadgeThemeData(
      backgroundColor: AppColors.accent,
      textColor: Colors.white,
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: AppColors.inkSoft,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: Colors.white, fontSize: 12),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: border(AppColors.line),
      enabledBorder: border(AppColors.line),
      disabledBorder: border(AppColors.line),
      focusedBorder: border(AppColors.accent, width: 1.6),
      errorBorder: border(AppColors.danger),
      focusedErrorBorder: border(AppColors.danger, width: 1.6),
      errorStyle: const TextStyle(color: AppColors.danger, fontSize: 12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.ink,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        side: const BorderSide(color: AppColors.line),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accentDark,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) => Colors.white),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.accent
            : const Color(0xFFCBD5E1),
      ),
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? AppColors.accent
            : const Color(0xFF94A3B8),
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.accent,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: AppColors.accent,
      selectionColor: AppColors.accent.withValues(alpha: 0.25),
      selectionHandleColor: AppColors.accent,
    ),
    scrollbarTheme: const ScrollbarThemeData(
      thumbColor: WidgetStatePropertyAll(Color(0xFFCBD5E1)),
      radius: Radius.circular(8),
      thickness: WidgetStatePropertyAll(6),
    ),
    chipTheme: base.chipTheme.copyWith(
      backgroundColor: Colors.white,
      selectedColor: AppColors.ink,
      disabledColor: AppColors.canvas,
      secondarySelectedColor: AppColors.ink,
      side: const BorderSide(color: AppColors.line),
      labelStyle: const TextStyle(
        color: AppColors.ink,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
      ),
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),
  );
}
