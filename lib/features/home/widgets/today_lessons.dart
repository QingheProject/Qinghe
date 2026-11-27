import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/utils/formatters.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/app/widgets/app_tag.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';

class TodayLessons extends StatelessWidget {
  const TodayLessons({
    required this.lessons,
    required this.minuteOfDay,
    required this.onOpen,
    super.key,
  });

  final List<LessonOccurrence> lessons;
  final int minuteOfDay;
  final ValueChanged<LessonOccurrence> onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionHeader(title: '今日课程'),
        if (lessons.isEmpty)
          AppPanel(
            child: Row(
              children: [
                Icon(AppIcons.calendarCheck, color: colors.accent),
                const SizedBox(width: AppSpace.md),
                Expanded(child: Text('今天没有课', style: text.bodyMedium)),
              ],
            ),
          )
        else
          AppPanel(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (index, lesson) in lessons.indexed) ...[
                  if (index > 0)
                    const Divider(
                      height: 1,
                      indent: AppSpace.lg,
                      endIndent: AppSpace.lg,
                    ),
                  _LessonRow(
                    lesson: lesson,
                    status: lesson.statusAt(minuteOfDay),
                    onTap: () => onOpen(lesson),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _LessonRow extends StatelessWidget {
  const _LessonRow({
    required this.lesson,
    required this.status,
    required this.onTap,
  });

  final LessonOccurrence lesson;
  final LessonStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final ongoing = status == LessonStatus.ongoing;
    final statusLabel = switch (status) {
      LessonStatus.finished => '已结束',
      LessonStatus.ongoing => '进行中',
      LessonStatus.upcoming => '未开始',
    };
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: AppSpace.md,
        ),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatClock(lesson.startMinute),
                  style: text.labelLarge?.copyWith(
                    color: ongoing ? colors.accent : colors.ink,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(formatClock(lesson.endMinute), style: text.labelSmall),
              ],
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lesson.courseName, style: text.titleMedium),
                  const SizedBox(height: AppSpace.xs),
                  Wrap(
                    spacing: AppSpace.sm,
                    runSpacing: AppSpace.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AppTag(
                        label: statusLabel,
                        tone: ongoing ? AppTagTone.accent : AppTagTone.neutral,
                      ),
                      if (lesson.location.isNotEmpty)
                        Text(lesson.location, style: text.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.xs),
            Icon(AppIcons.chevronRight, color: colors.inkMuted, size: 16),
          ],
        ),
      ),
    );
  }
}
