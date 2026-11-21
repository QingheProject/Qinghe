import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_lesson_card.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_period_label.dart';

class ScheduleAppearancePage extends GetView<AppearanceController> {
  const ScheduleAppearancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.canvas,
      appBar: AppBar(title: const Text('课表外观'), centerTitle: true),
      body: SafeArea(
        top: false,
        child: Obx(
          () => ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SchedulePreview(
                        colorScheme: controller.courseColorScheme.value,
                        saturation: controller.scheduleCourseSaturation.value,
                        rowHeight: controller.scheduleRowHeight.value,
                        cardWidthFactor: controller.scheduleCardWidth.value,
                        cardInset: controller.scheduleCardInset.value,
                        verticalInset: controller.scheduleVerticalInset.value,
                        cardOpacity: controller.scheduleCardOpacity.value,
                        showBorder: controller.scheduleShowBorder.value,
                        borderWidth: controller.scheduleBorderWidth.value,
                        showTopLine: controller.scheduleShowTopLine.value,
                        showLocation: controller.scheduleShowLocation.value,
                        showTeacher: controller.scheduleShowTeacher.value,
                        textLayout: controller.scheduleTextLayout.value,
                        showTime: controller.scheduleShowTime.value,
                        timeAlignment: controller.scheduleTimeAlignment.value,
                        startTimes: controller.scheduleStartTimes.toList(),
                        periodDuration: controller.schedulePeriodDuration.value
                            .round(),
                        railTextLayout: controller.scheduleRailTextLayout.value,
                        showCurrentTimeLine:
                            controller.scheduleShowCurrentTimeLine.value,
                        showWeekend: controller.scheduleShowWeekend.value,
                        showGridLines: controller.scheduleShowGridLines.value,
                      ),
                      const SizedBox(height: AppSpace.xxl),
                      _CoursePaletteSetting(
                        selected: controller.courseColorScheme.value,
                        saturation: controller.scheduleCourseSaturation.value,
                        onChanged: controller.setCourseColorScheme,
                      ),
                      const SizedBox(height: AppSpace.xxl),
                      _TextLayoutSelector(
                        selected: controller.scheduleTextLayout.value,
                        onChanged: controller.setScheduleTextLayout,
                      ),
                      const SizedBox(height: AppSpace.xxl),
                      _TimeSettings(
                        showTime: controller.scheduleShowTime.value,
                        alignment: controller.scheduleTimeAlignment.value,
                        startTimes: controller.scheduleStartTimes.toList(),
                        periodDuration: controller.schedulePeriodDuration.value,
                        textLayout: controller.scheduleRailTextLayout.value,
                        onShowTimeChanged: controller.setScheduleShowTime,
                        onAlignmentChanged: controller.setScheduleTimeAlignment,
                        onTextLayoutChanged:
                            controller.setScheduleRailTextLayout,
                        onTimeSettingsChanged: (startTimes, duration) async {
                          await controller.setScheduleStartTimes(startTimes);
                          await controller.setSchedulePeriodDuration(duration);
                        },
                      ),
                      const SizedBox(height: AppSpace.xxl),
                      _SettingsGroup(
                        title: '尺寸',
                        children: [
                          _SliderSetting(
                            key: const ValueKey('schedule-height-slider'),
                            title: '课程高度',
                            description: '更高的课程块可以容纳更多文字',
                            value: controller.scheduleRowHeight.value,
                            valueLabel:
                                '${controller.scheduleRowHeight.value.round()}',
                            minimum: 42,
                            maximum: 68,
                            divisions: 13,
                            onChanged: controller.previewScheduleRowHeight,
                            onChangeEnd: controller.setScheduleRowHeight,
                          ),
                          _SliderSetting(
                            key: const ValueKey('schedule-width-slider'),
                            title: '课程宽度',
                            description: '调整课程块在每天列中的占比',
                            value: controller.scheduleCardWidth.value,
                            valueLabel:
                                '${(controller.scheduleCardWidth.value * 100).round()}%',
                            minimum: 0.72,
                            maximum: 1,
                            divisions: 7,
                            onChanged: controller.previewScheduleCardWidth,
                            onChangeEnd: controller.setScheduleCardWidth,
                          ),
                          _SliderSetting(
                            key: const ValueKey('schedule-inset-slider'),
                            title: '左右间隔',
                            description: '调整课程块两侧的留白',
                            value: controller.scheduleCardInset.value,
                            valueLabel: controller.scheduleCardInset.value
                                .toStringAsFixed(1),
                            minimum: 0,
                            maximum: 5,
                            divisions: 10,
                            onChanged: controller.previewScheduleCardInset,
                            onChangeEnd: controller.setScheduleCardInset,
                          ),
                          _SliderSetting(
                            key: const ValueKey(
                              'schedule-vertical-inset-slider',
                            ),
                            title: '上下间隔',
                            description: '调整课程块上下方的留白',
                            value: controller.scheduleVerticalInset.value,
                            valueLabel: controller.scheduleVerticalInset.value
                                .toStringAsFixed(1),
                            minimum: 0,
                            maximum: 8,
                            divisions: 16,
                            onChanged: controller.previewScheduleVerticalInset,
                            onChangeEnd: controller.setScheduleVerticalInset,
                          ),
                          _SwitchSetting(
                            key: const ValueKey('schedule-weekend-switch'),
                            title: '显示周末',
                            description: '关闭后工作日会自动铺满课表宽度',
                            value: controller.scheduleShowWeekend.value,
                            onChanged: controller.setScheduleShowWeekend,
                            showDivider: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.xxl),
                      _SettingsGroup(
                        title: '卡片样式',
                        children: [
                          _SliderSetting(
                            key: const ValueKey('schedule-opacity-slider'),
                            title: '底色透明度',
                            description: '只调整课程底色，文字始终保持清晰',
                            value: controller.scheduleCardOpacity.value,
                            valueLabel:
                                '${(controller.scheduleCardOpacity.value * 100).round()}%',
                            minimum: 0.7,
                            maximum: 1,
                            divisions: 6,
                            onChanged: controller.previewScheduleCardOpacity,
                            onChangeEnd: controller.setScheduleCardOpacity,
                          ),
                          _SliderSetting(
                            key: const ValueKey('schedule-saturation-slider'),
                            title: '课程饱和度',
                            description: '调整课程颜色的鲜艳程度',
                            value: controller.scheduleCourseSaturation.value,
                            valueLabel:
                                '${(controller.scheduleCourseSaturation.value * 100).round()}%',
                            minimum: 0,
                            maximum: 1,
                            divisions: 20,
                            onChanged:
                                controller.previewScheduleCourseSaturation,
                            onChangeEnd: controller.setScheduleCourseSaturation,
                          ),
                          _SwitchSetting(
                            key: const ValueKey('schedule-border-switch'),
                            title: '课程边框',
                            description: '为课程块增加细描边',
                            value: controller.scheduleShowBorder.value,
                            onChanged: controller.setScheduleShowBorder,
                          ),
                          _SliderSetting(
                            key: const ValueKey('schedule-border-width-slider'),
                            title: '描边粗细',
                            description: '调整课程边框线条粗细',
                            value: controller.scheduleBorderWidth.value,
                            valueLabel: controller.scheduleBorderWidth.value
                                .toStringAsFixed(1),
                            minimum: 0.5,
                            maximum: 2.5,
                            divisions: 4,
                            onChanged: controller.previewScheduleBorderWidth,
                            onChangeEnd: controller.setScheduleBorderWidth,
                            enabled: controller.scheduleShowBorder.value,
                          ),
                          _SwitchSetting(
                            key: const ValueKey('schedule-top-line-switch'),
                            title: '顶部横线',
                            description: '显示课程色彩识别线',
                            value: controller.scheduleShowTopLine.value,
                            onChanged: controller.setScheduleShowTopLine,
                          ),
                          _SwitchSetting(
                            key: const ValueKey('schedule-grid-lines-switch'),
                            title: '背景横线',
                            description: '显示节次之间的横向辅助线',
                            value: controller.scheduleShowGridLines.value,
                            onChanged: controller.setScheduleShowGridLines,
                            showDivider: false,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.xxl),
                      _SettingsGroup(
                        title: '显示内容',
                        children: [
                          _SwitchSetting(
                            key: const ValueKey(
                              'schedule-current-time-line-switch',
                            ),
                            title: '当前时间线',
                            description: '在本周课表中标记当前时间位置',
                            value: controller.scheduleShowCurrentTimeLine.value,
                            onChanged:
                                controller.setScheduleShowCurrentTimeLine,
                          ),
                          _SwitchSetting(
                            key: const ValueKey('schedule-location-switch'),
                            title: '上课地点',
                            description: '在空间足够时显示地点',
                            value: controller.scheduleShowLocation.value,
                            onChanged: controller.setScheduleShowLocation,
                          ),
                          _SwitchSetting(
                            key: const ValueKey('schedule-teacher-switch'),
                            title: '授课教师',
                            description: '在空间足够时显示教师',
                            value: controller.scheduleShowTeacher.value,
                            onChanged: controller.setScheduleShowTeacher,
                            showDivider: false,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SchedulePreview extends StatelessWidget {
  const _SchedulePreview({
    required this.colorScheme,
    required this.saturation,
    required this.rowHeight,
    required this.cardWidthFactor,
    required this.cardInset,
    required this.verticalInset,
    required this.cardOpacity,
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
    required this.showWeekend,
    required this.showGridLines,
  });

  static final _previewDate = DateTime(2026, 9, 7);
  static const _lessons = [
    LessonOccurrence(
      id: 'preview-1',
      courseName: '示例课程甲',
      startPeriod: 1,
      endPeriod: 2,
      startMinute: 480,
      endMinute: 580,
      location: '示例教室 A101',
      teacher: '示例教师',
      colorIndex: 0,
    ),
    LessonOccurrence(
      id: 'preview-2',
      courseName: '示例实验乙',
      startPeriod: 2,
      endPeriod: 3,
      startMinute: 535,
      endMinute: 645,
      location: '示例实验室 3',
      teacher: '示例教师',
      colorIndex: 1,
    ),
  ];

  final CourseColorScheme colorScheme;
  final double saturation;
  final double rowHeight;
  final double cardWidthFactor;
  final double cardInset;
  final double verticalInset;
  final double cardOpacity;
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
  final bool showWeekend;
  final bool showGridLines;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final weekdayLabels = showWeekend
        ? const ['一', '二', '三', '四', '五', '六', '日']
        : const ['一', '二', '三', '四', '五'];
    final timeRailWidth = SchedulePeriodLabel.railWidthFor(
      showTime: showTime,
      textLayout: railTextLayout,
    );

    return Container(
      key: const ValueKey('schedule-appearance-preview'),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('实时预览', style: text.titleMedium),
              const Spacer(),
              Text(
                '模拟数据',
                style: text.labelSmall?.copyWith(color: colors.inkFaint),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              SizedBox(width: timeRailWidth),
              for (final label in weekdayLabels)
                Expanded(
                  child: Text(
                    '周$label',
                    textAlign: TextAlign.center,
                    style: text.labelSmall?.copyWith(color: colors.inkMuted),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          SizedBox(
            height: rowHeight * 4,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final dayWidth =
                    (constraints.maxWidth - timeRailWidth) /
                    weekdayLabels.length;
                return Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.canvas,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                    for (var period = 0; period < 4; period++)
                      Positioned(
                        left: 0,
                        top: period * rowHeight,
                        width: timeRailWidth,
                        height: rowHeight,
                        child: SchedulePeriodLabel(
                          period: period + 1,
                          showTime: showTime,
                          startTime: startTimes[period],
                          endTime: calculateScheduleEndTime(
                            startTimes[period],
                            periodDuration,
                          ),
                          alignment: timeAlignment,
                          textLayout: railTextLayout,
                        ),
                      ),
                    if (showGridLines)
                      for (var row = 1; row < 4; row++)
                        Positioned(
                          left: timeRailWidth,
                          right: 0,
                          top: row * rowHeight,
                          child: Container(
                            key: ValueKey('schedule-preview-grid-line-$row'),
                            height: 1,
                            color: colors.line,
                          ),
                        ),
                    _PreviewLesson(
                      cardKey: const ValueKey('schedule-preview-course-card'),
                      colorScheme: colorScheme,
                      saturation: saturation,
                      lesson: _lessons[0],
                      date: _previewDate,
                      dayIndex: 0,
                      timeRailWidth: timeRailWidth,
                      dayWidth: dayWidth,
                      rowHeight: rowHeight,
                      cardWidthFactor: cardWidthFactor,
                      cardInset: cardInset,
                      verticalInset: verticalInset,
                      cardOpacity: cardOpacity,
                      showBorder: showBorder,
                      borderWidth: borderWidth,
                      showTopLine: showTopLine,
                      showLocation: showLocation,
                      showTeacher: showTeacher,
                      textLayout: textLayout,
                    ),
                    _PreviewLesson(
                      colorScheme: colorScheme,
                      saturation: saturation,
                      lesson: _lessons[1],
                      date: _previewDate.add(const Duration(days: 1)),
                      dayIndex: 1,
                      timeRailWidth: timeRailWidth,
                      dayWidth: dayWidth,
                      rowHeight: rowHeight,
                      cardWidthFactor: cardWidthFactor,
                      cardInset: cardInset,
                      verticalInset: verticalInset,
                      cardOpacity: cardOpacity,
                      showBorder: showBorder,
                      borderWidth: borderWidth,
                      showTopLine: showTopLine,
                      showLocation: showLocation,
                      showTeacher: showTeacher,
                      textLayout: textLayout,
                    ),
                    if (showCurrentTimeLine) ...[
                      Positioned(
                        left: timeRailWidth,
                        right: 0,
                        top: rowHeight * 2.35,
                        child: Container(
                          key: const ValueKey(
                            'schedule-preview-current-time-line',
                          ),
                          height: 1.5,
                          color: colors.accent.withValues(alpha: 0.82),
                        ),
                      ),
                      Positioned(
                        left: timeRailWidth - 3,
                        top: rowHeight * 2.35 - 2.25,
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
          ),
        ],
      ),
    );
  }
}

class _PreviewLesson extends StatelessWidget {
  const _PreviewLesson({
    required this.colorScheme,
    required this.saturation,
    required this.lesson,
    required this.date,
    required this.dayIndex,
    required this.timeRailWidth,
    required this.dayWidth,
    required this.rowHeight,
    required this.cardWidthFactor,
    required this.cardInset,
    required this.verticalInset,
    required this.cardOpacity,
    required this.showBorder,
    required this.borderWidth,
    required this.showTopLine,
    required this.showLocation,
    required this.showTeacher,
    required this.textLayout,
    this.cardKey,
  });

  final CourseColorScheme colorScheme;
  final double saturation;
  final LessonOccurrence lesson;
  final DateTime date;
  final int dayIndex;
  final double timeRailWidth;
  final double dayWidth;
  final double rowHeight;
  final double cardWidthFactor;
  final double cardInset;
  final double verticalInset;
  final double cardOpacity;
  final bool showBorder;
  final double borderWidth;
  final bool showTopLine;
  final bool showLocation;
  final bool showTeacher;
  final ScheduleTextLayout textLayout;
  final Key? cardKey;

  @override
  Widget build(BuildContext context) {
    final availableWidth = dayWidth - cardInset * 2;
    final lessonWidth = availableWidth * cardWidthFactor;
    final horizontalOffset = cardInset + (availableWidth - lessonWidth) / 2;
    return Positioned(
      left: timeRailWidth + dayIndex * dayWidth + horizontalOffset,
      top: (lesson.startPeriod - 1) * rowHeight + verticalInset,
      width: lessonWidth,
      height:
          (lesson.endPeriod - lesson.startPeriod + 1) * rowHeight -
          verticalInset * 2,
      child: ScheduleLessonCard(
        key: cardKey,
        lesson: lesson,
        date: date,
        compact: lessonWidth < 62,
        colorScheme: colorScheme,
        saturation: saturation,
        backgroundOpacity: cardOpacity,
        showBorder: showBorder,
        borderWidth: borderWidth,
        showTopLine: showTopLine,
        showLocation: showLocation,
        showTeacher: showTeacher,
        textLayout: textLayout,
        onTap: () {},
      ),
    );
  }
}

const _coursePaletteOptions = [
  (CourseColorScheme.qinghe, '青禾'),
  (CourseColorScheme.ocean, '海风'),
  (CourseColorScheme.sunset, '暮色'),
  (CourseColorScheme.candy, '彩糖'),
  (CourseColorScheme.monochrome, '黑白'),
];

class _CoursePaletteSetting extends StatelessWidget {
  const _CoursePaletteSetting({
    required this.selected,
    required this.saturation,
    required this.onChanged,
  });

  final CourseColorScheme selected;
  final double saturation;
  final ValueChanged<CourseColorScheme> onChanged;

  String get _selectedLabel =>
      _coursePaletteOptions.firstWhere((option) => option.$1 == selected).$2;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpace.sm),
          child: Text('课程配色', style: Theme.of(context).textTheme.labelMedium),
        ),
        Semantics(
          button: true,
          label: '课程配色，当前为$_selectedLabel',
          child: Pressable(
            key: const ValueKey('course-palette-drawer'),
            onTap: () => _showPaletteDrawer(context),
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              height: 68,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '选择配色',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _selectedLabel,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  _OverlappingSwatches(
                    scheme: selected,
                    saturation: saturation,
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Icon(Icons.keyboard_arrow_up_rounded, color: colors.inkMuted),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showPaletteDrawer(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('课程配色', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text('选择一套课程颜色', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: AppSpace.lg),
              for (final (scheme, label) in _coursePaletteOptions) ...[
                _PaletteOption(
                  scheme: scheme,
                  label: label,
                  saturation: saturation,
                  selected: scheme == selected,
                  onTap: () {
                    if (scheme != selected) onChanged(scheme);
                    Navigator.of(sheetContext).pop();
                  },
                ),
                if (scheme != _coursePaletteOptions.last.$1)
                  const SizedBox(height: AppSpace.sm),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PaletteOption extends StatelessWidget {
  const _PaletteOption({
    required this.scheme,
    required this.label,
    required this.saturation,
    required this.selected,
    required this.onTap,
  });

  final CourseColorScheme scheme;
  final String label;
  final double saturation;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label课程配色',
      child: Pressable(
        key: ValueKey('course-palette-${scheme.name}'),
        onTap: onTap,
        selected: selected,
        color: colors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? colors.accent : colors.line,
              width: selected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: selected ? colors.accent : colors.ink,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              _OverlappingSwatches(scheme: scheme, saturation: saturation),
              const SizedBox(width: AppSpace.md),
              SizedBox(
                width: 22,
                child: selected
                    ? Icon(Icons.check_rounded, size: 20, color: colors.accent)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverlappingSwatches extends StatelessWidget {
  const _OverlappingSwatches({required this.scheme, required this.saturation});

  final CourseColorScheme scheme;
  final double saturation;

  @override
  Widget build(BuildContext context) {
    final palette = CoursePalette.colors(scheme, saturation);
    return ExcludeSemantics(
      child: SizedBox(
        width: 88,
        height: 22,
        child: Stack(
          children: [
            for (var index = 0; index < palette.length; index++)
              Positioned(
                left: index * 10,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: palette[index],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.colors.surface,
                      width: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TextLayoutSelector extends StatelessWidget {
  const _TextLayoutSelector({required this.selected, required this.onChanged});

  static const _options = [
    (ScheduleTextLayout.top, '靠上', Icons.vertical_align_top_rounded),
    (ScheduleTextLayout.center, '居中', Icons.vertical_align_center_rounded),
    (ScheduleTextLayout.bottom, '靠下', Icons.vertical_align_bottom_rounded),
    (ScheduleTextLayout.spaced, '间隔', Icons.format_line_spacing_rounded),
  ];

  final ScheduleTextLayout selected;
  final ValueChanged<ScheduleTextLayout> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpace.sm),
          child: Text('文字布局', style: Theme.of(context).textTheme.labelMedium),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final itemWidth = (constraints.maxWidth - AppSpace.sm) / 2;
            return Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                for (final (layout, label, icon) in _options)
                  SizedBox(
                    width: itemWidth,
                    child: Semantics(
                      button: true,
                      selected: layout == selected,
                      label: '$label文字布局',
                      child: Pressable(
                        key: ValueKey('schedule-text-layout-${layout.name}'),
                        onTap: layout == selected
                            ? null
                            : () => onChanged(layout),
                        selected: layout == selected,
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: layout == selected
                                  ? colors.accent
                                  : colors.line,
                              width: layout == selected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                icon,
                                size: 18,
                                color: layout == selected
                                    ? colors.accent
                                    : colors.inkMuted,
                              ),
                              const SizedBox(width: AppSpace.sm),
                              Text(
                                label,
                                style: Theme.of(context).textTheme.labelMedium
                                    ?.copyWith(
                                      color: layout == selected
                                          ? colors.accent
                                          : colors.inkMuted,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TimeSettings extends StatelessWidget {
  const _TimeSettings({
    required this.showTime,
    required this.alignment,
    required this.startTimes,
    required this.periodDuration,
    required this.textLayout,
    required this.onShowTimeChanged,
    required this.onAlignmentChanged,
    required this.onTextLayoutChanged,
    required this.onTimeSettingsChanged,
  });

  final bool showTime;
  final ScheduleTimeAlignment alignment;
  final List<String> startTimes;
  final double periodDuration;
  final ScheduleRailTextLayout textLayout;
  final ValueChanged<bool> onShowTimeChanged;
  final ValueChanged<ScheduleTimeAlignment> onAlignmentChanged;
  final ValueChanged<ScheduleRailTextLayout> onTextLayoutChanged;
  final Future<void> Function(List<String>, double) onTimeSettingsChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsGroup(
      title: '左侧时间',
      children: [
        _SwitchSetting(
          key: const ValueKey('schedule-time-switch'),
          title: '显示节次时间',
          description: '在左侧节次栏中显示开始与结束时间',
          value: showTime,
          onChanged: onShowTimeChanged,
        ),
        _TimeAlignmentSelector(
          selected: alignment,
          onChanged: onAlignmentChanged,
        ),
        _RailTextLayoutSelector(
          selected: textLayout,
          onChanged: onTextLayoutChanged,
        ),
        Pressable(
          key: const ValueKey('schedule-time-editor'),
          onTap: () => _showTimeEditor(context),
          color: context.colors.surface,
          child: SizedBox(
            height: 64,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '自定义节次时间',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          '每节 ${periodDuration.round()} 分钟，自动计算结束时间',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: context.colors.inkMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showTimeEditor(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: context.colors.surface,
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.9,
        child: _TimeEditorSheet(
          initialTimes: startTimes,
          initialDuration: periodDuration,
          onSave: onTimeSettingsChanged,
        ),
      ),
    );
  }
}

class _TimeAlignmentSelector extends StatelessWidget {
  const _TimeAlignmentSelector({
    required this.selected,
    required this.onChanged,
  });

  static const _options = [
    (ScheduleTimeAlignment.top, '靠上'),
    (ScheduleTimeAlignment.center, '居中'),
    (ScheduleTimeAlignment.bottom, '靠下'),
  ];

  final ScheduleTimeAlignment selected;
  final ValueChanged<ScheduleTimeAlignment> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Text('展示位置', style: Theme.of(context).textTheme.bodyMedium),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Row(
            children: [
              for (final (value, label) in _options)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: value == ScheduleTimeAlignment.bottom
                          ? 0
                          : AppSpace.sm,
                    ),
                    child: Pressable(
                      key: ValueKey('schedule-time-alignment-${value.name}'),
                      onTap: value == selected ? null : () => onChanged(value),
                      selected: value == selected,
                      color: value == selected
                          ? colors.accentSoft
                          : colors.surfaceMuted,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: SizedBox(
                        height: 44,
                        child: Center(
                          child: Text(
                            label,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: value == selected
                                      ? colors.accent
                                      : colors.inkMuted,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 16),
      ],
    );
  }
}

class _RailTextLayoutSelector extends StatelessWidget {
  const _RailTextLayoutSelector({
    required this.selected,
    required this.onChanged,
  });

  static const _options = [
    (ScheduleRailTextLayout.periodFirst, '节次在上'),
    (ScheduleRailTextLayout.timeFirst, '时间在上'),
    (ScheduleRailTextLayout.sideBySide, '并排'),
  ];

  final ScheduleRailTextLayout selected;
  final ValueChanged<ScheduleRailTextLayout> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
          child: Text('文字布局', style: text.bodyMedium),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Text('节次与时间的排列方式，选择「并排」时节次栏会加宽', style: text.bodySmall),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Row(
            children: [
              for (final (value, label) in _options)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: value == _options.last.$1 ? 0 : AppSpace.sm,
                    ),
                    child: Semantics(
                      button: true,
                      selected: value == selected,
                      label: '左侧文字布局，$label',
                      child: Pressable(
                        key: ValueKey('schedule-rail-layout-${value.name}'),
                        onTap: value == selected
                            ? null
                            : () => onChanged(value),
                        selected: value == selected,
                        color: value == selected
                            ? colors.accentSoft
                            : colors.surfaceMuted,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: SizedBox(
                          height: 44,
                          child: Center(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.labelMedium?.copyWith(
                                color: value == selected
                                    ? colors.accent
                                    : colors.inkMuted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 1, indent: 16),
      ],
    );
  }
}

class _TimeEditorSheet extends StatefulWidget {
  const _TimeEditorSheet({
    required this.initialTimes,
    required this.initialDuration,
    required this.onSave,
  });

  final List<String> initialTimes;
  final double initialDuration;
  final Future<void> Function(List<String>, double) onSave;

  @override
  State<_TimeEditorSheet> createState() => _TimeEditorSheetState();
}

class _TimeEditorSheetState extends State<_TimeEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late double _duration = widget.initialDuration;
  late final List<TextEditingController> _controllers = [
    for (final value in widget.initialTimes) TextEditingController(text: value),
  ];

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('自定义节次时间', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(
                '设置开始时间和每节时长，结束时间会自动计算',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpace.md),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '每节课时长',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '${_duration.round()} 分钟',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: context.colors.accent,
                    ),
                  ),
                ],
              ),
              Slider(
                key: const ValueKey('schedule-duration-slider'),
                value: _duration,
                min: 20,
                max: 120,
                divisions: 20,
                label: '${_duration.round()} 分钟',
                semanticFormatterCallback: (value) =>
                    '每节课时长，${value.round()} 分钟',
                onChanged: (value) => setState(() => _duration = value),
              ),
              const Divider(height: 1),
              const SizedBox(height: AppSpace.md),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: _controllers.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpace.sm),
                    itemBuilder: (context, index) {
                      final endTime = calculateScheduleEndTime(
                        _controllers[index].text,
                        _duration.round(),
                      );
                      return Row(
                        children: [
                          SizedBox(
                            width: 44,
                            child: Text(
                              '第 ${index + 1} 节',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                          const SizedBox(width: AppSpace.sm),
                          Expanded(
                            child: TextFormField(
                              key: ValueKey('schedule-time-$index'),
                              controller: _controllers[index],
                              keyboardType: TextInputType.datetime,
                              textInputAction: index == _controllers.length - 1
                                  ? TextInputAction.done
                                  : TextInputAction.next,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp('[0-9:]'),
                                ),
                                LengthLimitingTextInputFormatter(5),
                              ],
                              decoration: const InputDecoration(
                                labelText: '开始',
                                hintText: '08:00',
                                isDense: true,
                              ),
                              validator: _validateTime,
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: AppSpace.md),
                          SizedBox(
                            width: 52,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '结束',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: context.colors.inkFaint,
                                      ),
                                ),
                                Text(
                                  endTime,
                                  style: Theme.of(context).textTheme.labelMedium
                                      ?.copyWith(
                                        fontFeatures: const [
                                          FontFeature.tabularFigures(),
                                        ],
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('schedule-time-save'),
                  onPressed: _save,
                  child: const Text('保存时间'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateTime(String? value) {
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value ?? '');
    if (match == null) return '请输入 HH:mm';
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) return '时间格式不正确';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await widget.onSave([
      for (final controller in _controllers) controller.text,
    ], _duration);
    if (mounted) Navigator.of(context).pop();
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpace.sm),
          child: Text(title, style: Theme.of(context).textTheme.labelMedium),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SliderSetting extends StatelessWidget {
  const _SliderSetting({
    required this.title,
    required this.description,
    required this.value,
    required this.valueLabel,
    required this.minimum,
    required this.maximum,
    required this.divisions,
    required this.onChanged,
    required this.onChangeEnd,
    this.enabled = true,
    super.key,
  });

  final String title;
  final String description;
  final double value;
  final String valueLabel;
  final double minimum;
  final double maximum;
  final int divisions;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Column(
      children: [
        Opacity(
          opacity: enabled ? 1 : 0.48,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(title, style: text.bodyMedium)),
                    Text(
                      valueLabel,
                      style: text.labelMedium?.copyWith(color: colors.accent),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(description, style: text.bodySmall),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(trackHeight: 3),
                  child: Slider(
                    value: value,
                    min: minimum,
                    max: maximum,
                    divisions: divisions,
                    label: valueLabel,
                    semanticFormatterCallback: (_) => '$title，$valueLabel',
                    onChanged: enabled ? onChanged : null,
                    onChangeEnd: enabled ? onChangeEnd : null,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, indent: 16),
      ],
    );
  }
}

class _SwitchSetting extends StatelessWidget {
  const _SwitchSetting({
    required this.title,
    required this.description,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
    super.key,
  });

  final String title;
  final String description;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      children: [
        SwitchTheme(
          data: SwitchTheme.of(context).copyWith(
            trackColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? colors.accent
                  : colors.surfaceMuted,
            ),
            thumbColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? colors.onAccent
                  : colors.inkMuted,
            ),
            trackOutlineColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? colors.accent
                  : colors.line,
            ),
            trackOutlineWidth: const WidgetStatePropertyAll(1),
            overlayColor: WidgetStatePropertyAll(
              colors.accent.withValues(alpha: 0.08),
            ),
          ),
          child: SwitchListTile(
            value: value,
            onChanged: onChanged,
            title: Text(title),
            subtitle: Text(description),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          ),
        ),
        if (showDivider) const Divider(height: 1, indent: 16),
      ],
    );
  }
}
