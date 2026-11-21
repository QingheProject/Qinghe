import 'package:flutter/widgets.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';

/// 由外部动画驱动的渐显上浮。多个 Reveal 共享同一个控制器并错开区间，
/// 形成逐个进入的效果；控制器被重置或反向时同样可以随时打断。
class Reveal extends StatelessWidget {
  const Reveal({
    required this.animation,
    required this.child,
    this.begin = 0,
    this.end = 1,
    this.offset = const Offset(0, 18),
    super.key,
  });

  /// 按序号自动错开区间，适合纵向排列的内容块。
  Reveal.step({
    required this.animation,
    required this.child,
    required int index,
    this.offset = const Offset(0, 18),
    super.key,
  }) : begin = _stepBegin(index),
       end = _stepBegin(index) + _span;

  static const _step = 0.09;
  static const _span = 0.5;

  static double _stepBegin(int index) =>
      (index * _step).clamp(0.0, 1.0 - _span).toDouble();

  final Animation<double> animation;
  final Widget child;
  final double begin;
  final double end;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, child) {
        final t = AppMotion.interval(animation.value, begin, end);
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: offset * (1 - t), child: child),
        );
      },
    );
  }
}
