import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/utils/formatters.dart';
import 'package:qinghe_app/app/widgets/app_button.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';

/// 课程简要详情底部面板。完整的课程详情页实现前作为查看入口。
Future<void> showLessonSheet(BuildContext context, LessonOccurrence lesson) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (context) => _LessonSheet(lesson: lesson),
  );
}

class _LessonSheet extends StatelessWidget {
  const _LessonSheet({required this.lesson});

  final LessonOccurrence lesson;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final tone = CoursePalette.of(context, lesson.colorIndex);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Container(
                  width: 4,
                  height: 24,
                  decoration: BoxDecoration(
                    color: tone.foreground,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: Text(lesson.courseName, style: text.headlineSmall),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),
            _DetailRow(
              icon: Icons.schedule_rounded,
              label: '时间',
              value:
                  '${formatClock(lesson.startMinute)} – ${formatClock(lesson.endMinute)}',
            ),
            _DetailRow(
              icon: Icons.view_agenda_outlined,
              label: '节次',
              value: formatPeriods(lesson.startPeriod, lesson.endPeriod),
            ),
            if (lesson.location.isNotEmpty)
              _DetailRow(
                icon: Icons.place_outlined,
                label: '地点',
                value: lesson.location,
              ),
            if (lesson.teacher.isNotEmpty)
              _DetailRow(
                icon: Icons.person_outline_rounded,
                label: '教师',
                value: lesson.teacher,
              ),
            const SizedBox(height: AppSpace.xl),
            AppButton(
              label: '关闭',
              tone: AppButtonTone.secondary,
              expand: true,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
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
