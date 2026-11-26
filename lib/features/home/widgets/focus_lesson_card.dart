import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/utils/formatters.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';

/// 首页主卡：正在上的课显示进度，否则显示下一节的倒计时；
/// 课程切换时卡片内容交叉淡入。
class FocusLessonCard extends StatelessWidget {
  const FocusLessonCard({
    required this.lesson,
    required this.minuteOfDay,
    required this.hasLessonsToday,
    required this.onOpen,
    super.key,
  });

  final LessonOccurrence? lesson;
  final int minuteOfDay;
  final bool hasLessonsToday;
  final ValueChanged<LessonOccurrence> onOpen;

  @override
  Widget build(BuildContext context) {
    final current = lesson;
    return AnimatedSwitcher(
      duration: AppMotion.of(context, AppMotion.slow),
      switchInCurve: AppMotion.emphasized,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: animation.drive(Tween(begin: 0.97, end: 1)),
          child: child,
        ),
      ),
      child: current == null
          ? _RestCard(
              key: ValueKey('rest-$hasLessonsToday'),
              done: hasLessonsToday,
            )
          : _LessonCard(
              key: ValueKey(current.id),
              lesson: current,
              minuteOfDay: minuteOfDay,
              onTap: () => onOpen(current),
            ),
    );
  }
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.minuteOfDay,
    required this.onTap,
    super.key,
  });

  final LessonOccurrence lesson;
  final int minuteOfDay;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final ongoing = lesson.statusAt(minuteOfDay) == LessonStatus.ongoing;
    final onAccent = colors.onAccent;
    final soft = onAccent.withValues(alpha: 0.78);

    return Pressable(
      onTap: onTap,
      color: colors.accent,
      splashColor: onAccent.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      semanticLabel: '${ongoing ? '正在上课' : '下一节'}：${lesson.courseName}',
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          children: [
            Positioned(
              right: -4,
              bottom: -36,
              child: ExcludeSemantics(
                child: Text(
                  '${lesson.startPeriod}',
                  style: TextStyle(
                    fontSize: 156,
                    fontWeight: FontWeight.w800,
                    height: 1,
                    color: onAccent.withValues(alpha: 0.1),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _GlassTag(label: ongoing ? '进行中' : '下一节'),
                      const Spacer(),
                      Text(
                        formatPeriods(lesson.startPeriod, lesson.endPeriod),
                        style: text.labelMedium?.copyWith(color: soft),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    lesson.courseName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.headlineSmall?.copyWith(color: onAccent),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Wrap(
                    spacing: 14,
                    runSpacing: 6,
                    children: [
                      _IconText(
                        icon: AppIcons.clock,
                        label:
                            '${formatClock(lesson.startMinute)} – ${formatClock(lesson.endMinute)}',
                        color: soft,
                      ),
                      if (lesson.location.isNotEmpty)
                        _IconText(
                          icon: AppIcons.location,
                          label: lesson.location,
                          color: soft,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.xl),
                  if (ongoing)
                    _Progress(
                      value: lesson.progressAt(minuteOfDay),
                      remaining: lesson.endMinute - minuteOfDay,
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          formatDuration(lesson.startMinute - minuteOfDay),
                          style: text.headlineSmall?.copyWith(
                            color: onAccent,
                            fontSize: 26,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '后开始',
                          style: text.labelMedium?.copyWith(color: soft),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.value, required this.remaining});

  final double value;
  final int remaining;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final onAccent = colors.onAccent;

    return Column(
      children: [
        Row(
          children: [
            Text(
              '还剩 ${formatDuration(remaining)}',
              style: text.labelLarge?.copyWith(color: onAccent),
            ),
            const Spacer(),
            Text(
              '${(value * 100).round()}%',
              style: text.labelMedium?.copyWith(
                color: onAccent.withValues(alpha: 0.78),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value),
          duration: AppMotion.of(context, AppMotion.slow),
          curve: AppMotion.emphasized,
          builder: (context, v, _) => Container(
            height: 4,
            decoration: BoxDecoration(
              color: onAccent.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: v,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: onAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _GlassTag extends StatelessWidget {
  const _GlassTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final onAccent = context.colors.onAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: onAccent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: onAccent),
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: color),
        ),
      ],
    );
  }
}

class _RestCard extends StatelessWidget {
  const _RestCard({required this.done, super.key});

  final bool done;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpace.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colors.accentSoft,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              done ? AppIcons.check : AppIcons.sun,
              color: colors.accent,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(done ? '今天的课都上完了' : '今天没有课', style: text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  done ? '辛苦了，记得看看明天的安排。' : '好好休息，也可以去课表看看本周安排。',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
