import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/brand_mark.dart';

/// 引导插画统一的画布尺寸，外部用 FittedBox 适配小屏。
const _canvas = Size(300, 250);

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: SizedBox.fromSize(size: _canvas, child: child),
    );
  }
}

/// 第一步：完整的七天周网格，课程块依次落位。
class WeekGridIllustration extends StatelessWidget {
  const WeekGridIllustration({required this.animation, super.key});

  final Animation<double> animation;

  static const _days = ['一', '二', '三', '四', '五', '六', '日'];
  static const _rows = 8;
  static const _today = 4;

  /// (星期序号, 起始行, 跨行数, 配色)
  static const _blocks = <(int, int, int, int)>[
    (0, 0, 2, 0),
    (0, 4, 2, 1),
    (1, 2, 2, 2),
    (1, 6, 2, 3),
    (2, 0, 2, 0),
    (2, 2, 2, 4),
    (3, 0, 2, 2),
    (3, 4, 2, 1),
    (4, 2, 2, 4),
    (4, 4, 2, 0),
    (5, 6, 1, 5),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    const gutter = 18.0;

    return _Panel(
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: gutter),
              for (var day = 0; day < 7; day++)
                Expanded(
                  child: Center(
                    child: Text(
                      _days[day],
                      style: text.labelSmall?.copyWith(
                        color: day == _today ? colors.accent : colors.inkFaint,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: LayoutBuilder(
              builder: (context, box) {
                final colWidth = (box.maxWidth - gutter) / 7;
                final rowHeight = box.maxHeight / _rows;
                return AnimatedBuilder(
                  animation: animation,
                  builder: (context, _) {
                    final t = animation.value;
                    return Stack(
                      children: [
                        Positioned(
                          left: gutter + _today * colWidth,
                          width: colWidth,
                          top: 0,
                          bottom: 0,
                          child: Opacity(
                            opacity: AppMotion.interval(t, 0.1, 0.4),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: colors.accentSoft.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        for (var row = 1; row < _rows; row++)
                          Positioned(
                            left: gutter,
                            right: 0,
                            top: row * rowHeight,
                            child: Container(height: 1, color: colors.line),
                          ),
                        for (var row = 0; row < _rows; row++)
                          Positioned(
                            left: 0,
                            width: 12,
                            top: row * rowHeight,
                            height: rowHeight,
                            child: Center(
                              child: Text(
                                '${row + 1}',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: colors.inkFaint,
                                ),
                              ),
                            ),
                          ),
                        for (var i = 0; i < _blocks.length; i++)
                          _block(context, i, t, colWidth, rowHeight, gutter),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _block(
    BuildContext context,
    int index,
    double t,
    double colWidth,
    double rowHeight,
    double gutter,
  ) {
    final (day, row, span, color) = _blocks[index];
    final tone = CoursePalette.of(context, color);
    final v = AppMotion.interval(t, 0.25 + index * 0.045, 0.55 + index * 0.045);
    return Positioned(
      left: gutter + day * colWidth + 1.5,
      top: row * rowHeight + 1.5,
      width: colWidth - 3,
      height: span * rowHeight - 3,
      child: Opacity(
        opacity: v,
        child: Transform.scale(
          scale: 0.7 + 0.3 * v,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: tone.background,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 2.5, color: tone.foreground),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 4, 6, 0),
                  child: Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: tone.foreground.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(2),
                    ),
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

/// 第二步：单周逐格点亮，随后一节课从原时段平移到调整后的时段。
class FlexibleWeeksIllustration extends StatelessWidget {
  const FlexibleWeeksIllustration({required this.animation, super.key});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final tone = CoursePalette.of(context, 0);

    return _Panel(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = animation.value;
          final move = AppMotion.interval(t, 0.58, 0.95);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('教学周', style: text.labelMedium),
                  const Spacer(),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('单周', style: text.labelSmall),
                ],
              ),
              const SizedBox(height: 10),
              for (var row = 0; row < 2; row++)
                Row(
                  children: [
                    for (var col = 0; col < 8; col++)
                      Expanded(child: _weekCell(context, row * 8 + col + 1, t)),
                  ],
                ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text('调课', style: text.labelMedium),
                  const SizedBox(width: 6),
                  Opacity(
                    opacity: move,
                    child: Text(
                      '· 只改这一次',
                      style: text.labelSmall?.copyWith(color: colors.accent),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 64,
                child: LayoutBuilder(
                  builder: (context, box) {
                    const gap = 12.0;
                    final slot = (box.maxWidth - gap) / 2;
                    return Stack(
                      children: [
                        for (var i = 0; i < 2; i++)
                          Positioned(
                            left: i * (slot + gap),
                            width: slot,
                            top: 0,
                            bottom: 0,
                            child: _Slot(label: i == 0 ? '原安排' : '调整后'),
                          ),
                        Positioned(
                          left: (slot + gap) * move,
                          width: slot,
                          top: 0,
                          bottom: 0,
                          child: Opacity(
                            opacity: AppMotion.interval(t, 0.4, 0.6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                color: tone.background,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.sm,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 3,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      color: tone.foreground,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '示例课程甲',
                                          maxLines: 1,
                                          softWrap: false,
                                          overflow: TextOverflow.fade,
                                          style: text.labelMedium?.copyWith(
                                            color: colors.ink,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        Text(
                                          move < 0.5
                                              ? '周二 · 3–4 节'
                                              : '周四 · 5–6 节',
                                          maxLines: 1,
                                          softWrap: false,
                                          overflow: TextOverflow.fade,
                                          style: text.labelSmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _weekCell(BuildContext context, int week, double t) {
    final colors = context.colors;
    final odd = week.isOdd;
    final v = odd
        ? AppMotion.interval(t, 0.12 + week * 0.018, 0.4 + week * 0.018)
        : 0.0;
    return Padding(
      padding: const EdgeInsets.all(2.5),
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Color.lerp(colors.surfaceMuted, colors.accent, v),
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Text(
            '$week',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color.lerp(colors.inkFaint, colors.onAccent, v),
            ),
          ),
        ),
      ),
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      alignment: Alignment.bottomRight,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9.5, color: colors.inkFaint),
      ),
    );
  }
}

/// 第三步：锁屏上滑入一条课程提醒，底部出现离线与提醒说明。
class ReminderIllustration extends StatelessWidget {
  const ReminderIllustration({required this.animation, super.key});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    return _Panel(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final t = animation.value;
          final notice = AppMotion.interval(t, 0.3, 0.75);
          final chips = AppMotion.interval(t, 0.58, 0.95);
          return Stack(
            children: [
              Positioned(
                top: 10,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    Text(
                      '09:50',
                      style: text.displaySmall?.copyWith(
                        fontSize: 46,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1,
                        height: 1.1,
                      ),
                    ),
                    Text('星期四 · 第 11 周', style: text.labelMedium),
                  ],
                ),
              ),
              Positioned(
                top: 112,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: notice,
                  child: Transform.translate(
                    offset: Offset(0, -18 * (1 - notice)),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.canvas,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Row(
                        children: [
                          const BrandMark(size: 32),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '示例课程甲 · 10 分钟后上课',
                                  style: text.labelMedium?.copyWith(
                                    color: colors.ink,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text('示例教室 A101', style: text.labelSmall),
                              ],
                            ),
                          ),
                          Text('现在', style: text.labelSmall),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                left: 0,
                right: 0,
                child: Opacity(
                  opacity: chips,
                  child: Transform.translate(
                    offset: Offset(0, 10 * (1 - chips)),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Chip(icon: AppIcons.offline, label: '离线可用'),
                        SizedBox(width: 8),
                        _Chip(icon: AppIcons.notifications, label: '提前提醒'),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colors.accent),
          ),
        ],
      ),
    );
  }
}

/// 最后一步：标志在同心细线中重新生长。
class ReadyIllustration extends StatelessWidget {
  const ReadyIllustration({required this.animation, super.key});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final markProgress = animation.drive(
      CurveTween(curve: const Interval(0.1, 0.8)),
    );

    return SizedBox.fromSize(
      size: _canvas + const Offset(28, 28),
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: animation,
            builder: (context, _) {
              final t = animation.value;
              return Stack(
                alignment: Alignment.center,
                children: [
                  for (var i = 2; i >= 0; i--)
                    Opacity(
                      opacity: AppMotion.interval(
                        t,
                        0.2 + i * 0.12,
                        0.6 + i * 0.12,
                      ),
                      child: Transform.scale(
                        scale:
                            0.85 +
                            0.15 *
                                AppMotion.interval(
                                  t,
                                  0.2 + i * 0.12,
                                  0.6 + i * 0.12,
                                ),
                        child: Container(
                          width: 150.0 + i * 52,
                          height: 150.0 + i * 52,
                          // 由外向内逐层加深的实心圆，代替描边圆环。
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: switch (i) {
                              0 => colors.accentSoft,
                              1 => colors.surfaceMuted,
                              _ => colors.surfaceMuted.withValues(alpha: 0.5),
                            },
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          BrandMark(size: 96, progress: markProgress),
        ],
      ),
    );
  }
}
