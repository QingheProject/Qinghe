import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/routes/app_routes.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:qinghe_app/data/models/timetable_exam.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';
import 'package:qinghe_app/features/course_edit/views/add_lesson_page.dart';
import 'package:qinghe_app/features/home/widgets/lesson_sheet.dart';
import 'package:qinghe_app/features/schedule/controllers/schedule_controller.dart';
import 'package:qinghe_app/features/schedule/widgets/exam_sheet.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_day_view.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_exam_card.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_lesson_card.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_period_label.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_month_view.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_settings_sheet.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_view_switcher.dart';
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

  /// 「回到本周」按当前视图回位：日回今天、周回本周、月回本月。
  VoidCallback _onToday(ScheduleController controller) {
    return () {
      switch (controller.viewMode.value) {
        case ScheduleViewMode.day:
          _shiftWeek(controller.goToToday);
        case ScheduleViewMode.week:
          _shiftWeek(controller.goToCurrentWeek);
        case ScheduleViewMode.month:
          _shiftWeek(controller.goToCurrentMonth);
      }
    };
  }

  /// 点课表空白格：先放一个加号占位，已经占位的格子则清掉。
  void _handleSlotTap(
    ScheduleController controller,
    List<DateTime> days,
    int dayIndex,
    int period,
  ) {
    if (dayIndex < 0 || dayIndex >= days.length) return;
    final taken = controller
        .lessonsOn(days[dayIndex])
        .any(
          (lesson) =>
              period >= lesson.startPeriod && period <= lesson.endPeriod,
        );
    if (taken) {
      controller.clearGhost();
      return;
    }
    HapticFeedback.selectionClick();
    controller.selectGhost(dayIndex, period);
  }

  /// 再点一下占位格，进入添加课程页。
  Future<void> _openAddLesson(
    ScheduleController controller,
    List<DateTime> days,
  ) async {
    final ghost = controller.ghostSlot.value;
    if (ghost == null || ghost.dayIndex >= days.length) return;
    final date = days[ghost.dayIndex];
    HapticFeedback.selectionClick();
    final result = await Get.toNamed<Object?>(
      AppRoutes.addLesson,
      arguments: AddLessonArgs(weekday: date.weekday, period: ghost.period),
    );
    controller.clearGhost();
    if (result == true && Get.isRegistered<LocalTimetableRepository>()) {
      // 保存后让课表重算这一周。
      controller.update();
    }
  }

  /// 周/月视图共用的一层竖向滚动，日视图自己滚动所以不包这层。
  Widget _scrollable(BuildContext context, Widget child) {
    return SingleChildScrollView(
      key: const ValueKey('schedule-grid-scroll'),
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 96,
      ),
      child: child,
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
        // 日视图只显示选中的那一天；周末开关在日视图不裁剪（单列）。
        final viewDays = switch (controller.viewMode.value) {
          ScheduleViewMode.day => [controller.displayedDate],
          _ => days,
        };
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
                const SizedBox(height: 2),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _ScheduleHeading(
                    title: controller.timetableName,
                    teachingWeek: controller.teachingWeek,
                    displayedDate: controller.displayedDate,
                    isCurrentView: controller.isCurrentView,
                    todayLabel: controller.currentViewLabel,
                    onWeek: () => _openWeekSheet(controller),
                    onSettings: () => showScheduleSettingsSheet(context),
                    onToday: _onToday(controller),
                    viewMode: controller.viewMode.value,
                    onViewMode: controller.switchView,
                  ),
                ),
                // 只有周视图需要星期表头；日视图是时间线，月视图自带星期行。
                if (controller.viewMode.value == ScheduleViewMode.week) ...[
                  const SizedBox(height: AppSpace.xs),
                  _WeekdayHeader(
                    days: viewDays,
                    today: controller.today,
                    timeRailWidth: timeRailWidth,
                    teachingWeek: controller.teachingWeek,
                    examDays: {
                      for (final date in viewDays)
                        if (controller.examsOn(date).isNotEmpty)
                          DateTime(date.year, date.month, date.day),
                    },
                  ),
                ],
                const SizedBox(height: AppSpace.sm),
                Expanded(
                  // 日视图自己竖向滚动，周/月视图由 _scrollable 包一层滚动。
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
                        key: ValueKey(switch (controller.viewMode.value) {
                          ScheduleViewMode.month => controller.displayedMonth,
                          ScheduleViewMode.day => controller.displayedDate,
                          ScheduleViewMode.week => controller.weekStart.value,
                        }),
                        // 日视图是时间线，月视图是整月日历，周视图是节次网格。
                        child: switch (controller.viewMode.value) {
                          ScheduleViewMode.day => ScheduleDayView(
                            controller: controller,
                            colorScheme: appearance.courseColorScheme.value,
                            saturation:
                                appearance.scheduleCourseSaturation.value,
                          ),
                          ScheduleViewMode.month => _scrollable(
                            context,
                            ScheduleMonthView(
                              controller: controller,
                              colorScheme: appearance.courseColorScheme.value,
                              saturation:
                                  appearance.scheduleCourseSaturation.value,
                            ),
                          ),
                          ScheduleViewMode.week => _scrollable(
                            context,
                            _WeekGrid(
                              key: const ValueKey('schedule-grid'),
                              days: viewDays,
                              today: controller.today,
                              currentMinute: controller.currentMinute,
                              timeRailWidth: timeRailWidth,
                              rowHeight: appearance.scheduleRowHeight.value,
                              colorScheme: appearance.courseColorScheme.value,
                              saturation:
                                  appearance.scheduleCourseSaturation.value,
                              cardWidthFactor:
                                  appearance.scheduleCardWidth.value,
                              cardInset: appearance.scheduleCardInset.value,
                              verticalInset:
                                  appearance.scheduleVerticalInset.value,
                              cardOpacity: appearance.scheduleCardOpacity.value,
                              cardRadius: appearance.scheduleCardRadius.value,
                              showBorder: appearance.scheduleShowBorder.value,
                              borderWidth: appearance.scheduleBorderWidth.value,
                              showTopLine: appearance.scheduleShowTopLine.value,
                              showLocation:
                                  appearance.scheduleShowLocation.value,
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
                                  appearance.schedulePeriodDuration.value
                                      .round(),
                              railTextLayout: railTextLayout,
                              showCurrentTimeLine:
                                  appearance.scheduleShowCurrentTimeLine.value,
                              showGridLines:
                                  appearance.scheduleShowGridLines.value,
                              ghost: controller.ghostSlot.value,
                              onTapSlot: (dayIndex, period) => _handleSlotTap(
                                controller,
                                days,
                                dayIndex,
                                period,
                              ),
                              onTapGhost: () =>
                                  _openAddLesson(controller, days),
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
                                controller.clearGhost();
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
                                // 点已有课程时收起空白格里的占位。
                                controller.clearGhost();
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
                        },
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
    required this.displayedDate,
    required this.isCurrentView,
    required this.todayLabel,
    required this.onWeek,
    required this.onSettings,
    required this.onToday,
    required this.viewMode,
    required this.onViewMode,
  });

  /// 课表名称，放在标题区右下角。
  final String? title;
  final int? teachingWeek;

  /// 日视图显示的是哪一天。
  final DateTime displayedDate;

  final bool isCurrentView;
  final String todayLabel;
  final VoidCallback onWeek;
  final VoidCallback onSettings;
  final VoidCallback onToday;

  /// 当前的显示粒度与切换回调。
  final ScheduleViewMode viewMode;
  final ValueChanged<ScheduleViewMode> onViewMode;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final name = (title ?? '').trim();
    final isDay = viewMode == ScheduleViewMode.day;
    // 日视图的大标题变成当天日期，切换日期时文字向上跳进顶栏。
    final weekLabel = isDay
        ? '${displayedDate.month}月${displayedDate.day}日'
        : (teachingWeek == null ? '学期外' : '第$teachingWeek周');
    final hint = isDay
        ? '周${_weekdayLabels[displayedDate.weekday - 1]}'
              '${teachingWeek == null ? '' : ' · 第$teachingWeek周'}'
              '${name.isEmpty ? '' : ' · $name'}'
        : (name.isEmpty ? '我的课表' : name);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              // 周次 / 日期在左上角，字号比课表名称大一级。
              AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.fast),
                switchInCurve: AppMotion.emphasized,
                switchOutCurve: AppMotion.emphasized,
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    for (final child in previous) child,
                    if (current != null) current,
                  ],
                ),
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.6),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: Text(
                  weekLabel,
                  key: ValueKey(
                    isDay ? 'schedule-day-label' : 'schedule-week-label',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleLarge?.copyWith(
                    color: colors.ink,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              const SizedBox(height: 1),
              // 课表名称 / 当天说明紧跟在下面。
              Text(
                hint,
                key: const ValueKey('schedule-heading'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(
                  color: colors.inkMuted,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        // 视图切换：日 / 周 / 月。
        ScheduleViewSwitcher(mode: viewMode, onChanged: onViewMode),
        const SizedBox(width: AppSpace.xs),
        // 右侧动作组：回到本周 + 两个图标按钮，整体在两行文字之间竖直居中。
        ScheduleTodayButton(
          visible: !isCurrentView,
          label: todayLabel,
          onTap: onToday,
        ),
        const SizedBox(width: AppSpace.xs),
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
    );
  }
}

class _WeekdayHeader extends StatelessWidget {
  const _WeekdayHeader({
    required this.days,
    required this.today,
    required this.timeRailWidth,
    required this.teachingWeek,
    required this.examDays,
  });

  final List<DateTime> days;
  final DateTime today;
  final double timeRailWidth;

  /// 节次栏上方展示当前教学周。
  final int? teachingWeek;

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
          // 节次栏上方写周次，和下面一列节次数字对齐。
          SizedBox(
            width: timeRailWidth,
            child: Align(
              // 周次在节次栏顶部居中。
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Semantics(
                  label: teachingWeek == null ? '学期外' : '第 $teachingWeek 周',
                  child: ExcludeSemantics(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        teachingWeek == null ? '—' : '$teachingWeek周',
                        key: const ValueKey('schedule-rail-week'),
                        textAlign: TextAlign.center,
                        style: text.labelSmall?.copyWith(
                          color: colors.inkMuted,
                          fontWeight: FontWeight.w700,
                          height: 1,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
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
    required this.ghost,
    required this.onTapSlot,
    required this.onTapGhost,
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

  /// 空白格上点出来的加号占位。
  final ({int dayIndex, int period})? ghost;
  final void Function(int dayIndex, int period) onTapSlot;
  final VoidCallback onTapGhost;

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

          return GestureDetector(
            // 只有落在空白处才轮到这一层拿到点击，卡片自己会先消费掉。
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) {
              final local = details.localPosition;
              if (local.dx < timeRailWidth) return;
              final dayIndex = ((local.dx - timeRailWidth) / dayWidth)
                  .floor()
                  .clamp(0, days.length - 1);
              final period =
                  (local.dy / rowHeight).floor().clamp(0, periodCount - 1) + 1;
              // 再点同一格就是「确认添加」，不依赖手势竞技场谁赢。
              final current = ghost;
              if (current != null &&
                  current.dayIndex == dayIndex &&
                  current.period == period) {
                onTapGhost();
                return;
              }
              onTapSlot(dayIndex, period);
            },
            child: Stack(
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
                if (ghost case final slot?)
                  Positioned(
                    left:
                        timeRailWidth +
                        slot.dayIndex * dayWidth +
                        horizontalOffset,
                    top: (slot.period - 1) * rowHeight + verticalInset,
                    width: lessonWidth,
                    height: rowHeight - verticalInset * 2,
                    child: _GhostSlot(onTap: onTapGhost, radius: cardRadius),
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
            ),
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

bool _sameDate(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

bool _containsToday(List<DateTime> days, DateTime today) =>
    days.any((date) => _sameDate(date, today));

/// 空白格里的加号占位：点一下进入添加课程页。
class _GhostSlot extends StatelessWidget {
  const _GhostSlot({required this.onTap, required this.radius});

  final VoidCallback onTap;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final borderRadius = BorderRadius.circular(radius);
    return Semantics(
      button: true,
      label: '添加课程，点击打开添加界面',
      child: ExcludeSemantics(
        child: Pressable(
          key: const ValueKey('schedule-ghost-slot'),
          onTap: onTap,
          color: colors.surfaceMuted,
          borderRadius: borderRadius,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: borderRadius,
              border: Border.all(
                color: colors.inkFaint.withValues(alpha: 0.55),
                width: 1,
              ),
            ),
            child: Center(
              child: Icon(AppIcons.add, size: 18, color: colors.inkMuted),
            ),
          ),
        ),
      ),
    );
  }
}
