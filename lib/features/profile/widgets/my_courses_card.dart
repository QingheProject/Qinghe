import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/routes/app_routes.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/utils/formatters.dart';
import 'package:qinghe_app/app/widgets/app_button.dart';
import 'package:qinghe_app/app/widgets/app_expansion_icon.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/data/models/timetable.dart';
import 'package:qinghe_app/data/models/timetable_rule.dart';
import 'package:qinghe_app/features/home/widgets/lesson_sheet.dart';

class MyCoursesCard extends StatelessWidget {
  const MyCoursesCard({required this.timetable, required this.now, super.key});

  final Timetable? timetable;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final table = timetable;
    final text = Theme.of(context).textTheme;
    if (table == null || table.rules.isEmpty) {
      return AppPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('我的课程', style: text.titleLarge),
            const SizedBox(height: AppSpace.xs),
            Text(
              table == null ? '导入课表后可查看课程和上课时间。' : '${table.config.name}还没有课程。',
              style: text.bodySmall,
            ),
            const SizedBox(height: AppSpace.md),
            AppButton(
              icon: AppIcons.upload,
              label: '导入课表',
              tone: AppButtonTone.secondary,
              onPressed: () => Get.toNamed<void>(AppRoutes.timetableImport),
            ),
          ],
        ),
      );
    }

    final monday = now.day - now.weekday + DateTime.monday;
    var weekLessons = 0;
    for (var offset = 0; offset < 7; offset++) {
      weekLessons += table
          .lessonsOn(DateTime(now.year, now.month, monday + offset))
          .length;
    }
    final courses = <String, List<TimetableRule>>{};
    for (final rule in table.rules) {
      (courses[rule.courseId] ??= []).add(rule);
    }
    final upcoming = _upcoming(table).take(3).toList();

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('我的课程', style: text.titleLarge),
          Text(table.config.name, style: text.bodySmall),
          const SizedBox(height: AppSpace.lg),
          Row(
            key: const ValueKey('my-course-summary'),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppMetric(label: '课程总数', value: courses.length),
              ),
              Expanded(
                child: AppMetric(label: '本周上课次数', value: weekLessons),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          const Divider(),
          const SizedBox(height: AppSpace.sm),
          if (upcoming.isEmpty)
            Text('当前学期没有待上的课', style: text.bodySmall)
          else ...[
            Text('接下来的课', style: text.labelMedium),
            for (final (day, lesson) in upcoming)
              _CourseRow(lesson: lesson, prefix: '${day.month}月${day.day}日'),
          ],
          const SizedBox(height: AppSpace.sm),
          AppButton(
            label: '查看全部课程',
            tone: AppButtonTone.secondary,
            expand: true,
            onPressed: () =>
                _showCourses(context, table, courses.values.toList()),
          ),
        ],
      ),
    );
  }

  void _showCourses(
    BuildContext context,
    Timetable table,
    List<List<TimetableRule>> courses,
  ) {
    showModalBottomSheet<void>(
      context: context,
      sheetAnimationStyle: AppMotion.style(context),
      isScrollControlled: true,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 640),
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.84,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '全部课程',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: '关闭全部课程',
                      icon: const Icon(AppIcons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  itemCount: courses.length,
                  itemBuilder: (context, index) {
                    final group = courses[index];
                    return ExpansionTile(
                      trailing: const AppExpansionIcon(),
                      tilePadding: EdgeInsets.zero,
                      shape: const Border(),
                      title: Text(group.first.name),
                      subtitle: Text('${group.length} 条上课安排'),
                      children: [
                        for (final rule in group)
                          _CourseRow(
                            lesson: rule.lessonFor(
                              table.config,
                              _firstDate(table, rule),
                            ),
                            prefix: weekdayLabel(rule.weekday),
                            showName: false,
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Iterable<(DateTime, LessonOccurrence)> _upcoming(Timetable table) sync* {
    final first = table.config.week1Monday;
    final today = DateTime(now.year, now.month, now.day);
    final start = today.isBefore(first) ? first : today;
    final last = DateTime(
      first.year,
      first.month,
      first.day + table.config.weekCount * 7,
    );
    for (var offset = 0; ; offset++) {
      final date = DateTime(start.year, start.month, start.day + offset);
      if (!date.isBefore(last)) return;
      for (final lesson in table.lessonsOn(date)) {
        if (date != today || lesson.endMinute > now.hour * 60 + now.minute) {
          yield (date, lesson);
        }
      }
    }
  }

  DateTime _firstDate(Timetable table, TimetableRule rule) {
    final first = table.config.week1Monday;
    return DateTime(
      first.year,
      first.month,
      first.day + (rule.weeks.first - 1) * 7 + rule.weekday - 1,
    );
  }
}

class _CourseRow extends StatelessWidget {
  const _CourseRow({
    required this.lesson,
    required this.prefix,
    this.showName = true,
  });

  final LessonOccurrence lesson;
  final String prefix;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    final appearance = Get.find<AppearanceController>();
    return Obx(() {
      final location = appearance.scheduleShowLocation.value;
      final teacher = appearance.scheduleShowTeacher.value;
      final color = CoursePalette.of(
        context,
        lesson.colorIndex,
        appearance.courseColorScheme.value,
      ).foreground;
      final time =
          '$prefix · ${formatClock(lesson.startMinute)}–${formatClock(lesson.endMinute)}';
      final details = [
        if (showName) time,
        if (location && lesson.location.isNotEmpty) lesson.location,
        if (teacher && lesson.teacher.isNotEmpty) lesson.teacher,
      ];
      return ListTile(
        contentPadding: EdgeInsets.zero,
        minLeadingWidth: 8,
        horizontalTitleGap: AppSpace.md,
        leading: Icon(AppIcons.statusDot, size: 8, color: color),
        titleTextStyle: Theme.of(context).textTheme.bodyMedium,
        subtitleTextStyle: Theme.of(context).textTheme.bodySmall,
        title: Text(
          showName ? lesson.courseName : time,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: details.isEmpty ? null : Text(details.join(' · ')),
        trailing: const Icon(AppIcons.chevronRight),
        onTap: () => showLessonSheet(context, lesson),
      );
    });
  }
}
