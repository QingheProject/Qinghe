import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/features/schedule/controllers/schedule_controller.dart';

/// 顶部的「日 / 周 / 月」分段切换。
class ScheduleViewSwitcher extends StatelessWidget {
  const ScheduleViewSwitcher({
    required this.mode,
    required this.onChanged,
    super.key,
  });

  final ScheduleViewMode mode;
  final ValueChanged<ScheduleViewMode> onChanged;

  static const _labels = {
    ScheduleViewMode.day: '日',
    ScheduleViewMode.week: '周',
    ScheduleViewMode.month: '月',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      label: '切换课表视图',
      child: Container(
        key: const ValueKey('schedule-view-switcher'),
        height: 30,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: colors.surfaceMuted,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in _labels.entries)
              _Segment(
                label: entry.key.name,
                display: entry.value,
                selected: mode == entry.key,
                onTap: () => onChanged(entry.key),
              ),
          ],
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.display,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String display;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label视图',
      child: ExcludeSemantics(
        child: Pressable(
          key: ValueKey('schedule-view-$label'),
          onTap: selected ? null : onTap,
          color: selected ? colors.surface : Colors.transparent,
          selected: selected,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          semanticLabel: '$label视图',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: Text(
                display,
                style: text.labelMedium?.copyWith(
                  color: selected ? colors.ink : colors.inkMuted,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
