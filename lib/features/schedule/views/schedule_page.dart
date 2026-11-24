import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/data/models/timetable_exam.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';
import 'package:qinghe_app/features/home/widgets/lesson_sheet.dart';
import 'package:qinghe_app/features/schedule/controllers/schedule_controller.dart';
import 'package:qinghe_app/features/schedule/widgets/exam_sheet.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_exam_card.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_lesson_card.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_period_label.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_settings_sheet.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_week_sheet.dart';

const _weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

class SchedulePage extends GetView<ScheduleController> {
  const SchedulePage({super.key});

  void _shiftWeek(VoidCallback action) {
    HapticFeedback.selectionClick();
    action();
  }

  /// 打开周次抽屉；没有课表时给出提示。
  Future<void> _openWeekSheet(ScheduleController controller) async {
    final context = Get.context;
    if (context == null) return;
    final slots = controller.weekSlots;
    if (slots == null) {
      showAppToast(context, '还没有课表，先导入课表后再切换周次。');
      return;
    }
    HapticFeedback.selectionClick();
    await showScheduleWeekSheet(
      context: context,
      weeks: slots,
      selectedWeek: controller.displayedTeachingWeek,
      currentWeek: controller.currentTeachingWeek,
      periodCount:
          controller.activeTimetable?.config.periodStartTimes.length ?? 12,
      onSelect: controller.goToTeachingWeek,
      onBackToCurrentWeek: controller.goToCurrentWeek,
    );
  }

