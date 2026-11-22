import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';

/// 所有可点击元素的基础：在自身底色上绘制原生水波纹（主题使用 InkSparkle），
/// 并沿用 InkWell 的焦点、悬停、键盘激活与按钮语义。
///
/// 背景色需通过 [color] 传入，而不是放在子组件的装饰里，否则水波纹会被遮住。
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

  /// 深色底上需传入浅色水波纹，保证反馈可见。
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
