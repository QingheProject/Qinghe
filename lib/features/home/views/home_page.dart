import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/utils/formatters.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/app/widgets/icon_action.dart';
import 'package:qinghe_app/app/widgets/reveal.dart';
import 'package:qinghe_app/features/home/controllers/home_controller.dart';
import 'package:qinghe_app/features/home/widgets/focus_lesson_card.dart';
import 'package:qinghe_app/features/home/widgets/lesson_sheet.dart';

/// 首页：问候与当前或下一节课。
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  final _controller = Get.find<HomeController>();
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  );
  Timer? _ticker;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _controller.refreshClock(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _entrance.dispose();
    super.dispose();
  }

  void _comingSoon(String feature) => showAppToast(context, '$feature即将推出');

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: Obx(() {
        final now = _controller.now.value;
        final lessons = _controller.lessons.toList();
        final minute = _controller.minuteOfDay;

        final sections = <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${now.month}月${now.day}日 · ${weekdayLabel(now.weekday)}',
                      style: text.labelMedium,
                    ),
                    const SizedBox(height: AppSpace.xs),
                    Semantics(
                      header: true,
                      child: Text(
                        _controller.greeting,
                        style: text.displaySmall,
                      ),
                    ),
                  ],
                ),
              ),
              IconAction(
                icon: AppIcons.calendar,
                label: '打开日历',
                onTap: () => _comingSoon('日历'),
              ),
            ],
          ),
          if (lessons.isNotEmpty)
            FocusLessonCard(
              lesson: _controller.focusLesson,
              minuteOfDay: minute,
              hasLessonsToday: true,
              onOpen: (lesson, origin) => showLessonDialog(
                context,
                lesson,
                date: now,
                origin: origin,
                originColor: context.colors.accent,
                originRadius: AppRadius.xl,
              ),
            ),
        ];

        return ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.paddingOf(context).bottom + 24,
          ),
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var i = 0; i < sections.length; i++) ...[
                      if (i > 0) const SizedBox(height: AppSpace.xl),
                      Reveal.step(
                        animation: _entrance,
                        index: i,
                        child: sections[i],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
