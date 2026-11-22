import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/features/home/widgets/lesson_sheet.dart';
import 'package:qinghe_app/features/schedule/controllers/schedule_controller.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_lesson_card.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_period_label.dart';

const _weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

class SchedulePage extends GetView<ScheduleController> {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    final appearance = Get.find<AppearanceController>();
    return SafeArea(
      bottom: false,
      child: Obx(() {
        final config = controller.activeTimetable?.config;
        final allDays = controller.days;
        final days = appearance.scheduleShowWeekend.value
            ? allDays
            : allDays.take(DateTime.friday).toList(growable: false);
        final railTextLayout = appearance.scheduleRailTextLayout.value;
        final timeRailWidth = SchedulePeriodLabel.railWidthFor(
          showTime: appearance.scheduleShowTime.value,
          textLayout: railTextLayout,
        );
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              children: [
                const SizedBox(height: AppSpace.xs),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _ScheduleHeading(
                    days: days,
                    teachingWeek: controller.teachingWeek,
                  ),
                ),
                const SizedBox(height: AppSpace.xs),
                _WeekdayHeader(
                  days: days,
                  today: controller.today,
                  timeRailWidth: timeRailWidth,
                ),
                const SizedBox(height: AppSpace.sm),
                Expanded(
                  child: SingleChildScrollView(
                    key: const ValueKey('schedule-grid-scroll'),
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.paddingOf(context).bottom + 96,
                    ),
                    child: _WeekGrid(
                      key: const ValueKey('schedule-grid'),
                      days: days,
                      today: controller.today,
                      currentMinute: controller.currentMinute,
                      timeRailWidth: timeRailWidth,
                      rowHeight: appearance.scheduleRowHeight.value,
                      colorScheme: appearance.courseColorScheme.value,
                      saturation: appearance.scheduleCourseSaturation.value,
                      cardWidthFactor: appearance.scheduleCardWidth.value,
                      cardInset: appearance.scheduleCardInset.value,
                      verticalInset: appearance.scheduleVerticalInset.value,
                      cardOpacity: appearance.scheduleCardOpacity.value,
                      cardRadius: appearance.scheduleCardRadius.value,
                      showBorder: appearance.scheduleShowBorder.value,
                      borderWidth: appearance.scheduleBorderWidth.value,
                      showTopLine: appearance.scheduleShowTopLine.value,
                      showLocation: appearance.scheduleShowLocation.value,
                      showTeacher: appearance.scheduleShowTeacher.value,
                      textLayout: appearance.scheduleTextLayout.value,
                      showTime: appearance.scheduleShowTime.value,
                      timeAlignment: appearance.scheduleTimeAlignment.value,
                      startTimes:
                          config?.periodStartTimes ??
                          appearance.scheduleStartTimes.toList(),
                      periodDuration:
                          config?.periodDurationMinutes ??
                          appearance.schedulePeriodDuration.value.round(),
                      railTextLayout: railTextLayout,
                      showCurrentTimeLine:
                          appearance.scheduleShowCurrentTimeLine.value,
                      showGridLines: appearance.scheduleShowGridLines.value,
                      lessonsOn: controller.lessonsOn,
                      onOpen: (lesson) => showLessonSheet(context, lesson),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class _ScheduleHeading extends StatelessWidget {
  const _ScheduleHeading({required this.days, required this.teachingWeek});

  final List<DateTime> days;
  final int? teachingWeek;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final weekLabel = teachingWeek == null ? '学期外' : '第 $teachingWeek 周';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '课表',
          key: const ValueKey('schedule-heading'),
          style: text.titleLarge,
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: Text(
            '$weekLabel · ${_formatDateRange(days)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({
    required this.days,
    required this.today,
    required this.timeRailWidth,
  });

  final List<DateTime> days;
  final DateTime today;
  final double timeRailWidth;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    return SizedBox(
      height: 36,
      child: Row(
        children: [
          SizedBox(
            width: timeRailWidth,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('节', style: text.labelSmall),
              ),
            ),
          ),
          for (var index = 0; index < days.length; index++)
            Expanded(
              child: _DayLabel(
                weekday: _weekdayLabels[days[index].weekday - 1],
                date: days[index],
                today: _sameDate(days[index], today),
                weekend: days[index].weekday >= DateTime.saturday,
                colors: colors,
              ),
            ),
        ],
      ),
    );
  }
}

class _DayLabel extends StatelessWidget {
  const _DayLabel({
    required this.weekday,
    required this.date,
    required this.today,
    required this.weekend,
    required this.colors,
  });

  final String weekday;
  final DateTime date;
  final bool today;
  final bool weekend;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final foreground = today
        ? colors.accent
        : weekend
        ? colors.inkFaint
        : colors.inkMuted;

    return Semantics(
      label: '${date.month}月${date.day}日，星期$weekday${today ? '，今天' : ''}',
      child: ExcludeSemantics(
        child: AnimatedContainer(
          key: today ? const ValueKey('schedule-today-header') : null,
          duration: AppMotion.of(context, AppMotion.fast),
          width: 32,
          height: 34,
          decoration: BoxDecoration(
            color: today ? colors.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                weekday,
                style: text.labelSmall?.copyWith(color: foreground, height: 1),
              ),
              const SizedBox(height: 2),
              Text(
                '${date.day}',
                style: text.labelMedium?.copyWith(
                  color: foreground,
                  height: 1,
                  fontWeight: today ? FontWeight.w700 : FontWeight.w500,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeekGrid extends StatelessWidget {
  const _WeekGrid({
    required this.days,
    required this.today,
    required this.currentMinute,
    required this.timeRailWidth,
    required this.rowHeight,
    required this.colorScheme,
    required this.saturation,
    required this.cardWidthFactor,
    required this.cardInset,
    required this.verticalInset,
    required this.cardOpacity,
    required this.cardRadius,
    required this.showBorder,
    required this.borderWidth,
    required this.showTopLine,
    required this.showLocation,
    required this.showTeacher,
    required this.textLayout,
    required this.showTime,
    required this.timeAlignment,
    required this.startTimes,
    required this.periodDuration,
    required this.railTextLayout,
    required this.showCurrentTimeLine,
    required this.showGridLines,
    required this.lessonsOn,
    required this.onOpen,
    super.key,
  });

  final List<DateTime> days;
  final DateTime today;
  final int currentMinute;
  final double timeRailWidth;
  final double rowHeight;
  final CourseColorScheme colorScheme;
  final double saturation;
  final double cardWidthFactor;
  final double cardInset;
  final double verticalInset;
  final double cardOpacity;
  final double cardRadius;
  final bool showBorder;
  final double borderWidth;
  final bool showTopLine;
  final bool showLocation;
  final bool showTeacher;
  final ScheduleTextLayout textLayout;
  final bool showTime;
  final ScheduleTimeAlignment timeAlignment;
  final List<String> startTimes;
  final int periodDuration;
  final ScheduleRailTextLayout railTextLayout;
  final bool showCurrentTimeLine;
  final bool showGridLines;
  final List<LessonOccurrence> Function(DateTime date) lessonsOn;
  final ValueChanged<LessonOccurrence> onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final periodCount = startTimes.length;
    final gridHeight = rowHeight * periodCount;
    final currentTimeOffset = showCurrentTimeLine && _containsToday(days, today)
        ? _timeOffset(currentMinute, rowHeight, startTimes, periodDuration)
        : null;

    return Container(
      height: gridHeight,
      decoration: BoxDecoration(
        color: colors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dayWidth = (constraints.maxWidth - timeRailWidth) / days.length;
          final availableCardWidth = dayWidth - cardInset * 2;
          final lessonWidth = availableCardWidth * cardWidthFactor;
          final horizontalOffset =
              cardInset + (availableCardWidth - lessonWidth) / 2;

          return Stack(
            children: [
              if (showGridLines)
                for (var row = 1; row < periodCount; row++)
                  Positioned(
                    left: timeRailWidth,
                    right: 0,
                    top: row * rowHeight,
                    child: Container(
                      height: row == 4 || row == 8 ? 1.5 : 1,
                      color: colors.line.withValues(
                        alpha: row == 4 || row == 8 ? 0.82 : 0.48,
                      ),
                    ),
                  ),
              for (var row = 0; row < periodCount; row++)
                Positioned(
                  left: 0,
                  top: row * rowHeight,
                  width: timeRailWidth,
                  height: rowHeight,
                  child: SchedulePeriodLabel(
                    period: row + 1,
                    showTime: showTime,
                    startTime: startTimes[row],
                    endTime: calculateScheduleEndTime(
                      startTimes[row],
                      periodDuration,
                    ),
                    alignment: timeAlignment,
                    textLayout: railTextLayout,
                  ),
                ),
              for (var dayIndex = 0; dayIndex < days.length; dayIndex++)
                for (final (lesson, lane, laneCount) in _layoutDay(
                  lessonsOn(days[dayIndex]),
                ))
                  Positioned(
                    left:
                        timeRailWidth +
                        dayIndex * dayWidth +
                        horizontalOffset +
                        lane * lessonWidth / laneCount,
                    top: (lesson.startPeriod - 1) * rowHeight + verticalInset,
                    width: lessonWidth / laneCount,
                    height:
                        (lesson.endPeriod - lesson.startPeriod + 1) *
                            rowHeight -
                        verticalInset * 2,
                    child: ScheduleLessonCard(
                      lesson: lesson,
                      date: days[dayIndex],
                      compact: lessonWidth / laneCount < 62,
                      colorScheme: colorScheme,
                      saturation: saturation,
                      backgroundOpacity: cardOpacity,
                      cornerRadius: cardRadius,
                      showBorder: showBorder,
                      borderWidth: borderWidth,
                      showTopLine: showTopLine,
                      showLocation: showLocation,
                      showTeacher: showTeacher,
                      textLayout: textLayout,
                      onTap: () => onOpen(lesson),
                    ),
                  ),
              if (currentTimeOffset != null) ...[
                Positioned(
                  left: timeRailWidth,
                  right: 0,
                  top: currentTimeOffset,
                  child: Semantics(
                    label: '当前时间位置',
                    child: Container(
                      key: const ValueKey('schedule-current-time-line'),
                      height: 1.5,
                      color: colors.accent.withValues(alpha: 0.82),
                    ),
                  ),
                ),
                Positioned(
                  left: timeRailWidth - 3,
                  top: currentTimeOffset - 2.25,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
              if (_containsToday(days, today))
                Positioned(
                  left:
                      timeRailWidth +
                      days.indexWhere((date) => _sameDate(date, today)) *
                          dayWidth +
                      dayWidth / 2 -
                      2,
                  top: 5,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// 同一天时间重叠的课程并排展示，避免后绘制的课程盖住前一门。
Iterable<(LessonOccurrence, int, int)> _layoutDay(
  List<LessonOccurrence> lessons,
) sync* {
  final ordered = lessons.toList()
    ..sort((left, right) => left.startPeriod.compareTo(right.startPeriod));
  final group = <(LessonOccurrence, int)>[];
  final laneEnds = <int>[];
  var groupEnd = 0;
  for (final lesson in ordered) {
    if (lesson.startPeriod > groupEnd && group.isNotEmpty) {
      for (final (course, lane) in group) {
        yield (course, lane, laneEnds.length);
      }
      group.clear();
      laneEnds.clear();
    }
    final lane = laneEnds.indexWhere((end) => end < lesson.startPeriod);
    if (lane == -1) {
      group.add((lesson, laneEnds.length));
      laneEnds.add(lesson.endPeriod);
    } else {
      group.add((lesson, lane));
      laneEnds[lane] = lesson.endPeriod;
    }
    if (lesson.endPeriod > groupEnd) groupEnd = lesson.endPeriod;
  }
  for (final (course, lane) in group) {
    yield (course, lane, laneEnds.length);
  }
}

double? _timeOffset(
  int minute,
  double rowHeight,
  List<String> startTimes,
  int periodDuration,
) {
  final starts = startTimes.map(_minuteOfDay).toList(growable: false);
  final lastEnd = starts.last + periodDuration;
  if (minute < starts.first || minute > lastEnd) return null;
  for (var index = 0; index < starts.length; index++) {
    final start = starts[index];
    final end = start + periodDuration;
    if (minute <= end) {
      final progress = ((minute - start) / (end - start)).clamp(0.0, 1.0);
      return (index + progress) * rowHeight;
    }
    if (index < starts.length - 1 && minute < starts[index + 1]) {
      return (index + 1) * rowHeight;
    }
  }
  return null;
}

int _minuteOfDay(String value) {
  final parts = value.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

String _formatDateRange(List<DateTime> days) {
  final first = days.first;
  final last = days.last;
  if (first.year == last.year && first.month == last.month) {
    return '${first.month}月${first.day}日—${last.day}日';
  }
  return '${first.month}月${first.day}日—${last.month}月${last.day}日';
}

bool _sameDate(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

bool _containsToday(List<DateTime> days, DateTime today) =>
    days.any((date) => _sameDate(date, today));
