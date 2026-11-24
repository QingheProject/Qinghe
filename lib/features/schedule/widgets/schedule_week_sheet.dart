import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';

/// 一周的展示信息：教学周次与它对应的周一到周日。
typedef ScheduleWeekSlot = ({
  int week,
  DateTime monday,
  DateTime sunday,
  bool isCurrent,
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
          width: 38,
          height: 34,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(AppIcons.calendar, size: 16, color: colors.ink),
              Icon(AppIcons.chevronDown, size: 14, color: colors.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}

/// 打开周次抽屉，选中某一周后回到课表。
Future<void> showScheduleWeekSheet({
  required BuildContext context,
  required List<ScheduleWeekSlot> weeks,
  required int? selectedWeek,
  required int? currentWeek,
  required ValueChanged<int> onSelect,
  VoidCallback? onBackToCurrentWeek,
}) {
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
    required this.onSelect,
    this.onBackToCurrentWeek,
  });

  final List<ScheduleWeekSlot> weeks;
  final int? selectedWeek;
  final int? currentWeek;
  final ValueChanged<int> onSelect;
  final VoidCallback? onBackToCurrentWeek;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final showBack = onBackToCurrentWeek != null && selectedWeek != currentWeek;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 6),
              child: Row(
                children: [
                  Text('切换周次', style: text.titleMedium),
                  const Spacer(),
                  if (showBack)
                    TextButton(
                      key: const ValueKey('schedule-week-today'),
                      onPressed: onBackToCurrentWeek,
                      child: const Text('回到本周'),
                    ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: '关闭',
                    icon: const Icon(AppIcons.close, size: 20),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    const spacing = AppSpace.sm;
                    final columns = constraints.maxWidth >= 420 ? 4 : 3;
                    final width =
                        (constraints.maxWidth - spacing * (columns - 1)) /
                        columns;
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
                              onTap: () => onSelect(week.week),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 4),
              child: Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: colors.line,
                    borderRadius: BorderRadius.circular(2),
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

class _WeekTile extends StatelessWidget {
  const _WeekTile({
    required this.week,
    required this.selected,
    required this.onTap,
  });

  final ScheduleWeekSlot week;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final foreground = selected ? colors.onAccent : colors.ink;

    return Semantics(
      button: true,
      selected: selected,
      label:
          '第 ${week.week} 周，${week.monday.month}月${week.monday.day}日到'
          '${week.sunday.month}月${week.sunday.day}日'
          '${week.isCurrent ? '，本周' : ''}',
      child: ExcludeSemantics(
        child: Pressable(
          key: ValueKey('schedule-week-${week.week}'),
          onTap: onTap,
          color: selected ? colors.accent : colors.surfaceMuted,
          selected: selected,
          borderRadius: BorderRadius.circular(AppRadius.md),
          splashColor: selected
              ? colors.onAccent.withValues(alpha: 0.16)
              : colors.ink.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.sm,
              vertical: 10,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '第 ${week.week} 周',
                      style: text.labelMedium?.copyWith(
                        color: foreground,
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
                          color: selected
                              ? colors.onAccent.withValues(alpha: 0.9)
                              : colors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${week.monday.month}/${week.monday.day}–'
                  '${week.sunday.month}/${week.sunday.day}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.labelSmall?.copyWith(
                    color: selected
                        ? colors.onAccent.withValues(alpha: 0.85)
                        : colors.inkMuted,
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

/// 非本周时出现的返回按钮；本周内收缩为零高度。
class ScheduleTodayButton extends StatelessWidget {
  const ScheduleTodayButton({
    required this.visible,
    required this.onTap,
    super.key,
  });

  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    return AnimatedSize(
      duration: AppMotion.of(context, AppMotion.medium),
      curve: AppMotion.emphasized,
      alignment: Alignment.centerRight,
      child: AnimatedOpacity(
        duration: AppMotion.of(context, AppMotion.fast),
        opacity: visible ? 1 : 0,
        child: visible
            ? Pressable(
                key: const ValueKey('schedule-today-button'),
                onTap: onTap,
                color: colors.accentSoft,
                borderRadius: BorderRadius.circular(AppRadius.xs),
                semanticLabel: '回到本周',
                splashColor: colors.accent.withValues(alpha: 0.16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: Text(
                    '回到本周',
                    style: text.labelSmall?.copyWith(
                      color: colors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}
