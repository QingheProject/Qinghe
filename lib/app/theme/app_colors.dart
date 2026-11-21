import 'package:flutter/material.dart';

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
    canvas: Color(0xFFF5F6F2),
    surface: Color(0xFFFFFFFF),
    surfaceMuted: Color(0xFFECEEE8),
    ink: Color(0xFF16201B),
    inkMuted: Color(0xFF5B665F),
    inkFaint: Color(0xFF9AA39D),
    line: Color(0xFFE2E6DF),
    accent: Color(0xFF1F7A5A),
    accentSoft: Color(0xFFDCEEE5),
    onAccent: Color(0xFFFFFFFF),
  );

  static const dark = AppColors(
    canvas: Color(0xFF0F1412),
    surface: Color(0xFF171D1A),
    surfaceMuted: Color(0xFF212924),
    ink: Color(0xFFE9EEEA),
    inkMuted: Color(0xFFA3ADA6),
    inkFaint: Color(0xFF6A746D),
    line: Color(0xFF29312C),
    accent: Color(0xFF4FBF91),
    accentSoft: Color(0xFF1B3429),
    onAccent: Color(0xFF07170F),
  );

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

/// 低饱和的课程配色，按课程的配色序号循环取用。
abstract final class CoursePalette {
  static const _bases = <Color>[
    Color(0xFF2F8F83),
    Color(0xFF4C5FD5),
    Color(0xFFC98A1B),
    Color(0xFFC4506A),
    Color(0xFF7B5CC4),
    Color(0xFF6E8B3D),
  ];

  static CourseTone of(BuildContext context, int index) {
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final base = _bases[index % _bases.length];
    return CourseTone(
      background: Color.alphaBlend(
        base.withValues(alpha: dark ? 0.22 : 0.12),
        colors.surface,
      ),
      foreground: dark
          ? Color.lerp(base, Colors.white, 0.35)!
          : Color.lerp(base, Colors.black, 0.1)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
