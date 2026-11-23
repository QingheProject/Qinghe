import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';

/// 个人头像：圆角方块内放一个可选图形，底色取课程色板。
class StudentAvatar extends StatelessWidget {
  const StudentAvatar({
    required this.iconIndex,
    required this.colorIndex,
    this.size = 56,
    this.onTap,
    this.semanticLabel,
    super.key,
  });

  final int iconIndex;
  final int colorIndex;
  final double size;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final tones = CoursePalette.colors(CourseColorScheme.qinghe);
    final base = tones[colorIndex % tones.length];
    final background = Color.alphaBlend(
      base.withValues(alpha: dark ? 0.34 : 0.20),
      context.colors.surface,
    );
    final foreground = dark
        ? Color.lerp(base, Colors.white, 0.48)!
        : Color.lerp(base, Colors.black, 0.16)!;
    final radius = BorderRadius.circular(size * 0.34);
    final icon =
        AppIcons.avatarChoices[iconIndex % AppIcons.avatarChoices.length];

    final body = AnimatedContainer(
      duration: AppMotion.of(context, AppMotion.medium),
      curve: AppMotion.emphasized,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background,
        borderRadius: radius,
        border: Border.all(color: foreground.withValues(alpha: 0.18)),
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: AppMotion.of(context, AppMotion.fast),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: animation.drive(
                Tween<double>(
                  begin: 0.82,
                  end: 1,
                ).chain(CurveTween(curve: AppMotion.springOut)),
              ),
              child: child,
            ),
          ),
          child: Icon(
            icon,
            key: ValueKey('$iconIndex-$colorIndex'),
            size: size * 0.44,
            color: foreground,
          ),
        ),
      ),
    );

    if (onTap == null) return body;
    return Semantics(
      button: true,
      label: semanticLabel ?? '更换头像',
      child: ExcludeSemantics(
        child: Pressable(
          onTap: onTap,
          borderRadius: radius,
          splashColor: foreground.withValues(alpha: 0.12),
          child: body,
        ),
      ),
    );
  }
}
