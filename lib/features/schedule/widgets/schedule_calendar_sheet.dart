import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/app_sheet.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';
import 'package:qinghe_app/features/schedule/controllers/schedule_controller.dart';

const _weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

/// 日视图的日期抽屉：安静的整月日历，只有日期、今天与选中态，
/// 有课的日子用一个小圆点提示。点某一天直接跳到那天的日视图。
Future<void> showScheduleCalendarSheet({
  required BuildContext context,
  required ScheduleController controller,
}) {
  return showAppSheet<void>(
    context: context,
    builder: (_) => _ScheduleCalendarSheet(controller: controller),
  );
}

class _ScheduleCalendarSheet extends StatefulWidget {
  const _ScheduleCalendarSheet({required this.controller});

  final ScheduleController controller;

  @override
  State<_ScheduleCalendarSheet> createState() => _ScheduleCalendarSheetState();
}

class _ScheduleCalendarSheetState extends State<_ScheduleCalendarSheet> {
  late DateTime _month;

  ScheduleController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    final selected = _controller.displayedDate;
    _month = DateTime(selected.year, selected.month, 1);
  }

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta, 1);
    });
  }

  void _pick(DateTime date) {
    Navigator.of(context).pop();
    _controller.selectDay(date);
  }

  /// 从当月首周周一排到覆盖月末的那一周，始终是整周的倍数。
  List<DateTime> get _cells {
    final firstMonday = _month.subtract(
      Duration(days: _month.weekday - DateTime.monday),
    );
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final lastDay = DateTime(_month.year, _month.month, daysInMonth);
    final lastSunday = lastDay.add(
      Duration(days: DateTime.daysPerWeek - lastDay.weekday),
    );
    return [
      for (
        var date = firstMonday;
        !date.isAfter(lastSunday);
        date = date.add(const Duration(days: 1))
      )
        date,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final cells = _cells;
    final weekCount = cells.length ~/ DateTime.daysPerWeek;
    final selected = _controller.displayedDate;

    return AppSheet(
      key: const ValueKey('schedule-calendar-sheet'),
      title: '选择日期',
      maxHeightFactor: 0.76,
      actions: [
        AppSheetAction(
          label: '回到今天',
          onPressed: () => _pick(_controller.today),
        ),
      ],
      children: [
        Row(
          children: [
            _MonthArrow(
              key: const ValueKey('schedule-calendar-prev'),
              icon: AppIcons.arrowBack,
              semanticLabel: '上一个月',
              onTap: () => _shiftMonth(-1),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${_month.year}年${_month.month}月',
                  key: const ValueKey('schedule-calendar-month-label'),
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            _MonthArrow(
              key: const ValueKey('schedule-calendar-next'),
              icon: AppIcons.arrowForward,
              semanticLabel: '下一个月',
              onTap: () => _shiftMonth(1),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        Row(
          children: [
            for (final label in _weekdayLabels)
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    style: text.labelSmall?.copyWith(
                      color: colors.inkFaint,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        for (var week = 0; week < weekCount; week++)
          Row(
            children: [
              for (var column = 0; column < DateTime.daysPerWeek; column++)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final date = cells[week * DateTime.daysPerWeek + column];
                      return _CalendarDay(
                        key: ValueKey(
                          'schedule-calendar-day-'
                          '${date.year}${date.month}${date.day}',
                        ),
                        date: date,
                        inMonth: date.month == _month.month,
                        isToday: _sameDate(date, _controller.today),
                        isSelected: _sameDate(date, selected),
                        hasArrangement:
                            _controller.lessonsOn(date).isNotEmpty ||
                            _controller.examsOn(date).isNotEmpty,
                        onTap: () => _pick(date),
                      );
                    },
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

/// 日历里的一格：只有数字；选中是实心圆，今天用强调色，
/// 有安排的日子在下方留一个小点。
class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.date,
    required this.inMonth,
    required this.isToday,
    required this.isSelected,
    required this.hasArrangement,
    required this.onTap,
    super.key,
  });

  final DateTime date;
  final bool inMonth;
  final bool isToday;
  final bool isSelected;
  final bool hasArrangement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final Color foreground;
    if (isSelected) {
      foreground = colors.onAccent;
    } else if (!inMonth) {
      foreground = colors.inkFaint.withValues(alpha: 0.55);
    } else if (isToday) {
      foreground = colors.accent;
    } else {
      foreground = colors.ink;
    }

    return Semantics(
      button: true,
      selected: isSelected,
      label:
          '${date.month}月${date.day}日'
          '${isToday ? '，今天' : ''}'
          '${hasArrangement ? '，有安排' : ''}',
      child: ExcludeSemantics(
        child: Pressable(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: SizedBox(
            height: 46,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedContainer(
                  duration: AppMotion.of(context, AppMotion.fast),
                  curve: AppMotion.emphasized,
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: isSelected
                      ? BoxDecoration(
                          color: colors.accent,
                          shape: BoxShape.circle,
                        )
                      : null,
                  child: Text(
                    '${date.day}',
                    style: text.bodyMedium?.copyWith(
                      color: foreground,
                      fontWeight: isToday || isSelected
                          ? FontWeight.w600
                          : FontWeight.w400,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Container(
                  width: 3,
                  height: 3,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: !hasArrangement || !inMonth
                        ? Colors.transparent
                        : isSelected
                        ? colors.onAccent.withValues(alpha: 0.75)
                        : colors.inkFaint.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthArrow extends StatelessWidget {
  const _MonthArrow({
    required this.icon,
    required this.semanticLabel,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xs),
      semanticLabel: semanticLabel,
      splashColor: context.colors.ink.withValues(alpha: 0.06),
      child: SizedBox(
        width: 34,
        height: 34,
        child: Icon(icon, size: 17, color: context.colors.inkMuted),
      ),
    );
  }
}

bool _sameDate(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;
