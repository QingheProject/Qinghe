import 'dart:math' as math;

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
import 'package:qinghe_app/features/schedule/widgets/schedule_calendar_sheet.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_day_view.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_exam_card.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_lesson_card.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_period_label.dart';
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

  /// 打开日历抽屉：日视图选日期，周/月视图选周次。
  Future<void> _openWeekSheet(ScheduleController controller) async {
    final context = Get.context;
    if (context == null) return;
    final slots = controller.weekSlots;
    if (slots == null) {
      showAppToast(context, '还没有课表，先导入课表后再切换周次。');
      return;
    }
    HapticFeedback.selectionClick();
    if (controller.viewMode.value == ScheduleViewMode.day) {
      await showScheduleCalendarSheet(context: context, controller: controller);
      return;
    }
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

  /// 「回到本周」按当前视图回位：日回今天、周回本周。
  VoidCallback _onToday(ScheduleController controller) {
    return () {
      switch (controller.viewMode.value) {
        case ScheduleViewMode.day:
          _shiftWeek(controller.goToToday);
        case ScheduleViewMode.week:
          _shiftWeek(controller.goToCurrentWeek);
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

  /// 周视图的一层竖向滚动，日视图自己滚动所以不包这层。
  /// 只有当前页带 key，避免分页时同一 key 出现多份。
  Widget _scrollable(BuildContext context, Widget child, {bool active = true}) {
    return SingleChildScrollView(
      key: active ? const ValueKey('schedule-grid-scroll') : null,
      padding: EdgeInsets.only(
        bottom: MediaQuery.paddingOf(context).bottom + 96,
      ),
      child: child,
    );
  }

  /// 周视图的一页：星期表头 + 节次网格。分页时整页跟着手指一起移动。
  Widget _weekPage(
    BuildContext context,
    AppearanceController appearance,
    List<DateTime> days,
    bool active, {
    ({int dayIndex, int period})? ghost,
  }) {
    final config = controller.activeTimetable?.config;
    final railTextLayout = appearance.scheduleRailTextLayout.value;
    final timeRailWidth = SchedulePeriodLabel.railWidthFor(
      showTime: appearance.scheduleShowTime.value,
      textLayout: railTextLayout,
    );
    return Column(
      children: [
        _WeekdayHeader(
          days: days,
          today: controller.today,
          timeRailWidth: timeRailWidth,
          teachingWeek: controller.teachingWeekOf(days.first),
          active: active,
          examDays: {
            for (final date in days)
              if (controller.examsOn(date).isNotEmpty)
                DateTime(date.year, date.month, date.day),
          },
        ),
        const SizedBox(height: AppSpace.sm),
        Expanded(
          child: _scrollable(
            context,
            active: active,
            _WeekGrid(
              key: active ? const ValueKey('schedule-grid') : null,
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
              showCurrentTimeLine: appearance.scheduleShowCurrentTimeLine.value,
              showGridLines: appearance.scheduleShowGridLines.value,
              ghost: active ? ghost : null,
              onTapSlot: (dayIndex, period) =>
                  _handleSlotTap(controller, days, dayIndex, period),
              onTapGhost: () => _openAddLesson(controller, days),
              lessonsOn: controller.lessonsOn,
              examsOn: controller.examsOn,
              examSlot: (exam) => controller.activeTimetable?.examLayout(exam),
              examColorIndex: (exam) =>
                  controller.activeTimetable?.examColorIndex(exam) ?? 0,
              onOpenExam: (exam) {
                controller.clearGhost();
                showExamDialog(
                  context,
                  exam,
                  colorIndex:
                      controller.activeTimetable?.examColorIndex(exam) ?? 0,
                );
              },
              onOpen: (lesson, date) {
                // 点已有课程时收起空白格里的占位。
                controller.clearGhost();
                showLessonDialog(context, lesson, date: date);
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final appearance = Get.find<AppearanceController>();
    return SafeArea(
      bottom: false,
      child: Obx(() {
        final isWeek = controller.viewMode.value == ScheduleViewMode.week;
        // 占位格要在 Obx 作用域里读取，分页里的页面才会随它重建。
        final ghost = controller.ghostSlot.value;
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
                    titleFlight: controller.dayTitleFlight,
                    onWeek: () => _openWeekSheet(controller),
                    onSettings: () => showScheduleSettingsSheet(context),
                    onToday: _onToday(controller),
                    viewMode: controller.viewMode.value,
                    onViewMode: controller.switchView,
                  ),
                ),
                // 日视图的小标题就在列表里，顶栏下方的间距更紧；周视图的表头跟着分页一起滑动。
                SizedBox(
                  height: controller.viewMode.value == ScheduleViewMode.day
                      ? 2
                      : 0,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: AppMotion.of(
                      context,
                      const Duration(milliseconds: 220),
                    ),
                    switchInCurve: AppMotion.emphasized,
                    switchOutCurve: AppMotion.emphasized,
                    // 切换视图时只淡入新视图，不同时绘制两份整屏内容，
                    // 避免日 / 周切换时掉帧。
                    layoutBuilder: (current, previous) =>
                        current ?? const SizedBox.shrink(),
                    transitionBuilder: _weekFadeTransition,
                    child: isWeek
                        // 周视图：每周一页，左右滑动跟手翻页。
                        ? _ScheduleWeekPager(
                            key: const ValueKey('schedule-week-pages'),
                            controller: controller,
                            showWeekend: appearance.scheduleShowWeekend.value,
                            ghost: ghost,
                            builder: (context, days, active) => _weekPage(
                              context,
                              appearance,
                              days,
                              active,
                              ghost: ghost,
                            ),
                          )
                        : ScheduleDayView(
                            key: const ValueKey('schedule-day-pages'),
                            controller: controller,
                            colorScheme: appearance.courseColorScheme.value,
                            saturation:
                                appearance.scheduleCourseSaturation.value,
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
    required this.titleFlight,
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

  /// 日视图小标题飞向顶栏的进度：飞行途中顶栏日期让位。
  final Rx<double> titleFlight;
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
              // 日视图的小标题飞上来时，顶栏这一份暂时让位，避免出现两个日期；
              // 落位后再显示，顶栏文字本身不做动画。
              Obx(() {
                final flying = titleFlight.value > 0 && titleFlight.value < 1;
                return Opacity(
                  opacity: flying ? 0 : 1,
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
                );
              }),
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
        ScheduleWeekButton(onTap: onWeek, tooltip: isDay ? '选择日期' : '切换周次'),
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
    this.active = true,
  });

  final List<DateTime> days;
  final DateTime today;
  final double timeRailWidth;

  /// 节次栏上方展示当前教学周。
  final int? teachingWeek;

  /// 当天有考试的日子，日期下方会带一个标记点。
  final Set<DateTime> examDays;

  /// 是否是当前这一页；只有当前页的节点带测试用的 key。
  final bool active;

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
                        key: active
                            ? const ValueKey('schedule-rail-week')
                            : null,
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
                examDotKey: active ? const ValueKey('schedule-exam-dot') : null,
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
    this.examDotKey,
  });

  final String weekday;
  final DateTime date;
  final bool today;
  final bool weekend;
  final bool hasExam;
  final AppColors colors;
  final Key? examDotKey;

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
                          key: examDotKey,
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
  final void Function(TimetableExam exam) onOpenExam;
  final void Function(LessonOccurrence lesson, DateTime date) onOpen;

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
                        onTap: () => onOpen(lesson, days[dayIndex]),
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
                          onTap: () => onOpenExam(exam),
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
    // 与课程卡同尺寸、同圆角，只把底色和描边换成中性的虚线，
    // 表示「这里是空的，可以添加」。
    return Semantics(
      button: true,
      label: '添加课程，点击打开添加界面',
      child: ExcludeSemantics(
        child: Pressable(
          key: const ValueKey('schedule-ghost-slot'),
          onTap: onTap,
          color: colors.surface.withValues(alpha: 0.28),
          borderRadius: borderRadius,
          child: CustomPaint(
            painter: _DashedBorderPainter(
              color: colors.inkFaint.withValues(alpha: 0.72),
              radius: radius,
            ),
            child: Center(
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: colors.inkFaint.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(AppIcons.add, size: 15, color: colors.inkMuted),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 圆角虚线描边：沿圆角矩形的周长按固定间距画短划线。
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    const inset = 0.6;
    if (size.width <= inset * 2 || size.height <= inset * 2) return;
    final rect = Rect.fromLTWH(
      inset,
      inset,
      size.width - inset * 2,
      size.height - inset * 2,
    );
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = math.min(distance + dash, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}

/// 周视图的横向分页：每周一页，拖动时页面跟手移动，松手吸附到相邻的一周。
class _ScheduleWeekPager extends StatefulWidget {
  const _ScheduleWeekPager({
    required this.controller,
    required this.showWeekend,
    required this.ghost,
    required this.builder,
    super.key,
  });

  final ScheduleController controller;
  final bool showWeekend;

  /// 当前页上的加号占位格。
  final ({int dayIndex, int period})? ghost;

  /// 构建某一页：这一周有哪些天、是不是当前页、以及占位格。
  final Widget Function(BuildContext context, List<DateTime> days, bool active)
  builder;

  @override
  State<_ScheduleWeekPager> createState() => _ScheduleWeekPagerState();
}

class _ScheduleWeekPagerState extends State<_ScheduleWeekPager> {
  late final PageController _pages = PageController(initialPage: _targetIndex);

  /// 由顶栏周次选择、回到本周等外部操作触发的翻页，期间忽略页回调。
  bool _syncing = false;

  int get _weekCount =>
      widget.controller.activeTimetable?.config.weekCount ?? 1;

  int get _targetIndex {
    final week = widget.controller.displayedTeachingWeek;
    if (week == null) return 0;
    return (week - 1).clamp(0, _weekCount - 1);
  }

  @override
  void didUpdateWidget(_ScheduleWeekPager oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_pages.hasClients || _syncing) return;
    final current = (_pages.page ?? _targetIndex.toDouble()).round();
    final target = _targetIndex;
    if (current == target) return;
    // 从顶栏选周、回到本周：平滑滑到目标那一页。
    _syncing = true;
    _pages
        .animateToPage(
          target,
          duration: AppMotion.of(context, AppMotion.medium),
          curve: AppMotion.emphasized,
        )
        .whenComplete(() {
          if (mounted) _syncing = false;
        });
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  List<DateTime> _daysFor(int index) {
    final config = widget.controller.activeTimetable?.config;
    final monday = config == null
        ? widget.controller.displayedWeekStart
        : config.week1Monday.add(Duration(days: DateTime.daysPerWeek * index));
    final days = [
      for (var offset = 0; offset < DateTime.daysPerWeek; offset++)
        DateTime(monday.year, monday.month, monday.day + offset),
    ];
    return widget.showWeekend
        ? days
        : days.take(DateTime.friday).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final active = _targetIndex;
    return PageView.builder(
      controller: _pages,
      itemCount: _weekCount,
      onPageChanged: (index) {
        if (_syncing) return;
        widget.controller.goToTeachingWeek(index + 1);
      },
      itemBuilder: (context, index) =>
          widget.builder(context, _daysFor(index), index == active),
    );
  }
}