  /// 切周时整张课表淡入淡出，不再左右平移。
  Widget _weekFadeTransition(Widget child, Animation<double> animation) {
    return FadeTransition(opacity: animation, child: child);
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
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Column(
              children: [
                const SizedBox(height: AppSpace.xs),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _ScheduleHeading(
                    title: controller.timetableName,
                    teachingWeek: controller.teachingWeek,
                    days: days,
                    isCurrentWeek: controller.isCurrentWeek,
                    onWeek: () => _openWeekSheet(controller),
                    onSettings: () => showScheduleSettingsSheet(context),
                    onToday: () => _shiftWeek(controller.goToCurrentWeek),
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                _WeekdayHeader(
                  days: days,
                  today: controller.today,
                  timeRailWidth: timeRailWidth,
                  examDays: {
                    for (final date in days)
                      if (controller.examsOn(date).isNotEmpty)
                        DateTime(date.year, date.month, date.day),
                  },
                ),
                const SizedBox(height: AppSpace.sm),
                Expanded(
                  child: SingleChildScrollView(
                    key: const ValueKey('schedule-grid-scroll'),
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.paddingOf(context).bottom + 96,
                    ),
                    child: ClipRect(
                      // 切换周次时课程淡入淡出，不做平移，避免整屏晃动。
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
                        transitionBuilder: _weekFadeTransition,
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
                            examsOn: controller.examsOn,
                            examSlot: (exam) =>
                                controller.activeTimetable?.examLayout(exam),
                            examColorIndex: (exam) =>
                                controller.activeTimetable?.examColorIndex(
                                  exam,
                                ) ??
                                0,
                            onOpenExam: (exam, origin) {
                              // 与课程卡一致：对话框从这张卡的底色与圆角长出来。
                              final table = controller.activeTimetable;
                              final tone = CoursePalette.of(
                                context,
                                table?.examColorIndex(exam) ?? 0,
                                appearance.courseColorScheme.value,
                                appearance.scheduleCourseSaturation.value,
                              );
                              showExamDialog(
                                context,
                                exam,
                                colorIndex: table?.examColorIndex(exam) ?? 0,
                                origin: origin,
                                originColor: tone.background.withValues(
                                  alpha: appearance.scheduleCardOpacity.value,
                                ),
                                originRadius:
                                    appearance.scheduleCardRadius.value,
                              );
                            },
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
    required this.title,
    required this.teachingWeek,
    required this.days,
    required this.isCurrentWeek,
    required this.onWeek,
    required this.onSettings,
    required this.onToday,
  });

  /// 课表名称，占用原来「课表」标题的位置。
  final String? title;
  final int? teachingWeek;
  final List<DateTime> days;
  final bool isCurrentWeek;
  final VoidCallback onWeek;
  final VoidCallback onSettings;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final name = (title ?? '').trim();
    final weekLabel = teachingWeek == null ? '学期外' : '第 $teachingWeek 周';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      name.isEmpty ? '我的课表' : name,
                      key: const ValueKey('schedule-heading'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleLarge,
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Text(
                    weekLabel,
                    key: const ValueKey('schedule-week-label'),
                    style: text.labelMedium?.copyWith(
                      color: colors.inkMuted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            ScheduleWeekButton(onTap: onWeek),
            const SizedBox(width: AppSpace.xs),
            Tooltip(
              message: '课表设置',
              child: Pressable(
                key: const ValueKey('schedule-settings-button'),
                onTap: onSettings,
                color: colors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.md),
                semanticLabel: '课表设置',
                splashColor: colors.ink.withValues(alpha: 0.08),
                child: SizedBox(
                  width: 34,
                  height: 34,
                  child: Icon(AppIcons.settings, size: 17, color: colors.ink),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: Text(
                _formatDateRange(days),
                key: const ValueKey('schedule-date-range'),
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
    required this.examDays,
  });

  final List<DateTime> days;
  final DateTime today;
  final double timeRailWidth;

  /// 当天有考试的日子，日期下方会带一个标记点。
  final Set<DateTime> examDays;

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
                hasExam: examDays.contains(
                  DateTime(
                    days[index].year,
                    days[index].month,
                    days[index].day,
                  ),
                ),
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
    required this.hasExam,
    required this.colors,
  });

  final String weekday;
  final DateTime date;
  final bool today;
  final bool weekend;
  final bool hasExam;
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
      label:
          '${date.month}月${date.day}日，星期$weekday'
          '${today ? '，今天' : ''}${hasExam ? '，有考试' : ''}',
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
                      ] else if (hasExam) ...[
                        const SizedBox(height: 2.5),
                        Container(
                          key: const ValueKey('schedule-exam-dot'),
                          width: 3.5,
                          height: 3.5,
                          decoration: BoxDecoration(
                            color: colors.accent,
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
    required this.examsOn,
    required this.examSlot,
    required this.examColorIndex,
    required this.onOpenExam,
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

  /// 当天的考试安排。
  final List<TimetableExam> Function(DateTime date) examsOn;

  /// 考试在课表里的位置：从网格顶部算起的行偏移与高度（单位：节）。
  final ({double top, double height})? Function(TimetableExam exam) examSlot;

  /// 考试卡片使用的配色下标。
  final int Function(TimetableExam exam) examColorIndex;
  final void Function(TimetableExam exam, Rect? origin) onOpenExam;
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
              for (var dayIndex = 0; dayIndex < days.length; dayIndex++)
                for (final exam in examsOn(days[dayIndex]))
                  if (examSlot(exam) case (top: final top, :final height))
                    Positioned(
                      left:
                          timeRailWidth +
                          dayIndex * dayWidth +
                          horizontalOffset,
                      top: top * rowHeight + verticalInset,
                      width: lessonWidth,
                      height: height * rowHeight - verticalInset * 2,
                      child: ScheduleExamCard(
                        exam: exam,
                        compact:
                            lessonWidth < 62 ||
                            height * rowHeight - verticalInset * 2 < 64,
                        colorIndex: examColorIndex(exam),
                        colorScheme: colorScheme,
                        saturation: saturation,
                        backgroundOpacity: cardOpacity,
                        cornerRadius: cardRadius,
                        showBorder: showBorder,
                        borderWidth: borderWidth,
                        showTopLine: showTopLine,
                        showLocation: showLocation,
                        textLayout: textLayout,
                        onTap: (origin) => onOpenExam(exam, origin),
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
