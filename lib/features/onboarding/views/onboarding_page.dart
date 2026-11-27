import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/app_button.dart';
import 'package:qinghe_app/app/widgets/brand_mark.dart';
import 'package:qinghe_app/app/widgets/icon_action.dart';
import 'package:qinghe_app/app/widgets/reveal.dart';
import 'package:qinghe_app/app/widgets/step_indicator.dart';
import 'package:qinghe_app/features/onboarding/controllers/onboarding_controller.dart';
import 'package:qinghe_app/features/onboarding/widgets/onboarding_illustrations.dart';

class _StepContent {
  const _StepContent({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.illustration,
  });

  final String eyebrow;
  final String title;
  final String body;
  final Widget Function(Animation<double> animation) illustration;
}

final _steps = <_StepContent>[
  _StepContent(
    eyebrow: '01  完整周视图',
    title: '一眼看完\n整整一周',
    body: '七天与全部节次完整铺开，压缩标题，把空间留给课程。',
    illustration: (a) => WeekGridIllustration(animation: a),
  ),
  _StepContent(
    eyebrow: '02  灵活周次',
    title: '单双周与调课\n都能说清',
    body: '按教学周记录上课安排；调课只改这一次，其余周次保持不变。',
    illustration: (a) => FlexibleWeeksIllustration(animation: a),
  ),
  _StepContent(
    eyebrow: '03  离线与提醒',
    title: '不用联网\n也不会错过',
    body: '课表保存在本机，查看与编辑不依赖网络；上课前按你的设置提醒。',
    illustration: (a) => ReminderIllustration(animation: a),
  ),
  _StepContent(
    eyebrow: '准备就绪',
    title: '开始你的\n新学期',
    body: '先建立学期与节次，或使用模板导入课程。这些都可以稍后在“我的”中完成。',
    illustration: (a) => ReadyIllustration(animation: a),
  ),
];

/// 开始使用引导：每一步的插画、标题与说明依次进入。
class OnboardingPage extends GetView<OnboardingController> {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    assert(_steps.length == OnboardingController.stepCount);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              children: [
                _TopBar(controller: controller),
                Expanded(child: _StepArea(controller: controller)),
                _BottomBar(controller: controller),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.controller});

  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xl,
        AppSpace.sm,
        AppSpace.md,
        0,
      ),
      child: SizedBox(
        height: 48,
        child: Row(
          children: [
            const BrandMark(size: 26),
            const SizedBox(width: 10),
            Text('青禾', style: text.titleMedium?.copyWith(letterSpacing: 2)),
            const Spacer(),
            Obx(() {
              final hidden = controller.isLast;
              return IgnorePointer(
                ignoring: hidden,
                child: AnimatedOpacity(
                  opacity: hidden ? 0 : 1,
                  duration: AppMotion.of(context, AppMotion.fast),
                  child: AppButton(
                    label: '跳过',
                    tone: AppButtonTone.quiet,
                    dense: true,
                    onPressed: controller.skip,
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StepArea extends StatelessWidget {
  const _StepArea({required this.controller});

  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity < -250) controller.swipeNext();
        if (velocity > 250) controller.back();
      },
      child: Obx(() {
        final step = controller.step.value;
        final direction = controller.direction;
        final currentKey = ValueKey(step);
        return AnimatedSwitcher(
          duration: AppMotion.of(context, AppMotion.medium),
          switchInCurve: AppMotion.emphasized,
          switchOutCurve: Curves.easeIn,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topCenter,
            children: [...previous, ?current],
          ),
          transitionBuilder: (child, animation) {
            // 进入的一页从前进方向滑入，离开的一页朝反方向退出。
            final incoming = child.key == currentKey;
            final dx = (incoming ? 1 : -1) * direction * 0.08;
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: animation.drive(
                  Tween(begin: Offset(dx, 0), end: Offset.zero),
                ),
                child: child,
              ),
            );
          },
          child: _StepView(key: currentKey, content: _steps[step]),
        );
      }),
    );
  }
}

class _StepView extends StatefulWidget {
  const _StepView({required this.content, super.key});

  final _StepContent content;

  @override
  State<_StepView> createState() => _StepViewState();
}

class _StepViewState extends State<_StepView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _reveal.value = 1;
    } else {
      _reveal.forward();
    }
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final content = widget.content;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpace.lg),
              child: Center(
                child: Reveal(
                  animation: _reveal,
                  end: 0.5,
                  offset: const Offset(0, 24),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: content.illustration(_reveal),
                  ),
                ),
              ),
            ),
          ),
          Reveal(
            animation: _reveal,
            begin: 0.22,
            end: 0.62,
            child: Text(
              content.eyebrow,
              style: text.labelSmall?.copyWith(
                color: colors.accent,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Reveal(
            animation: _reveal,
            begin: 0.3,
            end: 0.72,
            child: Semantics(
              header: true,
              child: Text(content.title, style: text.displaySmall),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Reveal(
            animation: _reveal,
            begin: 0.4,
            end: 0.84,
            child: Text(content.body, style: text.bodyLarge),
          ),
          const SizedBox(height: AppSpace.xl),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.controller});

  final OnboardingController controller;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.of(context, AppMotion.medium);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xl,
        AppSpace.sm,
        AppSpace.xl,
        AppSpace.xl,
      ),
      child: Obx(() {
        final step = controller.step.value;
        return Row(
          children: [
            StepIndicator(count: OnboardingController.stepCount, current: step),
            const Spacer(),
            AnimatedSize(
              duration: duration,
              curve: AppMotion.emphasized,
              child: AnimatedSwitcher(
                duration: duration,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: ScaleTransition(scale: animation, child: child),
                ),
                child: controller.isFirst
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: IconAction(
                          icon: AppIcons.arrowBack,
                          label: '上一步',
                          onTap: controller.back,
                        ),
                      ),
              ),
            ),
            AppButton(
              label: controller.isLast ? '开始使用' : '继续',
              trailingIcon: AppIcons.arrowForward,
              onPressed: controller.next,
            ),
          ],
        );
      }),
    );
  }
}
