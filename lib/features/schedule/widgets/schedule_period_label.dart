import 'package:flutter/material.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';

class SchedulePeriodLabel extends StatelessWidget {
  const SchedulePeriodLabel({
    required this.period,
    required this.showTime,
    required this.startTime,
    required this.endTime,
    required this.alignment,
    required this.textLayout,
    super.key,
  });

  /// 节次栏需要多宽。并排布局要同时容纳节次与时间，所以比竖排更宽。
  static double railWidthFor({
    required bool showTime,
    required ScheduleRailTextLayout textLayout,
  }) {
    if (!showTime) return 28;
    return textLayout == ScheduleRailTextLayout.sideBySide ? 64 : 50;
  }

  final int period;
  final bool showTime;
  final String startTime;
  final String endTime;
  final ScheduleTimeAlignment alignment;
  final ScheduleRailTextLayout textLayout;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final periodText = Text(
      '$period',
      textAlign: TextAlign.right,
      style: text.labelSmall?.copyWith(
        color: colors.ink,
        fontSize: 11,
        height: 1.05,
        fontWeight: FontWeight.w800,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
    final timeStyle = text.labelSmall?.copyWith(
      color: colors.inkMuted,
      fontSize: 8.5,
      height: 1.15,
      fontWeight: FontWeight.w500,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final times = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(startTime, textAlign: TextAlign.right, style: timeStyle),
        Text(endTime, textAlign: TextAlign.right, style: timeStyle),
      ],
    );

    return Semantics(
      label: showTime ? '第 $period 节，$startTime 至 $endTime' : '第 $period 节',
      child: ExcludeSemantics(
        child: Align(
          alignment: switch (alignment) {
            ScheduleTimeAlignment.top => Alignment.topRight,
            ScheduleTimeAlignment.center => Alignment.centerRight,
            ScheduleTimeAlignment.bottom => Alignment.bottomRight,
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 3, 3, 3),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: _content(periodText, times),
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(Widget periodText, Widget times) {
    if (!showTime) return periodText;
    return switch (textLayout) {
      ScheduleRailTextLayout.periodFirst => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [periodText, times],
      ),
      ScheduleRailTextLayout.timeFirst => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [times, periodText],
      ),
      ScheduleRailTextLayout.sideBySide => Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [periodText, const SizedBox(width: 4), times],
      ),
    };
  }
}
