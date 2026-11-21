import 'package:flutter/widgets.dart';

/// 动效参数。所有动画都由可中断的控制器或隐式动画驱动，
/// 新的状态到来时直接从当前值继续，不排队播放过时的动画。
abstract final class AppMotion {
  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 520);

  /// 进场与位移使用的强调曲线：快速启动、柔和收尾。
  static const emphasized = Cubic(0.2, 0, 0, 1);

  /// 带轻微回弹的释放曲线，用于按压回弹。
  static const springOut = Cubic(0.34, 1.4, 0.64, 1);

  /// 系统开启“减少动画”时为 true。
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// 减少动画时把时长压缩为极短的即时反馈。
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? const Duration(milliseconds: 1) : duration;

  /// 把整体进度 [t] 映射到 [begin, end] 区间内的局部进度。
  static double interval(
    double t,
    double begin,
    double end, [
    Curve curve = emphasized,
  ]) {
    if (t <= begin) return 0;
    if (t >= end) return 1;
    return curve.transform((t - begin) / (end - begin));
  }
}
