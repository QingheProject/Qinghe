import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/widgets/brand_mark.dart';
import 'package:qinghe_app/app/widgets/reveal.dart';
import 'package:qinghe_app/features/splash/controllers/splash_controller.dart';

/// 加载页：标志描绘 → 字标浮现 → 底部进度线走完后进入下一页。
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  final _controller = Get.find<SplashController>();
  late final AnimationController _intro;
  late final Animation<double> _markProgress;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _intro =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1700),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) _controller.leave();
        });
    _markProgress = _intro.drive(CurveTween(curve: const Interval(0, 0.62)));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _intro.duration = const Duration(milliseconds: 240);
    }
    _intro.forward();
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.canvas,
      body: Stack(
        children: [
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BrandMark(size: 84, progress: _markProgress),
                const SizedBox(height: 26),
                Reveal(
                  animation: _intro,
                  begin: 0.42,
                  end: 0.78,
                  offset: const Offset(0, 12),
                  child: Padding(
                    // 补偿字距带来的右侧留白，使字标视觉居中。
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      '青禾',
                      style: text.displaySmall?.copyWith(letterSpacing: 10),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Reveal(
                  animation: _intro,
                  begin: 0.52,
                  end: 0.88,
                  offset: const Offset(0, 10),
                  child: Text(
                    '离线 · 简约 · 大学课表',
                    style: text.labelMedium?.copyWith(letterSpacing: 3),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: Center(child: _LoadingLine(animation: _intro)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingLine extends StatelessWidget {
  const _LoadingLine({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      label: '正在加载',
      child: SizedBox(
        width: 72,
        height: 2,
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = AppMotion.interval(
              animation.value,
              0.08,
              1,
              Curves.easeInOutCubic,
            );
            return DecoratedBox(
              decoration: BoxDecoration(
                color: colors.line,
                borderRadius: BorderRadius.circular(1),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: t,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
