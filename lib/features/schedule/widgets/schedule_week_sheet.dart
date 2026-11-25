import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/app_sheet.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';

/// 一周的展示信息：教学周次、它对应的周一到周日，以及那一周的课程。
typedef ScheduleWeekSlot = ({
  int week,
  DateTime monday,
  DateTime sunday,
  bool isCurrent,
  List<List<LessonOccurrence>> days,
});

/// 课表顶部右侧的周次按钮：点开抽屉式的周次选择。
class ScheduleWeekButton extends StatelessWidget {
  const ScheduleWeekButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Tooltip(
      message: '切换周次',
      child: Pressable(
        key: const ValueKey('schedule-week-button'),
        onTap: onTap,
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        semanticLabel: '切换周次',
        splashColor: colors.ink.withValues(alpha: 0.08),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Center(
            child: Icon(AppIcons.calendar, size: 17, color: colors.ink),
          ),
        ),
      ),
    );
  }
}

/// 打开周次抽屉：每一周显示成一张缩略课表，选中某一周后回到课表。
Future<void> showScheduleWeekSheet({
  required BuildContext context,
  required List<ScheduleWeekSlot> weeks,
  required int? selectedWeek,
  required int? currentWeek,
  required int periodCount,
  required ValueChanged<int> onSelect,
  VoidCallback? onBackToCurrentWeek,
}) {
  final appearance = Get.isRegistered<AppearanceController>()
      ? Get.find<AppearanceController>()
      : null;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: AppMotion.style(context),
    backgroundColor: context.colors.surface,
    builder: (sheetContext) => _WeekSheet(
      weeks: weeks,
      selectedWeek: selectedWeek,
      currentWeek: currentWeek,
      periodCount: periodCount,
      colorScheme:
          appearance?.courseColorScheme.value ?? CourseColorScheme.qinghe,
      saturation: appearance?.scheduleCourseSaturation.value ?? 1,
      onSelect: (week) {
        Navigator.of(sheetContext).pop();
        onSelect(week);
      },
      onBackToCurrentWeek: onBackToCurrentWeek == null
          ? null
          : () {
              Navigator.of(sheetContext).pop();
              onBackToCurrentWeek();
            },
    ),
  );
}

class _WeekSheet extends StatelessWidget {
  const _WeekSheet({
    required this.weeks,
    required this.selectedWeek,
    required this.currentWeek,
    required this.periodCount,
    required this.colorScheme,
    required this.saturation,
    required this.onSelect,
    this.onBackToCurrentWeek,
  });

  final List<ScheduleWeekSlot> weeks;
  final int? selectedWeek;
  final int? currentWeek;

  /// 全学期统一的节次行数，保证各周缩略图比例一致。
  final int periodCount;
  final CourseColorScheme colorScheme;
  final double saturation;
  final ValueChanged<int> onSelect;
  final VoidCallback? onBackToCurrentWeek;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final showBack = onBackToCurrentWeek != null && selectedWeek != currentWeek;

