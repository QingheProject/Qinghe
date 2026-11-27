import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/utils/formatters.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';

class WeekActivityChart extends StatelessWidget {
  const WeekActivityChart({
    required this.activity,
    required this.today,
    super.key,
  });

  final List<({DateTime date, int count})> activity;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final total = activity.fold(0, (sum, day) => sum + day.count);
    final peak = activity.fold(1, (peak, day) => math.max(peak, day.count));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSectionHeader(title: '课程活跃'),
        AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('本周上课次数', style: text.labelMedium),
              const SizedBox(height: AppSpace.xs),
              Text('共 $total 次课', style: text.titleLarge),
              const SizedBox(height: AppSpace.lg),
              Row(
                children: [
                  for (final day in activity)
                    Expanded(
                      child: _ActivityBar(
                        date: day.date,
                        count: day.count,
                        fraction: day.count / peak,
                        isToday: DateUtils.isSameDay(day.date, today),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityBar extends StatelessWidget {
  const _ActivityBar({
    required this.date,
    required this.count,
    required this.fraction,
    required this.isToday,
  });

  final DateTime date;
  final int count;
  final double fraction;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final weekday = weekdayLabel(date.weekday);
    final description = '${isToday ? '今天，' : ''}$weekday，$count 次课';
    final foreground = isToday ? colors.accent : colors.inkMuted;
    final radius = BorderRadius.circular(AppRadius.xs);
    return Semantics(
      container: true,
      label: description,
      child: ExcludeSemantics(
        child: Tooltip(
          message: '${date.month}月${date.day}日 · $description',
          child: Column(
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '$count',
                  style: text.labelMedium?.copyWith(color: foreground),
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Container(
                height: 56,
                width: 14,
                decoration: BoxDecoration(
                  color: colors.surfaceMuted,
                  borderRadius: radius,
                ),
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: fraction,
                  widthFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: isToday
                          ? colors.accent
                          : Color.lerp(colors.accentSoft, colors.accent, 0.6),
                      borderRadius: radius,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.xs),
              Text(
                weekday.substring(2),
                style: text.labelSmall?.copyWith(color: foreground),
              ),
              const SizedBox(height: AppSpace.xs),
              SizedBox.square(
                dimension: 4,
                child: isToday
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          color: foreground,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
