import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';

/// 构造对话框内容；[close] 会先播放收起动画再退出。
typedef MorphDialogBuilder =
    Widget Function(BuildContext context, VoidCallback close);

/// 从一个矩形（通常是课程卡片）连续放大成对话框。
///
/// 打开时容器按 [origin] 的矩形、[originColor] 的底色与 [originRadius] 的圆角，
/// 连续过渡到居中对话框的尺寸、主题底色与圆角；遮罩同时淡入，内容在容器接近
/// 最终尺寸后才显现。关闭时整体反向播放，容器收回原位再退出路由。
Future<void> showMorphDialog({
  required BuildContext context,
  required MorphDialogBuilder builder,
  Rect? origin,
  Color? originColor,
  double originRadius = AppRadius.md,
  double maxWidth = 520,
  Duration duration = const Duration(milliseconds: 320),
  String barrierLabel = '关闭对话框',
}) {
  return Navigator.of(context).push<void>(
    _MorphDialogRoute(
      builder: builder,
      origin: origin,
      originColor: originColor,
      originRadius: originRadius,
      maxWidth: maxWidth,
      duration: duration,
      barrierLabel: barrierLabel,
    ),
  );
}

class _MorphDialogRoute extends PageRoute<void> {
  _MorphDialogRoute({
    required this.builder,
    required this.origin,
    required this.originColor,
    required this.originRadius,
    required this.maxWidth,
    required this.duration,
    required this.barrierLabel,
  }) : super(settings: const RouteSettings(name: '/morph-dialog'));

  final MorphDialogBuilder builder;
  final Rect? origin;
  final Color? originColor;
  final double originRadius;
  final double maxWidth;
  final Duration duration;

  @override
  final String barrierLabel;

  @override
  bool get opaque => false;

  @override
  Color? get barrierColor => null;

  @override
  bool get barrierDismissible => false;

  /// 展开动画由页面自己的控制器驱动，路由本身不做过渡。
  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  bool get maintainState => false;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _MorphDialog(
      builder: builder,
      origin: origin,
      originColor: originColor,
      originRadius: originRadius,
      maxWidth: maxWidth,
      duration: duration,
      barrierLabel: barrierLabel,
    );
  }
}

class _MorphDialog extends StatefulWidget {
  const _MorphDialog({
    required this.builder,
    required this.origin,
    required this.originColor,
    required this.originRadius,
    required this.maxWidth,
    required this.duration,
    required this.barrierLabel,
  });

  final MorphDialogBuilder builder;
  final Rect? origin;
  final Color? originColor;
  final double originRadius;
  final double maxWidth;
  final Duration duration;
  final String barrierLabel;

  @override
  State<_MorphDialog> createState() => _MorphDialogState();
}

