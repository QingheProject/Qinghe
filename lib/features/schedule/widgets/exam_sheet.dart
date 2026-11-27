import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/utils/formatters.dart';
import 'package:qinghe_app/app/widgets/app_detail_dialog.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/data/models/timetable_exam.dart';

/// 打开考试详情，使用系统默认的对话框过渡。
///
/// 结构与课程详情一致：左侧色条 + 标题 + 日期，下面是同一套信息行。
Future<void> showExamDialog(
  BuildContext context,
  TimetableExam exam, {
  int colorIndex = 0,
}) {
  return showDialog<void>(
    context: context,
    barrierLabel: '关闭考试详情',
    animationStyle: AppMotion.reduced(context)
        ? AnimationStyle.noAnimation
        : null,
    builder: (context) => _ExamDialog(exam: exam, colorIndex: colorIndex),
  );
}

class _ExamDialog extends StatelessWidget {
  const _ExamDialog({required this.exam, required this.colorIndex});

  final TimetableExam exam;
  final int colorIndex;

  @override
  Widget build(BuildContext context) {
    final appearance = Get.isRegistered<AppearanceController>()
        ? Get.find<AppearanceController>()
        : null;
    final tone = CoursePalette.of(
      context,
      colorIndex,
      appearance?.courseColorScheme.value ?? CourseColorScheme.qinghe,
      appearance?.scheduleCourseSaturation.value ?? 1,
    );

    return AppDetailDialog(
      label: '考试详情',
      title: exam.courseName,
      subtitle:
          '考试 · ${exam.date.month}月${exam.date.day}日 · '
          '${weekdayLabel(exam.date.weekday)}',
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
                value: exam.timeLabel.isEmpty ? '待定' : exam.timeLabel,
              ),
              if (exam.location.isNotEmpty)
                AppDetailRow(
                  icon: AppIcons.location,
                  label: '考场',
                  value: exam.location,
                ),
              if (exam.seat.isNotEmpty)
                AppDetailRow(
                  icon: AppIcons.rows,
                  label: '座位',
                  value: exam.seat,
                ),
              if (exam.note.isNotEmpty)
                AppDetailRow(
                  icon: AppIcons.info,
                  label: '方式',
                  value: exam.note,
                ),
              if (exam.sourceNote.isNotEmpty)
                AppDetailRow(
                  icon: AppIcons.calendarCheck,
                  label: '来源',
                  value: exam.sourceNote,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
