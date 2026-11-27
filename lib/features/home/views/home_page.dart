import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/utils/formatters.dart';
import 'package:qinghe_app/app/widgets/app_page.dart';
import 'package:qinghe_app/app/widgets/app_tag.dart';
import 'package:qinghe_app/app/widgets/reveal.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/features/home/controllers/home_controller.dart';
import 'package:qinghe_app/features/home/widgets/focus_lesson_card.dart';
import 'package:qinghe_app/features/home/widgets/lesson_sheet.dart';
import 'package:qinghe_app/features/home/widgets/today_lessons.dart';
import 'package:qinghe_app/features/home/widgets/week_activity_chart.dart';

/// 首页：当前课程、今日安排和本周课程活跃度。
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

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return SafeArea(
      bottom: false,
      child: Obx(() {
        final now = _controller.now.value;
        final lessons = _controller.lessons;
        final minute = _controller.minuteOfDay;
        final teachingWeek = _controller.teachingWeek;
        final weekActivity = _controller.weekActivity;
        void openLesson(LessonOccurrence lesson) =>
            showLessonDialog(context, lesson, date: now);

        final sections = <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: AppSpace.sm,
                      runSpacing: AppSpace.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${now.month}月${now.day}日 · ${weekdayLabel(now.weekday)}',
                          style: text.labelMedium,
                        ),
                        if (teachingWeek != null)
                          AppTag(label: '第 $teachingWeek 周'),
                      ],
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
            ],
          ),
          if (lessons.isNotEmpty)
            FocusLessonCard(
              lesson: _controller.focusLesson,
              minuteOfDay: minute,
              hasLessonsToday: true,
              onOpen: openLesson,
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final agenda = TodayLessons(
                lessons: lessons,
                minuteOfDay: minute,
                onOpen: openLesson,
              );
              final activity = WeekActivityChart(
                activity: weekActivity,
                today: now,
              );
              if (constraints.maxWidth >= 560 &&
                  MediaQuery.textScalerOf(context).scale(16) <= 19) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: agenda),
                    const SizedBox(width: AppSpace.xl),
                    Expanded(flex: 4, child: activity),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  agenda,
                  const SizedBox(height: AppSpace.xl),
                  activity,
                ],
              );
            },
          ),
        ];

        return AppPageContent(
          child: ListView(
            padding: AppPageContent.padding.copyWith(
              bottom:
                  MediaQuery.paddingOf(context).bottom +
                  AppSpace.xl +
                  AppSpace.xs,
            ),
            children: [
              for (var i = 0; i < sections.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSpace.xl),
                Reveal.step(animation: _entrance, index: i, child: sections[i]),
              ],
            ],
          ),
        );
      }),
    );
  }
}
