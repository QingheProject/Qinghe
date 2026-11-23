import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:qinghe_app/features/schedule/widgets/schedule_week_switcher.dart';

const _weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

class SchedulePage extends GetView<ScheduleController> {
  const SchedulePage({super.key});

  void _shiftWeek(VoidCallback action) {
    HapticFeedback.selectionClick();
    action();
  }

  /// 课表按切换方向左右滑入，离场的一侧同时反向滑出。
  Widget _weekSlideTransition(
    Widget child,
    Animation<double> animation,
    int direction,
  ) {
    final entering = animation.status != AnimationStatus.reverse;
    final begin = Offset((entering ? direction : -direction) * 0.07, 0);
    return SlideTransition(
      position: animation.drive(
        Tween(
          begin: begin,
          end: Offset.zero,
        ).chain(CurveTween(curve: AppMotion.emphasized)),
      ),
      child: FadeTransition(opacity: animation, child: child),
    );
  }

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
        final weekDirection = controller.weekDirection.value;
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
                    isCurrentWeek: controller.isCurrentWeek,
                    weekDirection: weekDirection,
                    onPrevious: () => _shiftWeek(controller.previousWeek),
                    onNext: () => _shiftWeek(controller.nextWeek),
                    onToday: () => _shiftWeek(controller.goToCurrentWeek),
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
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
                    child: ClipRect(
                      // 切换周次时整张课表按方向左右滑动进出，旧网格同时反向滑出。
                      child: AnimatedSwitcher(
                        duration: AppMotion.of(
                          context,
                          const Duration(milliseconds: 260),
                        ),
                        switchInCurve: AppMotion.emphasized,
                        switchOutCurve: AppMotion.emphasized,
                        layoutBuilder: (current, previous) => Stack(
                          alignment: Alignment.topCenter,
                          children: [
                            for (final child in previous) child,
                            if (current != null) current,
                          ],
                        ),
                        transitionBuilder: (child, animation) =>
                            _weekSlideTransition(
                              child,
                              animation,
                              weekDirection,
                            ),
                        child: KeyedSubtree(
                          key: ValueKey(controller.weekStart.value),
                          child: _WeekGrid(
                            key: const ValueKey('schedule-grid'),
                            days: days,
                            today: controller.today,
                            currentMinute: controller.currentMinute,
                            timeRailWidth: timeRailWidth,
                            rowHeight: appearance.scheduleRowHeight.value,
                            colorScheme: appearance.courseColorScheme.value,
                            saturation:
                                appearance.scheduleCourseSaturation.value,
                            cardWidthFactor: appearance.scheduleCardWidth.value,
                            cardInset: appearance.scheduleCardInset.value,
                            verticalInset:
                                appearance.scheduleVerticalInset.value,
                            cardOpacity: appearance.scheduleCardOpacity.value,
                            cardRadius: appearance.scheduleCardRadius.value,
                            showBorder: appearance.scheduleShowBorder.value,
                            borderWidth: appearance.scheduleBorderWidth.value,
                            showTopLine: appearance.scheduleShowTopLine.value,
                            showLocation: appearance.scheduleShowLocation.value,
                            showTeacher: appearance.scheduleShowTeacher.value,
                            textLayout: appearance.scheduleTextLayout.value,
                            showTime: appearance.scheduleShowTime.value,
                            timeAlignment:
                                appearance.scheduleTimeAlignment.value,
                            startTimes:
                                config?.periodStartTimes ??
                                appearance.scheduleStartTimes.toList(),
                            periodDuration:
                                config?.periodDurationMinutes ??
                                appearance.schedulePeriodDuration.value.round(),
                            railTextLayout: railTextLayout,
                            showCurrentTimeLine:
                                appearance.scheduleShowCurrentTimeLine.value,
                            showGridLines:
                                appearance.scheduleShowGridLines.value,
                            lessonsOn: controller.lessonsOn,
                            onOpen: (lesson, origin) {
                              // 对话框从这张卡片的底色与圆角长出来，再过渡到主题底色。
                              final tone = CoursePalette.of(
                                context,
                                lesson.colorIndex,
                                appearance.courseColorScheme.value,
                                appearance.scheduleCourseSaturation.value,
                              );
                              showLessonDialog(
                                context,
                                lesson,
                                origin: origin,
                                originColor: tone.background.withValues(
                                  alpha: appearance.scheduleCardOpacity.value,
                                ),
                                originRadius:
                                    appearance.scheduleCardRadius.value,
                              );
                            },
                          ),
                        ),
                      ),
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
  const _ScheduleHeading({
    required this.days,
    required this.teachingWeek,
    required this.isCurrentWeek,
    required this.weekDirection,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final List<DateTime> days;
  final int? teachingWeek;
  final bool isCurrentWeek;
  final int weekDirection;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              '课表',
              key: const ValueKey('schedule-heading'),
              style: text.titleLarge,
            ),
            const Spacer(),
            ScheduleWeekSwitcher(
              teachingWeek: teachingWeek,
              direction: weekDirection,
              onPrevious: onPrevious,
              onNext: onNext,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _formatDateRange(days),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall,
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            ScheduleTodayButton(visible: !isCurrentWeek, onTap: onToday),
          ],
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
      height: 42,
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final foreground = today
        ? colors.onAccent
        : weekend
        ? colors.inkFaint
        : colors.inkMuted;

    return Semantics(
      label: '${date.month}月${date.day}日，星期$weekday${today ? '，今天' : ''}',
      child: ExcludeSemantics(
        child: Center(
          child: AspectRatio(
            aspectRatio: 1,
            child: AnimatedContainer(
              key: today ? const ValueKey('schedule-today-header') : null,
              duration: AppMotion.of(context, AppMotion.fast),
              curve: AppMotion.emphasized,
              decoration: BoxDecoration(
                // 选中日期只做轻微透明底色，不加投影，避免在顶栏上显得沉重。
                color: today
                    ? colors.accent.withValues(alpha: dark ? 0.72 : 0.88)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        weekday,
                        style: text.labelSmall?.copyWith(
                          color: today
                              ? foreground.withValues(alpha: 0.82)
                              : foreground,
                          height: 1,
                        ),
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
                      if (today) ...[
                        const SizedBox(height: 2.5),
                        Container(
                          width: 3.5,
                          height: 3.5,
                          decoration: BoxDecoration(
                            color: foreground.withValues(alpha: 0.9),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
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
  final void Function(LessonOccurrence lesson, Rect? origin) onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final periodCount = startTimes.length;
    final gridHeight = rowHeight * periodCount;
    final todayIndex = days.indexWhere((date) => _sameDate(date, today));
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
              if (todayIndex >= 0)
                Positioned(
                  left: timeRailWidth + todayIndex * dayWidth + 1,
                  top: 0,
                  bottom: 0,
                  width: dayWidth - 2,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      key: const ValueKey('schedule-today-column'),
                      decoration: BoxDecoration(
                        color: colors.accentSoft.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                    ),
                  ),
                ),
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
                      onTap: (origin) => onOpen(lesson, origin),
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
