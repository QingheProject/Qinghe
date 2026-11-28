import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/student_profile_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/utils/formatters.dart';
import 'package:qinghe_app/app/widgets/app_academic_summary.dart';
import 'package:qinghe_app/app/widgets/app_page.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/app/widgets/app_tag.dart';
import 'package:qinghe_app/app/widgets/reveal.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/data/repositories/local_academic_repository.dart';
import 'package:qinghe_app/data/sources/school_registry.dart';
import 'package:qinghe_app/features/home/controllers/home_controller.dart';
import 'package:qinghe_app/features/home/widgets/course_activity_heatmap.dart';
import 'package:qinghe_app/features/home/widgets/lesson_sheet.dart';
import 'package:qinghe_app/features/home/widgets/today_lessons.dart';
import 'package:qinghe_app/features/timetable_import/views/jwxt_grades_page.dart';

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
        final courseActivity = _controller.courseActivity;
        final school = Get.find<StudentProfileController>().school;
        final academic = Get.find<LocalAcademicRepository>().latestFor(school);
        final gpaMaximum = SchoolRegistry.forSchool(school)?.gpaMaximum;
        final appearance = Get.isRegistered<AppearanceController>()
            ? Get.find<AppearanceController>()
            : null;
        void openLesson(LessonOccurrence lesson) =>
            showLessonDialog(context, lesson, date: now);
        void openAcademics(AcademicSnapshot snapshot) => openJwxtGradesPage(
          context,
          semester: snapshot.semester,
          grades: snapshot.grades,
          gpaMaximum: gpaMaximum,
        );

        final sections = <Widget>[
          Column(
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
                  if (teachingWeek != null) AppTag(label: '第 $teachingWeek 周'),
                ],
              ),
              const SizedBox(height: AppSpace.xs),
              AppPageHeader(title: _controller.greeting),
            ],
          ),
          CourseActivityHeatmap(activity: courseActivity, today: now),
          TodayLessons(
            lessons: lessons,
            minuteOfDay: minute,
            focusLesson: _controller.focusLesson,
            onOpen: openLesson,
            colorScheme:
                appearance?.courseColorScheme.value ?? CourseColorScheme.qinghe,
            saturation: appearance?.scheduleCourseSaturation.value ?? 1,
          ),
          AppAcademicSummary(
            grades: academic?.grades,
            gpaMaximum: gpaMaximum,
            onOpen: academic == null ? null : () => openAcademics(academic),
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
