import 'package:flutter/material.dart';

enum AppAccentTone { qinghe, ocean, violet, amber, rose }

enum CourseColorScheme { qinghe, ocean, sunset, candy, monochrome }

/// 青禾的语义色板。页面只使用这里的语义名称，不直接写死颜色值。
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.canvas,
    required this.surface,
    required this.surfaceMuted,
    required this.ink,
    required this.inkMuted,
    required this.inkFaint,
    required this.line,
    required this.accent,
    required this.accentSoft,
    required this.onAccent,
  });

  /// 页面底色。
  final Color canvas;

  /// 卡片与导航等承载内容的表面。
  final Color surface;

  /// 次级表面，例如占位块、轨道。
  final Color surfaceMuted;

  /// 主要文字。
  final Color ink;

  /// 次要文字。
  final Color inkMuted;

  /// 辅助文字与禁用态。
  final Color inkFaint;

  /// 发丝线与描边。
  final Color line;

  /// 品牌强调色（青绿）。
  final Color accent;

  /// 强调色的浅色底。
  final Color accentSoft;

  /// 位于强调色之上的文字与图形。
  final Color onAccent;

  static const light = AppColors(
    canvas: Color(0xFFF6F6F6),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFEDEDED),
    ink: Color(0xFF1C1C1C),
    inkMuted: Color(0xFF606060),
    inkFaint: Color(0xFF9A9A9A),
    line: Color(0xFFE3E3E3),
    accent: Color(0xFF1F7A5A),
    accentSoft: Color(0xFFDCEEE5),
    onAccent: Color(0xFFFFFFFF),
  );

  static const dark = AppColors(
    canvas: Color(0xFF111111),
    surface: Color(0xFF1A1A1A),
    surfaceMuted: Color(0xFF252525),
    ink: Color(0xFFECECEC),
    inkMuted: Color(0xFFA8A8A8),
    inkFaint: Color(0xFF707070),
    line: Color(0xFF303030),
    accent: Color(0xFF4FBF91),
    accentSoft: Color(0xFF1B3429),
    onAccent: Color(0xFF07170F),
  );

  static AppColors lightFor(AppAccentTone tone) => switch (tone) {
    AppAccentTone.qinghe => light,
    AppAccentTone.ocean => light.copyWith(
      accent: const Color(0xFF3267C8),
      accentSoft: const Color(0xFFDDE8FA),
    ),
    AppAccentTone.violet => light.copyWith(
      accent: const Color(0xFF7557B7),
      accentSoft: const Color(0xFFE8E0F4),
    ),
    AppAccentTone.amber => light.copyWith(
      accent: const Color(0xFFB85B23),
      accentSoft: const Color(0xFFF5E3D7),
    ),
    AppAccentTone.rose => light.copyWith(
      accent: const Color(0xFFB64D69),
      accentSoft: const Color(0xFFF4DDE4),
    ),
  };

  static AppColors darkFor(AppAccentTone tone) => switch (tone) {
    AppAccentTone.qinghe => dark,
    AppAccentTone.ocean => dark.copyWith(
      accent: const Color(0xFF7BA7F2),
      accentSoft: const Color(0xFF1A2A45),
      onAccent: const Color(0xFF08111F),
    ),
    AppAccentTone.violet => dark.copyWith(
      accent: const Color(0xFFA991E1),
      accentSoft: const Color(0xFF2A203A),
      onAccent: const Color(0xFF120A20),
    ),
    AppAccentTone.amber => dark.copyWith(
      accent: const Color(0xFFE4935D),
      accentSoft: const Color(0xFF3A2418),
      onAccent: const Color(0xFF211006),
    ),
    AppAccentTone.rose => dark.copyWith(
      accent: const Color(0xFFE0879F),
      accentSoft: const Color(0xFF3B2029),
      onAccent: const Color(0xFF200A11),
    ),
  };

  @override
  AppColors copyWith({
    Color? canvas,
    Color? surface,
    Color? surfaceMuted,
    Color? ink,
    Color? inkMuted,
    Color? inkFaint,
    Color? line,
    Color? accent,
    Color? accentSoft,
    Color? onAccent,
  }) {
    return AppColors(
      canvas: canvas ?? this.canvas,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      ink: ink ?? this.ink,
      inkMuted: inkMuted ?? this.inkMuted,
      inkFaint: inkFaint ?? this.inkFaint,
      line: line ?? this.line,
      accent: accent ?? this.accent,
      accentSoft: accentSoft ?? this.accentSoft,
      onAccent: onAccent ?? this.onAccent,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    return AppColors(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      inkFaint: Color.lerp(inkFaint, other.inkFaint, t)!,
      line: Color.lerp(line, other.line, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentSoft: Color.lerp(accentSoft, other.accentSoft, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
    );
  }
}

/// 课程色块的底色与前景色。
@immutable
class CourseTone {
  const CourseTone({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

/// 课程配色，按课程的配色序号循环取用。
abstract final class CoursePalette {
  static const _schemes = <CourseColorScheme, List<Color>>{
    CourseColorScheme.qinghe: [
      Color(0xFF2A9D8F),
      Color(0xFF4361EE),
      Color(0xFFE09F1F),
      Color(0xFFD94F70),
      Color(0xFF8755D9),
      Color(0xFF6C9A32),
      Color(0xFFE76F51),
      Color(0xFF2780C2),
    ],
    CourseColorScheme.ocean: [
      Color(0xFF168AAD),
      Color(0xFF3A67D8),
      Color(0xFF2C9BC2),
      Color(0xFF5A5FC7),
      Color(0xFF159A84),
      Color(0xFF557FA6),
      Color(0xFF25A5A5),
      Color(0xFF4A78E0),
    ],
    CourseColorScheme.sunset: [
      Color(0xFFD56A2D),
      Color(0xFFC84855),
      Color(0xFFD39B24),
      Color(0xFFA64F78),
      Color(0xFFD05732),
      Color(0xFF8F6446),
      Color(0xFFE27B3F),
      Color(0xFFB43C64),
    ],
    CourseColorScheme.candy: [
      Color(0xFF9254D8),
      Color(0xFFDD4F88),
      Color(0xFF3E7EDC),
      Color(0xFFE77838),
      Color(0xFF20A08B),
      Color(0xFF7FA22E),
      Color(0xFFD55FC2),
      Color(0xFF5B5DE0),
    ],
    CourseColorScheme.monochrome: [
      Color(0xFF171717),
      Color(0xFF343434),
      Color(0xFF505050),
      Color(0xFF6B6B6B),
      Color(0xFF858585),
      Color(0xFF9E9E9E),
      Color(0xFFB8B8B8),
      Color(0xFFD0D0D0),
    ],
  };

  static List<Color> colors(
    CourseColorScheme scheme, [
    double saturation = 1,
  ]) => _schemes[scheme]!
      .map((color) => _withSaturation(color, saturation))
      .toList(growable: false);

  static CourseTone of(
    BuildContext context,
    int index, [
    CourseColorScheme scheme = CourseColorScheme.qinghe,
    double saturation = 1,
  ]) {
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final bases = _schemes[scheme]!;
    final base = _withSaturation(bases[index % bases.length], saturation);
    return CourseTone(
      background: Color.alphaBlend(
        base.withValues(alpha: dark ? 0.30 : 0.20),
        colors.surface,
      ),
      foreground: dark
          ? Color.lerp(base, Colors.white, 0.42)!
          : Color.lerp(base, Colors.black, 0.12)!,
    );
  }

  static Color _withSaturation(Color color, double saturation) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withSaturation(
          (hsl.saturation * saturation.clamp(0, 1)).clamp(0, 1).toDouble(),
        )
        .toColor();
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
