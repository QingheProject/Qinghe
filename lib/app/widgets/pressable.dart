import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';

/// 将点击波纹画在组件自身底色上。
class Pressable extends StatelessWidget {
  const Pressable({
    required this.child,
    this.onTap,
    this.semanticLabel,
    this.selected,
    this.color = Colors.transparent,
    this.borderRadius = BorderRadius.zero,
    this.splashColor,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final bool? selected;
  final Color color;
  final BorderRadius borderRadius;
  final Color? splashColor;

  @override
  Widget build(BuildContext context) {
    final transparent = color.a == 0;
    return Semantics(
      button: true,
      enabled: onTap != null,
      selected: selected,
      label: semanticLabel,
      child: Material(
        animationDuration: AppMotion.of(context, AppMotion.medium),
        type: transparent ? MaterialType.transparency : MaterialType.canvas,
        color: transparent ? null : color,
        borderRadius: transparent ? null : borderRadius,
        clipBehavior: transparent ? Clip.none : Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          splashColor: splashColor,
          highlightColor: splashColor?.withValues(alpha: splashColor!.a * 0.5),
          child: child,
        ),
      ),
    );
  }
}