class _MorphDialogState extends State<_MorphDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  final _contentKey = GlobalKey();
  double? _contentHeight;
  bool _closing = false;
  int _measureAttempts = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _targetWidth =>
      math.min(widget.maxWidth, MediaQuery.sizeOf(context).width - 40);

  double get _maxContentHeight {
    final size = MediaQuery.sizeOf(context);
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    return math.max(180, size.height * 0.82 - inset * 0.5);
  }

  /// 量出内容在目标宽度下的自然高度，量到之后才开始放大。
  void _measure() {
    if (!mounted) return;
    final render = _contentKey.currentContext?.findRenderObject();
    if (render is! RenderBox || !render.hasSize) {
      if (_measureAttempts++ < 4) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
      }
      return;
    }
    final height = render.size.height;
    if (_contentHeight == null) {
      setState(() => _contentHeight = height);
      _controller.forward();
      return;
    }
    if ((height - _contentHeight!).abs() > 0.5) {
      setState(() => _contentHeight = height);
    }
  }

  Future<void> _close() async {
    if (_closing) return;
    _closing = true;
    await _controller.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final contentHeight = _contentHeight;
    return SizedBox.expand(
      child: contentHeight == null
          ? _measureLayer(context)
          : _morphLayer(context, contentHeight),
    );
  }

  /// 先在目标宽度下摆好内容但不显示，只用于测量自然高度。
  Widget _measureLayer(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: OverflowBox(
              alignment: Alignment.topCenter,
              minHeight: 0,
              maxHeight: double.infinity,
              child: SizedBox(
                width: _targetWidth,
                child: Opacity(
                  opacity: 0,
                  child: SizedBox(
                    key: _contentKey,
                    child: widget.builder(context, _close),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _morphLayer(BuildContext context, double contentHeight) {
    final colors = context.colors;
    final size = MediaQuery.sizeOf(context);
    final inset = MediaQuery.viewInsetsOf(context).bottom;
    final targetWidth = _targetWidth;
    final targetHeight = math.min(contentHeight, _maxContentHeight);
    final center = Offset(size.width / 2, (size.height - inset) / 2);
    final startRect =
        widget.origin ??
        Rect.fromCenter(
          center: center,
          width: math.max(targetWidth * 0.62, 180),
          height: math.max(targetHeight * 0.34, 120),
        );
    final startColor = Color.alphaBlend(
      widget.originColor ?? colors.accent,
      colors.surface,
    );

    return Stack(
      children: [
        // 遮罩：随容器展开逐渐加深，点击收起整段动画。
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final opacity =
                AppMotion.interval(_controller.value, 0, 0.72) * 0.42;
            return Positioned.fill(
              child: Semantics(
                label: widget.barrierLabel,
                button: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _close,
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: opacity),
                  ),
                ),
              ),
            );
          },
        ),
        // 高度变化（例如切到编辑态、弹出键盘）时平滑过渡，不打断展开。
        TweenAnimationBuilder<double>(
          tween: Tween<double>(end: targetHeight),
          duration: AppMotion.of(context, const Duration(milliseconds: 260)),
          curve: AppMotion.emphasized,
          builder: (context, animatedHeight, _) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final progress = AppMotion.emphasized.transform(
                  _controller.value,
                );
                final rect = Rect.lerp(
                  startRect,
                  Rect.fromCenter(
                    center: center,
                    width: targetWidth,
                    height: animatedHeight,
                  ),
                  progress,
                )!;
                final radius = BorderRadius.circular(
                  widget.originRadius +
                      (AppRadius.xl - widget.originRadius) * progress,
                );
                final contentProgress = AppMotion.interval(
                  _controller.value,
                  0.34,
                  0.94,
                );

                return Positioned.fromRect(
                  rect: rect,
                  child: IgnorePointer(
                    ignoring: contentProgress < 0.6,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          startColor,
                          colors.surface,
                          AppMotion.interval(_controller.value, 0, 0.8),
                        ),
                        borderRadius: radius,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: 0.18 * progress,
                            ),
                            blurRadius: 40 * progress,
                            offset: Offset(0, 16 * progress),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: radius,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            OverflowBox(
                              alignment: Alignment.topCenter,
                              minWidth: targetWidth,
                              maxWidth: targetWidth,
                              minHeight: 0,
                              maxHeight: double.infinity,
                              child: SizedBox(
                                width: targetWidth,
                                height: animatedHeight,
                                child: SingleChildScrollView(
                                  physics: const ClampingScrollPhysics(),
                                  child: Opacity(
                                    opacity: contentProgress,
                                    child: Transform.scale(
                                      alignment: Alignment.topCenter,
                                      scale: 0.98 + 0.02 * contentProgress,
                                      child:
                                          NotificationListener<
                                            SizeChangedLayoutNotification
                                          >(
                                            onNotification: (_) {
                                              WidgetsBinding.instance
                                                  .addPostFrameCallback(
                                                    (_) => _measure(),
                                                  );
                                              return true;
                                            },
                                            child: SizeChangedLayoutNotifier(
                                              child: SizedBox(
                                                key: _contentKey,
                                                child: widget.builder(
                                                  context,
                                                  _close,
                                                ),
                                              ),
                                            ),
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
