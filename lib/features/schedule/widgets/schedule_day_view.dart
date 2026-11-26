import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/data/models/timetable_exam.dart';
import 'package:qinghe_app/features/home/widgets/lesson_sheet.dart';
import 'package:qinghe_app/features/schedule/controllers/schedule_controller.dart';
import 'package:qinghe_app/features/schedule/widgets/exam_sheet.dart';

const _weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

/// 时间线里每一格（一节课或一场考试）的固定高度。
const _entryHeight = 84.0;

/// 一天的小标题高度；滑过这一段就由顶栏接管。
const _headerHeight = 34.0;

/// 两天之间的间距。
const _dayGap = 6.0;

/// 列表顶部内边距。滚动位置换算页码时要先减掉它。
const _listTopPadding = AppSpace.xs;

/// 没课的日子在标题下方留给说明文字的高度。
const _emptyHeight = 20.0;

/// 时间轴轨道所在列：左侧时间（[railTimeWidth]）之后、卡片之前。
const _railTimeWidth = 54.0;
const _railGap = 10.0;
const _railTrackWidth = 16.0;

/// 轨道中心相对区块左边的距离。有课的日子和时间线都按这个值对齐，
/// 保证空档的虚线与每一段的实线共线。
const _railCenter = _railTimeWidth + _railGap + _railTrackWidth / 2;

/// 日视图：一条覆盖整学期的竖向时间线 + 底部悬浮的横向日期轴。
///
/// - 每天一个小标题，有课的日子每节课一个站点，站点之间是实线；
///   没课的日子、周末以及两天的空隙都画虚线，且与有课日的轨道严格共线。
/// - 滚动时当前这一天的小标题会向上淡出并交给顶栏，日期轴同步高亮。
class ScheduleDayView extends StatefulWidget {
  const ScheduleDayView({
    required this.controller,
    required this.colorScheme,
    required this.saturation,
    super.key,
  });

  final ScheduleController controller;
  final CourseColorScheme colorScheme;
  final double saturation;

  @override
  State<ScheduleDayView> createState() => _ScheduleDayViewState();
}

class _ScheduleDayViewState extends State<ScheduleDayView> {
  final ScrollController _list = ScrollController();

  late List<double> _heights;
  late List<double> _offsets;

  /// 上一次计算布局时的课表与天数；不变就不重算。
  Object? _layoutKey;
  late int _activePage;

  /// 0 = 当天标题还在列表里，1 = 已经完全由顶栏接管。
  /// 用 ValueNotifier 驱动，滚动时只重绘飞行标题，不重建整条时间线。
  final ValueNotifier<double> _flight = ValueNotifier<double>(0);

  /// 点击日期轴、回到今天等程序化滚动期间忽略滚动回调。
  bool _syncing = false;

  /// 首帧内容还没测量出滚动范围时，跳转会被夹到 0；用有限的几帧重试。
  static const _maxRetries = 6;
  int _jumpRetries = 0;

