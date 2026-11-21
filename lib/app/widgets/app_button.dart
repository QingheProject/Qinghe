import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';

enum AppButtonTone { primary, secondary, quiet }

/// 扁平矩形按钮，无描边，以底色区分层级。文字变化时上下交替切换，宽度平滑过渡。
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.tone = AppButtonTone.primary,
    this.icon,
    this.trailingIcon,
    this.expand = false,
    this.dense = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonTone tone;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool expand;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final (background, foreground) = switch (tone) {
      AppButtonTone.primary => (colors.ink, colors.canvas),
      AppButtonTone.secondary => (colors.surfaceMuted, colors.ink),
      AppButtonTone.quiet => (Colors.transparent, colors.inkMuted),
    };
    final duration = AppMotion.of(context, AppMotion.medium);

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: foreground),
          const SizedBox(width: AppSpace.sm),
        ],
        AnimatedSwitcher(
          duration: AppMotion.of(context, AppMotion.fast),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: animation.drive(
                Tween(begin: const Offset(0, 0.35), end: Offset.zero),
              ),
              child: child,
            ),
          ),
          child: Text(
            label,
            key: ValueKey(label),
            style: (dense ? text.labelMedium : text.labelLarge)?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: AppSpace.sm),
          Icon(trailingIcon, size: 18, color: foreground),
        ],
      ],
    );

    return AnimatedOpacity(
      opacity: onPressed == null ? 0.4 : 1,
      duration: duration,
      child: Pressable(
        onTap: onPressed,
        color: background,
        splashColor: foreground.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox(
          height: dense ? 40 : 52,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: dense ? 14 : 22),
            child: AnimatedSize(
              duration: duration,
              curve: AppMotion.emphasized,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
