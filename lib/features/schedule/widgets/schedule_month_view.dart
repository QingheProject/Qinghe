import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';
import 'package:qinghe_app/features/schedule/controllers/schedule_controller.dart';

const _weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

/// 月视图：整月日历，格子里用课程色点标记当天有课，考试用空心圈标记。
/// 点某一天跳到日视图查看当天安排。
class ScheduleMonthView extends StatelessWidget {
  const ScheduleMonthView({
    required this.controller,
    required this.colorScheme,
    required this.saturation,
    super.key,
  });

  final ScheduleController controller;
  final CourseColorScheme colorScheme;
  final double saturation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final month = controller.displayedMonth;
    final cells = controller.monthCells;
    final weeks = cells.length ~/ 7;

    return Column(
      key: const ValueKey('schedule-month-view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _MonthArrow(
              icon: Icons.chevron_left,
              semanticLabel: '上一个月',
              onTap: controller.previousMonth,
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${month.year}年${month.month}月',
                  key: const ValueKey('schedule-month-label'),
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            _MonthArrow(
              icon: Icons.chevron_right,
              semanticLabel: '下一个月',
              onTap: controller.nextMonth,
            ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        Row(
          children: [
            for (final label in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: text.labelSmall?.copyWith(color: colors.inkMuted),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.xs),
        for (var week = 0; week < weeks; week++)
          Row(
            children: [
              for (var column = 0; column < 7; column++)
                Expanded(
                  child: _MonthCell(
                    date: cells[week * 7 + column],
                    controller: controller,
                    colorScheme: colorScheme,
                    saturation: saturation,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      tooltip: semanticLabel,
      icon: Icon(icon, size: 20, color: context.colors.ink),
    );
  }
}

class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.date,
    required this.controller,
    required this.colorScheme,
    required this.saturation,
  });

  final DateTime date;
  final ScheduleController controller;
  final CourseColorScheme colorScheme;
  final double saturation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final inMonth = date.month == controller.displayedMonth.month;
    final lessons = controller.lessonsOn(date);
    final exams = controller.examsOn(date);
    final isToday = _sameDate(date, controller.today);

    return Pressable(
      key: ValueKey('schedule-month-cell-${date.year}${date.month}${date.day}'),
      onTap: () => controller.selectDay(date),
      borderRadius: BorderRadius.circular(AppRadius.sm),
      semanticLabel:
          '${date.month}月${date.day}日'
          '${isToday ? '，今天' : ''}'
          '${lessons.isNotEmpty ? '，${lessons.length} 节课' : ''}'
          '${exams.isNotEmpty ? '，${exams.length} 场考试' : ''}',
      child: SizedBox(
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: isToday
                  ? BoxDecoration(color: colors.accent, shape: BoxShape.circle)
                  : null,
              alignment: Alignment.center,
              child: Text(
                '${date.day}',
                style: text.bodyMedium?.copyWith(
                  color: !inMonth
                      ? colors.inkFaint
                      : isToday
                      ? colors.onAccent
                      : colors.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            const SizedBox(height: 2),
            SizedBox(
              height: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (inMonth)
                    for (final lesson in lessons.take(3))
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: CoursePalette.of(
                            context,
                            lesson.colorIndex,
                            colorScheme,
                            saturation,
                          ).background,
                          shape: BoxShape.circle,
                        ),
                      ),
                  if (inMonth && exams.isNotEmpty)
                    Container(
                      width: 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.accent, width: 1.5),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static bool _sameDate(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