  ScheduleController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    _activePage = _controller.displayedDatePage;
    _ensureLayout();
    _list.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToPage(_activePage, animate: false);
    });
  }

  @override
  void didUpdateWidget(ScheduleDayView oldWidget) {
    super.didUpdateWidget(oldWidget);
    final previous = _heights;
    final hadLayout = _layoutKey != null;
    _ensureLayout();
    final layoutChanged =
        hadLayout &&
        (previous.length != _heights.length ||
            !_sameHeights(previous, _heights));
    final target = _controller.displayedDatePage;
    if (target != _activePage && !_syncing) {
      _activePage = target;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _jumpToPage(target);
      });
    } else if (layoutChanged && !_syncing) {
      // 课表刚加载完（或导入更新）时每天的高度会变，按控制器里的选中日期
      // 重新对齐滚动位置；不能用旧的页码，否则会落到别的日子。
      final page = _controller.displayedDatePage;
      _activePage = page;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _jumpToPage(page, animate: false);
      });
    }
  }

  static bool _sameHeights(List<double> left, List<double> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if ((left[index] - right[index]).abs() > 0.01) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _list.removeListener(_onScroll);
    _list.dispose();
    _flight.dispose();
    super.dispose();
  }

  int _entryCount(int page) {
    final date = _controller.dateForPage(page);
    return _controller.lessonsOn(date).length +
        _controller.examsOn(date).length;
  }

  double _heightFor(int page) {
    final count = _entryCount(page);
    return _headerHeight +
        (count == 0 ? _emptyHeight : count * _entryHeight) +
        _dayGap;
  }

  /// 课表或天数没变时复用上一次的高度表。
  void _ensureLayout() {
    final key = (_controller.activeTimetable, _controller.dayPageCount);
    if (_layoutKey == key) return;
    _layoutKey = key;
    _rebuildLayout();
  }

  void _rebuildLayout() {
    final count = _controller.dayPageCount;
    _heights = List<double>.filled(count, 0);
    _offsets = List<double>.filled(count, 0);
    var offset = 0.0;
    for (var page = 0; page < count; page++) {
      _heights[page] = _heightFor(page);
      _offsets[page] = offset;
      offset += _heights[page];
    }
  }

  int _pageAtOffset(double offset) {
    var low = 0;
    var high = _offsets.length - 1;
    while (low < high) {
      final mid = (low + high + 1) ~/ 2;
      if (_offsets[mid] <= offset + 1) {
        low = mid;
      } else {
        high = mid - 1;
      }
    }
    return low;
  }

  void _onScroll() {
    if (_syncing || !_list.hasClients || _offsets.isEmpty) return;
    final offset = _list.offset - _listTopPadding;
    final page = _pageAtOffset(offset);
    final local = (offset - _offsets[page]).clamp(0.0, _headerHeight);
    final progress = (local / _headerHeight).clamp(0.0, 1.0);
    if ((progress - _flight.value).abs() >= 0.005) {
      _flight.value = progress;
      _controller.dayTitleFlight.value = progress;
    }
    // 只有换成另一天才重建列表；滚动过程中的进度交给 ValueNotifier。
    if (page != _activePage) {
      _activePage = page;
      _controller.selectDateOnly(_controller.dateForPage(page));
      setState(() {});
    }
  }

  void _jumpToPage(int page, {bool animate = true}) {
    if (page < 0 || page >= _offsets.length) return;
    // 内容尚未测量（第一帧或视图切换中）时滚动范围还是 0，直接跳会落到开头。
    final ready =
        _list.hasClients &&
        _list.position.hasContentDimensions &&
        _list.position.maxScrollExtent > 0;
    if (!ready) {
      if (_jumpRetries++ < _maxRetries) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _jumpToPage(page, animate: false);
        });
      }
      return;
    }
    _jumpRetries = 0;
    // 区块起点正好贴住视口顶部（偏移里已经包含列表内边距）。
    final target = (_offsets[page] + _listTopPadding).clamp(
      _list.position.minScrollExtent,
      _list.position.maxScrollExtent,
    );
    _syncing = true;
    _flight.value = 0;
    _controller.dayTitleFlight.value = 0;
    _controller.dayTitleFlight.value = 0;
    if (animate) {
      _list
          .animateTo(
            target.toDouble(),
            duration: AppMotion.of(context, AppMotion.medium),
            curve: AppMotion.emphasized,
          )
          .whenComplete(() {
            if (!mounted) return;
            _syncing = false;
            // 以落点为准回读一次，保证顶栏日期与列表位置一致。
            _onScroll();
          });
    } else {
      _list.jumpTo(target.toDouble());
      _syncing = false;
      _onScroll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = _controller.dayPageCount;
    // Scaffold 的 extendBody 已经把底栏高度算进 MediaQuery.padding.bottom，
    // 再用 AppTabBar.occupiedHeight 会重复计算，日期轴会被顶得过高。
    final bottomBar = MediaQuery.paddingOf(context).bottom;
    final flyingDate = _controller.dateForPage(_activePage);

    return Stack(
      key: const ValueKey('schedule-day-view'),
      // 小标题要飞出内容区落进顶栏，这里也不能裁切。
      clipBehavior: Clip.none,
      children: [
        ListView.builder(
          key: const ValueKey('schedule-day-list'),
          controller: _list,
          padding: EdgeInsets.only(
            top: _listTopPadding,
            bottom: bottomBar + 24,
          ),
          itemCount: count,
          itemBuilder: (context, page) {
            final pageDate = _controller.dateForPage(page);
            // 每天一块重绘边界：滚动时相邻的日期不会一起重绘。
            return RepaintBoundary(
              child: SizedBox(
                height: _heights[page],
                child: _DaySection(
                  key: ValueKey(
                    'schedule-day-section-'
                    '${pageDate.year}${pageDate.month}${pageDate.day}',
                  ),
                  date: pageDate,
                  controller: _controller,
                  colorScheme: widget.colorScheme,
                  saturation: widget.saturation,
                  isToday: pageDate == _controller.today,
                  isWeekend:
                      pageDate.weekday >= DateTime.saturday ||
                      pageDate.weekday == DateTime.sunday,
                  flight: page == _activePage ? _flight : null,
                  isLastPage: page == count - 1,
                ),
              ),
            );
          },
        ),
        // 顶部虚化：只用渐变淡出，不用整宽模糊（模糊层在滚动时非常耗性能）。
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 14,
          child: IgnorePointer(
            child: DecoratedBox(
              key: const ValueKey('schedule-day-top-scrim'),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.colors.canvas.withValues(alpha: 0.94),
                    context.colors.canvas.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        // 底部虚化：内容滚到日期轴与底栏后面时逐渐淡出。
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          height: bottomBar + 40,
          child: IgnorePointer(
            child: DecoratedBox(
              key: const ValueKey('schedule-day-bottom-scrim'),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    context.colors.canvas.withValues(alpha: 0),
                    context.colors.canvas.withValues(alpha: 0.94),
                  ],
                ),
              ),
            ),
          ),
        ),
        // 飞向顶栏的小标题：画在列表与虚化之上，全程不透明地移动放大。
        Positioned(
          left: 20,
          // 与列表里日期文字的位置对齐（区块贴住视口顶部时，标题内边距 4）。
          top: 4,
          right: 20,
          child: ValueListenableBuilder<double>(
            valueListenable: _flight,
            builder: (context, progress, _) {
              if (progress <= 0 || progress >= 1) {
                return const SizedBox.shrink();
              }
              return IgnorePointer(
                key: const ValueKey('schedule-flying-title'),
                child: _FlyingTitle(
                  date: flyingDate,
                  isWeekend:
                      flyingDate.weekday == DateTime.saturday ||
                      flyingDate.weekday == DateTime.sunday,
                  progress: progress,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TodayChip extends StatelessWidget {
  const _TodayChip();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.accentSoft,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Text(
        '今天',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: colors.accent,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// 一天：小标题 + 一条连续的时间轴。
///
/// 轨道从区块顶部一直画到底部，缺口（两节课之间、没课的天、周末）用虚线，
/// 站点覆盖的位置用实线，所以虚线永远与实线共线。
class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.date,
    required this.controller,
    required this.colorScheme,
    required this.saturation,
    required this.isToday,
    required this.isWeekend,
    required this.flight,
    required this.isLastPage,
    super.key,
  });

  final DateTime date;
  final ScheduleController controller;
  final CourseColorScheme colorScheme;
  final double saturation;
  final bool isToday;
  final bool isWeekend;

  /// 当前页才有飞行进度；其余页为 null，标题保持原位。
  final ValueListenable<double>? flight;
  final bool isLastPage;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final lessons = [...controller.lessonsOn(date)]
      ..sort((left, right) => left.startMinute.compareTo(right.startMinute));
    final exams = controller.examsOn(date);
    final entries = lessons.length + exams.length;
    final hasClass = entries > 0;
    final total =
        _headerHeight +
        (hasClass ? entries * _entryHeight : _emptyHeight) +
        _dayGap;

    return SizedBox(
      height: total,
      child: Stack(
        // 小标题要向上飞出这个区块，不能在这里被裁掉。
        clipBehavior: Clip.none,
        children: [
          // 轨道：整段连接线，缺口处为虚线。
          Positioned(
            left: _railCenter - _railTrackWidth / 2,
            top: 0,
            bottom: 0,
            width: _railTrackWidth,
            child: CustomPaint(
              key: ValueKey(
                'schedule-day-track-${date.year}${date.month}${date.day}',
              ),
              painter: _RailPainter(
                color: hasClass
                    ? colors.line
                    : colors.line.withValues(alpha: 0.72),
                start: _headerHeight + _entryHeight / 2,
                unit: _entryHeight,
                count: entries,
                // 最后一天不再向下延续。
                end: isLastPage && !hasClass ? _headerHeight : null,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DayTitle(
                date: date,
                isToday: isToday,
                isWeekend: isWeekend,
                entryCount: entries,
                flight: flight,
              ),
              for (final lesson in lessons)
                SizedBox(
                  height: _entryHeight,
                  child: _EntryRow(
                    leading: _hm(lesson.startMinute),
                    trailing: _hm(lesson.endMinute),
                    dotColor: CoursePalette.of(
                      context,
                      lesson.colorIndex,
                      colorScheme,
                      saturation,
                    ).foreground,
                    child: _LessonCard(
                      lesson: lesson,
                      date: date,
                      colorIndex: lesson.colorIndex,
                      colorScheme: colorScheme,
                      saturation: saturation,
                    ),
                  ),
                ),
              for (final exam in exams)
                SizedBox(
                  height: _entryHeight,
                  child: _EntryRow(
                    leading: exam.hasTime
                        ? exam.timeLabel.split('–').first
                        : '待定',
                    trailing: exam.hasTime
                        ? exam.timeLabel.split('–').last
                        : '',
                    dotColor: colors.accent,
                    child: _ExamCard(
                      exam: exam,
                      colorIndex:
                          controller.activeTimetable?.examColorIndex(exam) ?? 0,
                      colorScheme: colorScheme,
                      saturation: saturation,
                    ),
                  ),
                ),
            ],
          ),
          // 没课 / 周末：轨道已是虚线，这里补一句说明，且不参与列高计算。
          if (!hasClass)
            Positioned(
              left: _railCenter + 12,
              top: _headerHeight - 4,
              right: 20,
              child: IgnorePointer(
                child: Text(
                  isWeekend ? '周末 · 没有课' : '这天没有课',
                  key: const ValueKey('schedule-day-empty'),
                  style: text.bodySmall?.copyWith(color: colors.inkFaint),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _hm(int minuteOfDay) {
    final hour = (minuteOfDay ~/ 60).toString().padLeft(2, '0');
    final minute = (minuteOfDay % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _DayTitle extends StatelessWidget {
  const _DayTitle({
    required this.date,
    required this.isToday,
    required this.isWeekend,
    required this.entryCount,
    required this.flight,
  });

  final DateTime date;
  final bool isToday;
  final bool isWeekend;
  final int entryCount;
  final ValueListenable<double>? flight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final dateText = Text(
      '${date.month}月${date.day}日',
      key: const ValueKey('schedule-day-title'),
      style: text.titleSmall?.copyWith(
        color: isWeekend && !isToday ? colors.inkMuted : colors.ink,
        fontWeight: FontWeight.w700,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );

    return SizedBox(
      height: _headerHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
        child: Row(
          key: const ValueKey('schedule-day-title-shell'),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 飞向顶栏时原位置的日期先藏起来（由叠加层接住）；
            // 旁边的星期和数量留在原地随列表滚走。
            if (flight case final listenable?)
              ValueListenableBuilder<double>(
                valueListenable: listenable,
                child: dateText,
                builder: (context, progress, child) => Opacity(
                  // 前三分之一段淡出，避免日期瞬间消失显得生硬。
                  opacity: (1 - progress / 0.35).clamp(0.0, 1.0),
                  child: child,
                ),
              )
            else
              dateText,
            const SizedBox(width: 6),
            Text(
              '周${_weekdayLabels[date.weekday - 1]}',
              style: text.labelSmall?.copyWith(color: colors.inkMuted),
            ),
            if (isToday) ...[const SizedBox(width: 6), const _TodayChip()],
            const Spacer(),
            Text(
              entryCount == 0 ? '空闲' : '$entryCount 项安排',
              style: text.labelSmall?.copyWith(color: colors.inkFaint),
            ),
          ],
        ),
      ),
    );
  }
}

/// 飞向顶栏的小标题：随滚动上移、放大，全程保持不透明；
/// 往回滚动时进度减小，同一段动画自然倒放。
class _FlyingTitle extends StatelessWidget {
  const _FlyingTitle({
    required this.date,
    required this.isWeekend,
    required this.progress,
  });

  final DateTime date;
  final bool isWeekend;
  final double progress;

  /// 小标题从列表第一行（top = 4）飞到这里：略高于内容区顶部，
  /// 正好落在大标题日期所在的位置。
  static const _rise = _headerHeight + 12.0;

  /// 顶栏日期比列表小标题大一号，收尾时放大到同样大小。
  static const _endScale = 1.36;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final t = AppMotion.emphasized.transform(progress.clamp(0.0, 1.0));

    return Transform.translate(
      // 向左并入顶栏日期（顶栏左侧内边距比列表少 8）。
      offset: Offset(-8 * t, -_rise * t),
      child: Transform.scale(
        scale: 1 + (_endScale - 1) * t,
        alignment: Alignment.topLeft,
        // 只飞日期本身：旁边的「周x」留在列表里，不跟着走。
        child: Text(
          '${date.month}月${date.day}日',
          key: const ValueKey('schedule-flying-date'),
          style: text.titleSmall?.copyWith(
            color: isWeekend ? colors.inkMuted : colors.ink,
            fontWeight: FontWeight.w700,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}

/// 一行：左侧时间、中间轨道上的站点、右侧卡片。
class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.leading,
    required this.trailing,
    required this.dotColor,
    required this.child,
  });

  final String leading;
  final String trailing;
  final Color dotColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: _railTimeWidth,
          child: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  leading,
                  style: text.labelMedium?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (trailing.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    trailing,
                    style: text.labelSmall?.copyWith(
                      color: colors.inkFaint,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: _railGap),
        SizedBox(
          width: _railTrackWidth,
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: _entryHeight / 2 - 6),
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.canvas, width: 2),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: _railGap),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 20, top: 6, bottom: 6),
            child: child,
          ),
        ),
      ],
    );
  }
}

/// 轨道画笔：从 [start] 起按 [unit] 间距画站点，站点之间是实线；
/// 其余部分（开头、结尾、没课的天）画虚线。
class _RailPainter extends CustomPainter {
  const _RailPainter({
    required this.color,
    required this.start,
    required this.unit,
    required this.count,
    this.end,
  }) : assert(count >= 0);

  final Color color;

  /// 第一个站点中心相对区块顶部的位置。
  final double start;

  /// 相邻站点的间距。
  final double unit;

  /// 站点数量。
  final int count;

  /// 轨道在距顶部多远结束；为 null 时画到底。
  final double? end;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final bottom = end ?? size.height;
    if (bottom <= 0) return;

    if (count == 0) {
      _dashed(canvas, x, 0, bottom);
      return;
    }

    final firstTop = start - unit / 2;
    final lastBottom = start + (count - 1) * unit + unit / 2;

    // 开头到第一个站点之间。
    if (firstTop > 0) _dashed(canvas, x, 0, math.min(firstTop, bottom));
    // 站点之间是连续实线。
    final solidStart = math.max(firstTop, 0.0);
    final solidEnd = math.min(lastBottom, bottom);
    if (solidEnd > solidStart) {
      canvas.drawLine(
        Offset(x, solidStart),
        Offset(x, solidEnd),
        Paint()
          ..color = color
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
    // 最后一个站点之后，直到下一天或本区块底部。
    if (lastBottom < bottom) _dashed(canvas, x, lastBottom, bottom);
  }

  void _dashed(Canvas canvas, double x, double from, double to) {
    if (to <= from) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    const dash = 4.0;
    const gap = 5.0;
    var y = from;
    while (y < to) {
      canvas.drawLine(Offset(x, y), Offset(x, math.min(y + dash, to)), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_RailPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.start != start ||
      oldDelegate.unit != unit ||
      oldDelegate.count != count ||
      oldDelegate.end != end;
}

class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.date,
    required this.colorIndex,
    required this.colorScheme,
    required this.saturation,
  });

  final LessonOccurrence lesson;
  final DateTime date;
  final int colorIndex;
  final CourseColorScheme colorScheme;
  final double saturation;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final tone = CoursePalette.of(context, colorIndex, colorScheme, saturation);
    final periods = lesson.startPeriod == lesson.endPeriod
        ? '第 ${lesson.startPeriod} 节'
        : '第 ${lesson.startPeriod}–${lesson.endPeriod} 节';
    final details = [
      periods,
      if (lesson.location.trim().isNotEmpty) lesson.location.trim(),
      if (lesson.teacher.trim().isNotEmpty) lesson.teacher.trim(),
    ].join(' · ');

    return Pressable(
      key: ValueKey('schedule-day-lesson-${lesson.id}'),
      onTap: () => showLessonDialog(context, lesson, date: date),
      color: tone.background,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      semanticLabel: '${lesson.courseName}，$details',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              lesson.courseName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.titleSmall?.copyWith(
                color: tone.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              details,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(
                color: tone.foreground.withValues(alpha: 0.78),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ExamCard extends StatelessWidget {
  const _ExamCard({
    required this.exam,
    required this.colorIndex,
    required this.colorScheme,
    required this.saturation,
  });

  final TimetableExam exam;
  final int colorIndex;
  final CourseColorScheme colorScheme;
  final double saturation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final details = [
      if (exam.location.trim().isNotEmpty) exam.location.trim(),
      if (exam.seat.trim().isNotEmpty) '座位 ${exam.seat.trim()}',
    ].join(' · ');

    return Pressable(
      key: ValueKey('schedule-day-exam-${exam.id}'),
      onTap: () => showExamDialog(context, exam, colorIndex: colorIndex),
      color: colors.accentSoft,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      semanticLabel:
          '考试，${exam.courseName}${details.isEmpty ? '' : '，$details'}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(AppIcons.calendarCheck, size: 14, color: colors.accent),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '考试 · ${exam.courseName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.titleSmall?.copyWith(
                      color: colors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                details,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(color: colors.inkMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
