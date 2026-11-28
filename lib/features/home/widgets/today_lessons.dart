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
    required this.focusLesson,
    required this.onOpen,
    this.colorScheme = CourseColorScheme.qinghe,
    this.saturation = 1,
    super.key,
  });

  final List<LessonOccurrence> lessons;
  final int minuteOfDay;
  final LessonOccurrence? focusLesson;
  final ValueChanged<LessonOccurrence> onOpen;
  final CourseColorScheme colorScheme;
  final double saturation;

  static const _timeWidth = 56.0;
  static const _trackWidth = 22.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (lessons.isEmpty)
          AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(AppIcons.sun, color: colors.accent),
                const SizedBox(height: AppSpace.sm),
                Text(
                  '课表今天请假啦，去做点喜欢的事吧。',
                  style: text.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          Stack(
            children: [
              if (lessons.length > 1)
                Positioned(
                  left: _timeWidth + (_trackWidth - 2) / 2,
                  top: AppSpace.xl,
                  bottom: AppSpace.xl,
                  width: 2,
                  child: ColoredBox(color: colors.line),
                ),
              Column(
                children: [
                  for (final (index, lesson) in lessons.indexed) ...[
                    if (index > 0) const SizedBox(height: AppSpace.md),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: _timeWidth,
                          child: Padding(
                            padding: const EdgeInsets.only(top: AppSpace.md),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                _TimelineTime(
                                  minute: lesson.startMinute,
                                  style: text.labelLarge,
                                ),
                                _TimelineTime(
                                  minute: lesson.endMinute,
                                  style: text.labelSmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          width: _trackWidth,
                          child: Padding(
                            padding: const EdgeInsets.only(top: AppSpace.lg),
                            child: Center(
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: CoursePalette.of(
                                    context,
                                    lesson.colorIndex,
                                    colorScheme,
                                    saturation,
                                  ).foreground,
                                  border: Border.all(
                                    color: colors.canvas,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: _LessonCard(
                            lesson: lesson,
                            minuteOfDay: minuteOfDay,
                            isFocus: lesson.id == focusLesson?.id,
                            tone: CoursePalette.of(
                              context,
                              lesson.colorIndex,
                              colorScheme,
                              saturation,
                            ),
                            onTap: () => onOpen(lesson),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ],
          ),
      ],
    );
  }
}

class _TimelineTime extends StatelessWidget {
  const _TimelineTime({required this.minute, required this.style});

  final int minute;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(
        formatClock(minute),
        style: style?.copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.minuteOfDay,
    required this.isFocus,
    required this.tone,
    required this.onTap,
  });

  final LessonOccurrence lesson;
  final int minuteOfDay;
  final bool isFocus;
  final CourseTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final status = lesson.statusAt(minuteOfDay);
    final ongoing = status == LessonStatus.ongoing;
    final statusLabel = switch (status) {
      LessonStatus.finished => '已结束',
      LessonStatus.ongoing => '进行中',
      LessonStatus.upcoming => isFocus ? '下一节' : '未开始',
    };
    final detail = [
      formatPeriods(lesson.startPeriod, lesson.endPeriod),
      if (lesson.location.trim().isNotEmpty) lesson.location.trim(),
    ].join(' · ');

    return Pressable(
      key: ValueKey('today-lesson-${lesson.id}'),
      color: tone.background,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    lesson.courseName,
                    style: text.titleMedium?.copyWith(color: tone.foreground),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Icon(AppIcons.chevronRight, color: tone.foreground, size: 16),
              ],
            ),
            const SizedBox(height: AppSpace.xs),
            Text(detail, style: text.bodySmall),
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppTag(
                  label: statusLabel,
                  tone: ongoing ? AppTagTone.accent : AppTagTone.neutral,
                ),
                if (ongoing || isFocus)
                  Text(
                    ongoing
                        ? '还有 ${formatDuration(lesson.endMinute - minuteOfDay)}下课'
                        : '${formatDuration(lesson.startMinute - minuteOfDay)}后开始',
                    style: text.labelSmall?.copyWith(
                      color: context.colors.inkMuted,
                    ),
                  ),
              ],
            ),
            if (ongoing) ...[
              const SizedBox(height: AppSpace.sm),
              LinearProgressIndicator(
                value: lesson.progressAt(minuteOfDay),
                color: tone.foreground,
                backgroundColor: tone.foreground.withValues(alpha: 0.18),
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
                semanticsLabel: '上课进度',
              ),
            ],
          ],
        ),
      ),
    );
  }
}