    return AppSheet(
      title: '切换周次',
      maxHeightFactor: 0.78,
      actions: [
        if (showBack)
          AppSheetAction(
            key: const ValueKey('schedule-week-today'),
            label: '回到本周',
            onPressed: onBackToCurrentWeek,
          ),
      ],
      children: [
        Row(
          children: [
            Text('每周一张缩略课表', style: text.labelSmall),
            const Spacer(),
            _LegendDot(color: colors.accent, label: '本周'),
            const SizedBox(width: AppSpace.sm),
            _LegendDot(color: colors.accentSoft, label: '有课'),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        LayoutBuilder(
          builder: (context, constraints) {
            const spacing = AppSpace.sm;
            final columns = constraints.maxWidth >= 420 ? 4 : 3;
            final width =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final week in weeks)
                  SizedBox(
                    width: width,
                    child: _WeekTile(
                      week: week,
                      selected: week.week == selectedWeek,
                      periodCount: periodCount,
                      colorScheme: colorScheme,
                      saturation: saturation,
                      onTap: () => onSelect(week.week),
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

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: text.labelSmall),
      ],
    );
  }
}

/// 一周的缩略课表：按真实节次比例画出一周里有课的方块。
class _WeekTile extends StatelessWidget {
  const _WeekTile({
    required this.week,
    required this.selected,
    required this.periodCount,
    required this.colorScheme,
    required this.saturation,
    required this.onTap,
  });

  final ScheduleWeekSlot week;
  final bool selected;
  final int periodCount;
  final CourseColorScheme colorScheme;
  final double saturation;
  final VoidCallback onTap;

  static const _thumbnailHeight = 104.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final count = week.days.fold<int>(0, (sum, day) => sum + day.length);

    return Semantics(
      button: true,
      selected: selected,
      label:
          '第 ${week.week} 周，${week.monday.month}月${week.monday.day}日到'
          '${week.sunday.month}月${week.sunday.day}日，$count 节课'
          '${week.isCurrent ? '，本周' : ''}',
      child: ExcludeSemantics(
        child: Pressable(
          key: ValueKey('schedule-week-${week.week}'),
          onTap: onTap,
          color: selected ? colors.accentSoft : colors.surfaceMuted,
          selected: selected,
          borderRadius: BorderRadius.circular(AppRadius.md),
          splashColor: colors.ink.withValues(alpha: 0.08),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(
                color: selected
                    ? colors.accent.withValues(alpha: 0.6)
                    : Colors.transparent,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(8, 7, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      '第 ${week.week} 周',
                      style: text.labelSmall?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (week.isCurrent) ...[
                      const SizedBox(width: 4),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: _thumbnailHeight,
                  child: _WeekThumbnail(
                    week: week.week,
                    days: week.days,
                    periodCount: periodCount,
                    colorScheme: colorScheme,
                    saturation: saturation,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${week.monday.month}/${week.monday.day}–'
                  '${week.sunday.month}/${week.sunday.day}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(
                    color: colors.inkMuted,
                    fontFeatures: const [FontFeature.tabularFigures()],
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

/// 缩略课表本身：一列一天，方块按节次区间定位。
///
/// 行数用全学期统一的 [periodCount]，不按当周最大节次算，否则「课少的周」
/// 会被拉伸、看起来课程变长。
class _WeekThumbnail extends StatelessWidget {
  const _WeekThumbnail({
    required this.week,
    required this.days,
    required this.periodCount,
    required this.colorScheme,
    required this.saturation,
  });

  final int week;
  final List<List<LessonOccurrence>> days;
  final int periodCount;
  final CourseColorScheme colorScheme;
  final double saturation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final rows = periodCount < 1 ? 1 : periodCount;

    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = constraints.maxWidth / days.length;
        final rowHeight = constraints.maxHeight / rows;
        return Stack(
          children: [
            // 一天的底色，让「没课」也能看出格子。
            for (var day = 0; day < days.length; day++)
              Positioned(
                left: day * columnWidth + 0.5,
                top: 0,
                width: columnWidth - 1,
                height: constraints.maxHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            for (var day = 0; day < days.length; day++)
              for (final lesson in days[day])
                Positioned(
                  key: ValueKey('week-$week-block-$day-${lesson.id}'),
                  left: day * columnWidth + 1,
                  top: (lesson.startPeriod - 1) * rowHeight + 0.5,
                  width: columnWidth - 2,
                  height:
                      (lesson.endPeriod - lesson.startPeriod + 1) * rowHeight -
                      1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: CoursePalette.of(
                        context,
                        lesson.colorIndex,
                        colorScheme,
                        saturation,
                      ).background,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }
}

/// 非本周时出现的返回按钮；本周内收缩为零高度。
class ScheduleTodayButton extends StatelessWidget {
  const ScheduleTodayButton({
    required this.visible,
    required this.onTap,
    this.label = '回到本周',
    super.key,
  });

  final bool visible;
  final VoidCallback onTap;

  /// 文案随视图变化：日视图「回到今天」、月视图「回到本月」。
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    return AnimatedSize(
      duration: AppMotion.of(context, AppMotion.medium),
      curve: AppMotion.emphasized,
      alignment: Alignment.center,
      child: AnimatedOpacity(
        duration: AppMotion.of(context, AppMotion.fast),
        opacity: visible ? 1 : 0,
        child: visible
            // 与右侧图标按钮同高，保证三者纵向对齐。
            ? SizedBox(
                height: 34,
                child: Center(
                  child: Pressable(
                    key: const ValueKey('schedule-today-button'),
                    onTap: onTap,
                    color: colors.accentSoft,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    semanticLabel: label,
                    splashColor: colors.accent.withValues(alpha: 0.16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: ExcludeSemantics(
                        child: Text(
                          label,
                          style: text.labelSmall?.copyWith(
                            color: colors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
