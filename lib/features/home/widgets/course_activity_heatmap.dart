import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/utils/formatters.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';

const _greens = [
  Color(0xFFDCE9DF),
  Color(0xFFADD7B9),
  Color(0xFF77BD91),
  Color(0xFF438F66),
  Color(0xFF205E40),
];

class CourseActivityHeatmap extends StatelessWidget {
  const CourseActivityHeatmap({
    required this.activity,
    required this.today,
    super.key,
  });

  final List<({DateTime date, int count})> activity;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    const week = DateTime.daysPerWeek;
    return Semantics(
      container: true,
      label: '课程活跃',
      child: AppPanel(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 56),
                    for (var day = 1; day <= week; day++)
                      Expanded(
                        child: Center(
                          child: Text(
                            weekdayLabel(day).substring(2),
                            style: text.labelSmall,
                          ),
                        ),
                      ),
                  ],
                ),
                for (var start = 0; start < activity.length; start += week) ...[
                  const SizedBox(height: AppSpace.xs),
                  Row(
                    children: [
                      SizedBox(
                        width: 56,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${activity[start].date.month}/${activity[start].date.day}',
                              style: text.labelSmall,
                            ),
                          ),
                        ),
                      ),
                      for (final day in activity.skip(start).take(week))
                        Expanded(
                          child: _DayCell(day: day, today: today),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppSpace.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text('少', style: text.labelSmall),
                    const SizedBox(width: AppSpace.xs),
                    for (final color in _greens)
                      Container(
                        width: 12,
                        height: 12,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    const SizedBox(width: AppSpace.xs),
                    Text('多', style: text.labelSmall),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.today});

  final ({DateTime date, int count}) day;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final count = day.count;
    final isToday = DateUtils.isSameDay(day.date, today);
    final date = day.date;
    final level = count.clamp(0, _greens.length - 1);
    final label = '${isToday ? '今天，' : ''}${date.month}月${date.day}日，$count 次课';
    final colors = context.colors;
    return Semantics(
      container: true,
      label: label,
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: LayoutBuilder(
            builder: (context, constraints) => Tooltip(
              triggerMode: TooltipTriggerMode.tap,
              message: '课程: $count',
              preferBelow: false,
              verticalOffset: constraints.maxWidth / 2 + AppSpace.xs,
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 12),
              margin: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
              decoration: ShapeDecoration(
                color: colors.ink,
                shape: const _CountBubbleShape(),
              ),
              textStyle: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: colors.canvas),
              child: AspectRatio(
                aspectRatio: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: _greens[level],
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    border: isToday
                        ? Border.all(color: const Color(0xFF102E20), width: 2)
                        : null,
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

class _CountBubbleShape extends ShapeBorder {
  const _CountBubbleShape();

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    const arrowHeight = 6.0;
    final body = Rect.fromLTRB(
      rect.left,
      rect.top,
      rect.right,
      rect.bottom - arrowHeight,
    );
    final center = rect.center.dx;
    return Path()
      ..addRRect(
        RRect.fromRectAndRadius(body, const Radius.circular(AppRadius.sm)),
      )
      ..moveTo(center - arrowHeight, body.bottom - 1)
      ..lineTo(center + arrowHeight, body.bottom - 1)
      ..lineTo(center, rect.bottom)
      ..close();
  }

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) =>
      getOuterPath(rect, textDirection: textDirection);

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}
