import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';

abstract final class AppTheme {
  static final light = lightFor(AppAccentTone.qinghe);
  static final dark = darkFor(AppAccentTone.qinghe);

  static ThemeData lightFor(AppAccentTone tone) =>
      _build(AppColors.lightFor(tone), Brightness.light);

  static ThemeData darkFor(AppAccentTone tone) =>
      _build(AppColors.darkFor(tone), Brightness.dark);

  static ThemeData _build(AppColors colors, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.accent,
      onPrimary: colors.onAccent,
      secondary: colors.accent,
      onSecondary: colors.onAccent,
      error: const Color(0xFFC4453C),
      onError: const Color(0xFFFFFFFF),
      surface: colors.surface,
      onSurface: colors.ink,
    );
    final text = _textTheme(colors);
    const fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
      borderSide: BorderSide.none,
    );
    final fieldErrorColor = brightness == Brightness.dark
        ? const Color(0xFFFF9D94)
        : scheme.error;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.canvas,
      canvasColor: colors.canvas,
      textTheme: text,
      inputDecorationTheme: InputDecorationThemeData(
        filled: true,
        fillColor: colors.surfaceMuted,
        border: fieldBorder,
        enabledBorder: fieldBorder,
        disabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: colors.accent, width: 1.5),
        ),
        errorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: fieldErrorColor),
        ),
        focusedErrorBorder: fieldBorder.copyWith(
          borderSide: BorderSide(color: fieldErrorColor, width: 1.5),
        ),
        constraints: const BoxConstraints(minHeight: 48),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        hintStyle: text.bodyMedium?.copyWith(color: colors.inkMuted),
        labelStyle: text.labelMedium,
        helperStyle: text.bodySmall,
        helperMaxLines: 2,
        errorStyle: text.bodySmall?.copyWith(color: fieldErrorColor),
        errorMaxLines: 3,
        suffixIconColor: colors.inkMuted,
      ),
      splashFactory: InkSparkle.splashFactory,
      splashColor: colors.ink.withValues(alpha: 0.08),
      highlightColor: colors.ink.withValues(alpha: 0.04),
      hoverColor: colors.ink.withValues(alpha: 0.04),
      focusColor: colors.accent.withValues(alpha: 0.12),
      dividerTheme: DividerThemeData(
        color: colors.line,
        thickness: 1,
        space: 1,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: colors.ink,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        textStyle: text.labelSmall?.copyWith(color: colors.canvas),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: colors.ink,
        elevation: 0,
        contentTextStyle: text.bodyMedium?.copyWith(color: colors.canvas),
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        modalBarrierColor: colors.ink.withValues(alpha: 0.32),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      extensions: [colors],
    );
  }

  static TextTheme _textTheme(AppColors colors) {
    const base = TextStyle(
      fontFamilyFallback: [
        'PingFang SC',
        'Microsoft YaHei UI',
        'Microsoft YaHei',
        'Noto Sans CJK SC',
        'Source Han Sans SC',
      ],
      height: 1.35,
      leadingDistribution: TextLeadingDistribution.even,
    );

    return TextTheme(
      displaySmall: base.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.6,
        height: 1.2,
        color: colors.ink,
      ),
      headlineSmall: base.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.25,
        color: colors.ink,
      ),
      titleLarge: base.copyWith(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: colors.ink,
      ),
      titleMedium: base.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colors.ink,
      ),
      bodyLarge: base.copyWith(
        fontSize: 15.5,
        height: 1.6,
        color: colors.inkMuted,
      ),
      bodyMedium: base.copyWith(fontSize: 14.5, height: 1.5, color: colors.ink),
      bodySmall: base.copyWith(fontSize: 12.5, color: colors.inkMuted),
      labelLarge: base.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: colors.ink,
      ),
      labelMedium: base.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: colors.inkMuted,
      ),
      labelSmall: base.copyWith(
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
        color: colors.inkMuted,
      ),
    );
  }
}
