import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/routes/app_routes.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/utils/formatters.dart';
import 'package:qinghe_app/app/widgets/app_button.dart';
import 'package:qinghe_app/app/widgets/app_detail_dialog.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/data/models/timetable_rule.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:qinghe_app/features/course_edit/views/add_lesson_page.dart';

/// 课程详情对话框：系统默认的对话框过渡。
///
/// 只负责查看；编辑与删除都放在编辑页里，通过「编辑课程」进入。
Future<void> showLessonDialog(
  BuildContext context,
  LessonOccurrence lesson, {
  DateTime? date,
}) {
  return showDialog<void>(
    context: context,
    barrierLabel: '关闭课程详情',
    animationStyle: AppMotion.reduced(context)
        ? AnimationStyle.noAnimation
        : null,
    builder: (context) => _LessonDialog(lesson: lesson, date: date),
  );
}

class _LessonDialog extends StatefulWidget {
  const _LessonDialog({required this.lesson, this.date});

  final LessonOccurrence lesson;
  final DateTime? date;

  @override
  State<_LessonDialog> createState() => _LessonDialogState();
}

class _LessonDialogState extends State<_LessonDialog> {
  LessonOccurrence get _lesson => widget.lesson;

  LocalTimetableRepository? get _repository =>
      Get.isRegistered<LocalTimetableRepository>()
      ? Get.find<LocalTimetableRepository>()
      : null;

  TimetableRule? get _rule {
    if (_lesson.ruleId.isEmpty) return null;
    return _repository?.findRule(_lesson.ruleId);
  }

  /// 这次课落在第几教学周；没有日期时无法确定，不能单独删除。
  /// 这次课落在第几教学周，用于显示在标题下方。
  int? get _week {
    final date = widget.date;
    if (date == null) return null;
    return _repository?.active?.teachingWeekOn(date);
  }

  void _edit(TimetableRule rule) {
    Navigator.of(context).pop();
    Get.toNamed<Object?>(
      AppRoutes.addLesson,
      arguments: AddLessonArgs(
        weekday: rule.weekday,
        period: rule.startPeriod,
        rule: rule,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final appearance = Get.isRegistered<AppearanceController>()
        ? Get.find<AppearanceController>()
        : null;
    final tone = CoursePalette.of(
      context,
      _lesson.colorIndex,
      appearance?.courseColorScheme.value ?? CourseColorScheme.qinghe,
      appearance?.scheduleCourseSaturation.value ?? 1,
    );
    final rule = _rule;
    final week = _week;
    final date = widget.date;

    return AppDetailDialog(
      label: '课程详情',
      title: _lesson.courseName,
      subtitle: date != null
          ? '${date.month}月${date.day}日 · '
                '${weekdayLabel(date.weekday)}'
                '${week == null ? '' : ' · 第$week周'}'
          : null,
      markerColor: tone.foreground,
      children: [
        AppPanel(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.sm,
          ),
          child: Column(
            children: [
              AppDetailRow(
                icon: AppIcons.clock,
                label: '时间',
                value:
                    '${formatClock(_lesson.startMinute)} – '
                    '${formatClock(_lesson.endMinute)}',
              ),
              AppDetailRow(
                icon: AppIcons.rows,
                label: '节次',
                value: formatPeriods(_lesson.startPeriod, _lesson.endPeriod),
              ),
              if (_lesson.location.isNotEmpty)
                AppDetailRow(
                  icon: AppIcons.location,
                  label: '地点',
                  value: _lesson.location,
                ),
              if (_lesson.teacher.isNotEmpty)
                AppDetailRow(
                  icon: AppIcons.user,
                  label: '教师',
                  value: _lesson.teacher,
                ),
            ],
          ),
        ),
        if (rule != null) ...[
          const SizedBox(height: AppSpace.xl),
          AppButton(
            key: const ValueKey('lesson-sheet-edit'),
            icon: AppIcons.edit,
            label: '编辑课程',
            expand: true,
            onPressed: () => _edit(rule),
          ),
        ] else ...[
          const SizedBox(height: AppSpace.lg),
          Text(
            '在课表中导入或新建课程后可编辑信息。',
            textAlign: TextAlign.center,
            style: text.bodySmall,
          ),
        ],
      ],
    );
  }
}
