import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';
import 'package:qinghe_app/data/models/timetable.dart';

/// 学期真实进度：当前教学周 / 总周数；学期开始前为 0，结束后为 1。
@visibleForTesting
double semesterProgressOf(Timetable table, DateTime now) {
  final week = table.teachingWeekOn(now);
  if (week != null) {
    return (week / table.config.weekCount).clamp(0.0, 1.0);
  }
  return now.isBefore(table.config.week1Monday) ? 0.0 : 1.0;
}

/// 我的页面的学期进度卡，外环显示进度，内侧刻度对应教学周。
class SemesterProgressCard extends StatefulWidget {
  const SemesterProgressCard({
    required this.timetable,
    required this.now,
    this.onTap,
    super.key,
  });

  final Timetable? timetable;
  final DateTime now;
  final VoidCallback? onTap;

  @override
  State<SemesterProgressCard> createState() => _SemesterProgressCardState();
}

class _SemesterProgressCardState extends State<SemesterProgressCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 760),
  );
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppMotion.reduced(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(SemesterProgressCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timetable?.id != widget.timetable?.id) {
      if (AppMotion.reduced(context)) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final table = widget.timetable;
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    if (table == null || table.rules.isEmpty) {
      return _buildEmpty(context);
    }

    final totalWeeks = table.config.weekCount;
    final currentWeek = table.teachingWeekOn(widget.now);
    final courseCount = table.rules.map((rule) => rule.courseId).toSet().length;
    final weekLessons = _weekLessons(table);
    final accent = Theme.of(context).colorScheme.primary;
    final semesterProgress = semesterProgressOf(table, widget.now);

    return Pressable(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      semanticLabel:
          '学期进度，'
          '${currentWeek == null ? '当前不在学期内' : '第 $currentWeek 周，共 $totalWeeks 周'}，'
          '$courseCount 门课程，本周 $weekLessons 节，查看课表',
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpace.lg,
          AppSpace.lg,
          AppSpace.md,
          AppSpace.lg,
        ),
        child: Row(
          children: [
            SizedBox(
              width: 88,
              height: 88,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) => CustomPaint(
                        painter: _WeekDialPainter(
                          progress:
                              AppMotion.emphasized.transform(
                                _controller.value,
                              ) *
                              semesterProgress,
                          weeks: totalWeeks,
                          currentWeek: currentWeek,
                          accent: accent,
                          track: colors.line,
                        ),
                      ),
                    ),
                  ),
                  ExcludeSemantics(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentWeek == null ? '—' : '$currentWeek',
                          style: text.titleLarge?.copyWith(
                            color: colors.ink,
                            height: 1,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentWeek == null ? '学期外' : '周',
                          style: text.labelSmall?.copyWith(
                            color: colors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          table.config.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.labelMedium,
                        ),
                      ),
                      Icon(
                        AppIcons.chevronRight,
                        size: 16,
                        color: colors.inkFaint,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentWeek == null
                        ? '当前不在学期内'
                        : '第 $currentWeek 周 / 共 $totalWeeks 周',
                    style: text.titleMedium?.copyWith(color: colors.ink),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: AppSpace.md,
                    runSpacing: 4,
                    children: [
                      _Meta(icon: AppIcons.table, label: '$courseCount 门课程'),
                      _Meta(icon: AppIcons.clock, label: '本周 $weekLessons 节'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _weekLessons(Timetable table) {
    final monday = widget.now.day - widget.now.weekday + DateTime.monday;
    var count = 0;
    for (var offset = 0; offset < DateTime.daysPerWeek; offset++) {
      count += table
          .lessonsOn(
            DateTime(widget.now.year, widget.now.month, monday + offset),
          )
          .length;
    }
    return count;
  }

  Widget _buildEmpty(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final empty = widget.timetable;
    return Pressable(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      semanticLabel: '还没有课表，导入后可查看学期进度',
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: colors.accentSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(AppIcons.upload, size: 22, color: colors.accent),
            ),
            const SizedBox(width: AppSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('还没有课表', style: text.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    empty == null
                        ? '导入后这里会显示学期进度'
                        : '${empty.config.name}还没有课程',
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(AppIcons.chevronRight, size: 16, color: colors.inkFaint),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: colors.inkFaint),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _WeekDialPainter extends CustomPainter {
  const _WeekDialPainter({
    required this.progress,
    required this.weeks,
    required this.currentWeek,
    required this.accent,
    required this.track,
  });

  /// 已完成的学期比例（0–1）。不是动画时间，动画在外部相乘。
  final double progress;
  final int weeks;
  final int? currentWeek;
  final Color accent;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2 - 6;
    final total = math.max(weeks, 1);
    final step = 2 * math.pi / total;
    final rect = Rect.fromCircle(center: center, radius: radius);
    const start = -math.pi / 2;
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..color = track;
    canvas.drawCircle(center, radius, ring);
    if (progress > 0) {
      canvas.drawArc(
        rect,
        start,
        2 * math.pi * progress,
        false,
        ring..color = accent,
      );
    }

    for (var index = 0; index < total; index++) {
      final angle = start + (index + 1) * step;
      final direction = Offset(math.cos(angle), math.sin(angle));
      final isCurrent =
          currentWeek == index + 1 && progress * total >= index + 0.5;
      final passed = progress * total >= index + 1;
      canvas.drawLine(
        center + direction * (radius - (isCurrent ? 13 : 11)),
        center + direction * (radius - 8),
        Paint()
          ..strokeWidth = isCurrent ? 2 : 1
          ..strokeCap = StrokeCap.round
          ..color = isCurrent || passed ? accent : track,
      );
    }
    if (currentWeek == null || progress == 0) return;
    final angle = start + progress * 2 * math.pi;
    final end = center + Offset(math.cos(angle), math.sin(angle)) * radius;
    canvas.drawCircle(end, 5, Paint()..color = accent);
    canvas.drawCircle(end, 2, Paint()..color = track);
  }

  @override
  bool shouldRepaint(_WeekDialPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.currentWeek != currentWeek ||
      oldDelegate.weeks != weeks ||
      oldDelegate.accent != accent ||
      oldDelegate.track != track;
}
