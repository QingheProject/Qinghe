import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/utils/formatters.dart';
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
    builder: (context) => _ExamDialog(
      exam: exam,
      colorIndex: colorIndex,
      onClose: () => Navigator.of(context).pop(),
    ),
  );
}

class _ExamDialog extends StatelessWidget {
  const _ExamDialog({
    required this.exam,
    required this.colorIndex,
    required this.onClose,
  });

  final TimetableExam exam;
  final int colorIndex;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final appearance = Get.isRegistered<AppearanceController>()
        ? Get.find<AppearanceController>()
        : null;
    final tone = CoursePalette.of(
      context,
      colorIndex,
      appearance?.courseColorScheme.value ?? CourseColorScheme.qinghe,
      appearance?.scheduleCourseSaturation.value ?? 1,
    );

    final colors = context.colors;

    return Semantics(
      container: true,
      label: '考试详情',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Material(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 4,
                          height: 26,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            color: tone.foreground,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exam.courseName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: text.headlineSmall,
                              ),
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Text(
                                  '考试 · ${exam.date.month}月${exam.date.day}日 · '
                                  '${weekdayLabel(exam.date.weekday)}',
                                  style: text.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: onClose,
                          tooltip: '关闭',
                          icon: const Icon(AppIcons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpace.lg),
                    AppPanel(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.lg,
                        vertical: AppSpace.sm,
                      ),
                      child: Column(
                        children: [
                          _DetailRow(
                            icon: AppIcons.clock,
                            label: '时间',
                            value: exam.timeLabel.isEmpty
                                ? '待定'
                                : exam.timeLabel,
                          ),
                          if (exam.location.isNotEmpty)
                            _DetailRow(
                              icon: AppIcons.location,
                              label: '考场',
                              value: exam.location,
                            ),
                          if (exam.seat.isNotEmpty)
                            _DetailRow(
                              icon: AppIcons.rows,
                              label: '座位',
                              value: exam.seat,
                            ),
                          if (exam.note.isNotEmpty)
                            _DetailRow(
                              icon: AppIcons.info,
                              label: '方式',
                              value: exam.note,
                            ),
                          if (exam.sourceNote.isNotEmpty)
                            _DetailRow(
                              icon: AppIcons.calendarCheck,
                              label: '来源',
                              value: exam.sourceNote,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.inkFaint),
          const SizedBox(width: AppSpace.md),
          SizedBox(width: 44, child: Text(label, style: text.labelMedium)),
          Expanded(child: Text(value, style: text.bodyMedium)),
        ],
      ),
    );
  }
}
