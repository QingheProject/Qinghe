import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/data/models/timetable_exam.dart';
import 'package:qinghe_app/features/home/widgets/lesson_sheet.dart';
import 'package:qinghe_app/features/schedule/controllers/schedule_controller.dart';
import 'package:qinghe_app/features/schedule/widgets/exam_sheet.dart';

const _weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

/// 日视图：横向日期轴（选日期）+ 竖向地铁线式时间线（当天安排）。
///
/// - 横向轴只负责选日期，滚动靠点击，不参与内容翻页。
/// - 内容区上下滚动，左侧一条贯穿的时间线，每个节点是一节课或一场考试。
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
  static const _axisItemWidth = 52.0;

  final ScrollController _axis = ScrollController();

  ScheduleController get _controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _centerAxisOnSelected(),
    );
  }

  @override
  void didUpdateWidget(ScheduleDayView oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _centerAxisOnSelected(),
    );
  }

  @override
  void dispose() {
    _axis.dispose();
    super.dispose();
  }

  /// 把选中的日期滚到轴中间。
  void _centerAxisOnSelected() {
    if (!_axis.hasClients) return;
    final page = _controller.displayedDatePage;
    final viewport = _axis.position.viewportDimension;
    final target = page * _axisItemWidth - (viewport - _axisItemWidth) / 2;
    final clamped = target.clamp(
      _axis.position.minScrollExtent,
      _axis.position.maxScrollExtent,
    );
    _axis.animateTo(
      clamped.toDouble(),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      key: const ValueKey('schedule-day-view'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 62,
          child: ListView.builder(
            key: const ValueKey('schedule-day-axis'),
            controller: _axis,
            scrollDirection: Axis.horizontal,
            itemExtent: _axisItemWidth,
            itemCount: _controller.dayPageCount,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            itemBuilder: (context, page) {
              final date = _controller.dateForPage(page);
              return _AxisDay(
                date: date,
                selected: date == _controller.displayedDate,
                isToday: date == _controller.today,
                hasLessons: _controller.lessonsOn(date).isNotEmpty,
                hasExam: _controller.examsOn(date).isNotEmpty,
                onTap: () => setState(() => _controller.selectDateOnly(date)),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Divider(height: 1, color: colors.line),
        ),
        Expanded(
          child: _DayTimeline(
            controller: _controller,
            colorScheme: widget.colorScheme,
            saturation: widget.saturation,
          ),
        ),
      ],
    );
  }
}

/// 日期轴上的一天。
class _AxisDay extends StatelessWidget {
  const _AxisDay({
    required this.date,
    required this.selected,
    required this.isToday,
    required this.hasLessons,
    required this.hasExam,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool isToday;
  final bool hasLessons;
  final bool hasExam;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final foreground = selected ? colors.onAccent : colors.ink;

    return Pressable(
      key: ValueKey('schedule-axis-${date.year}${date.month}${date.day}'),
      onTap: onTap,
      color: selected ? colors.accent : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      selected: selected,
      semanticLabel:
          '${date.month}月${date.day}日'
          '${isToday ? '，今天' : ''}'
          '${hasLessons ? '，有课' : ''}',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '周${_weekdayLabels[date.weekday - 1]}',
              style: text.labelSmall?.copyWith(
                color: selected
                    ? foreground.withValues(alpha: 0.86)
                    : colors.inkMuted,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${date.day}',
              style: text.titleMedium?.copyWith(
                color: foreground,
                height: 1,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              height: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isToday && !selected)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.accent,
                        shape: BoxShape.circle,
                      ),
                    )
                  else if (hasLessons || hasExam)
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: selected
                            ? foreground.withValues(alpha: 0.7)
                            : (hasExam ? colors.accent : colors.inkFaint),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 当天的时间线：竖向滚动，左侧一条贯穿的地铁线。
class _DayTimeline extends StatelessWidget {
  const _DayTimeline({
    required this.controller,
    required this.colorScheme,
    required this.saturation,
  });

  final ScheduleController controller;
  final CourseColorScheme colorScheme;
  final double saturation;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final date = controller.displayedDate;
    final lessons = [...controller.lessonsOn(date)]
      ..sort((left, right) => left.startMinute.compareTo(right.startMinute));
    final exams = controller.examsOn(date);

    if (lessons.isEmpty && exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.leaf, size: 28, color: colors.inkFaint),
            const SizedBox(height: AppSpace.sm),
            Text(
              date == controller.today ? '今天没有课' : '这天没有课',
              style: text.bodyMedium?.copyWith(color: colors.inkMuted),
            ),
          ],
        ),
      );
    }

    // 节点顺序：先按开课时间排课，再把当天的考试排在后面。
    final entries = <_TimelineEntryData>[
      for (final lesson in lessons)
        _TimelineEntryData(
          leading: _hm(lesson.startMinute),
          trailing: _hm(lesson.endMinute),
          accent: colors.line,
          dotColor: CoursePalette.of(
            context,
            lesson.colorIndex,
            colorScheme,
            saturation,
          ).foreground,
          child: _LessonCard(
            lesson: lesson,
            colorIndex: lesson.colorIndex,
            colorScheme: colorScheme,
            saturation: saturation,
          ),
        ),
      for (final exam in exams)
        _TimelineEntryData(
          leading: exam.hasTime ? exam.timeLabel.split('–').first : '待定',
          trailing: exam.hasTime ? exam.timeLabel.split('–').last : '',
          accent: colors.accent,
          dotColor: colors.accent,
          child: _ExamCard(
            exam: exam,
            colorIndex: controller.activeTimetable?.examColorIndex(exam) ?? 0,
            colorScheme: colorScheme,
            saturation: saturation,
          ),
        ),
    ];

    return ListView.builder(
      key: const ValueKey('schedule-day-timeline'),
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        16,
        MediaQuery.paddingOf(context).bottom + 96,
      ),
      itemCount: entries.length,
      itemBuilder: (context, index) => _MetroRow(
        data: entries[index],
        isFirst: index == 0,
        isLast: index == entries.length - 1,
      ),
    );
  }

  String _hm(int minuteOfDay) {
    final hour = (minuteOfDay ~/ 60).toString().padLeft(2, '0');
    final minute = (minuteOfDay % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _TimelineEntryData {
  const _TimelineEntryData({
    required this.leading,
    required this.trailing,
    required this.accent,
    required this.dotColor,
    required this.child,
  });

  final String leading;
  final String trailing;
  final Color accent;
  final Color dotColor;
  final Widget child;
}

/// 地铁线式的一行：左侧时间，中间线路与站点，右侧卡片。
class _MetroRow extends StatelessWidget {
  const _MetroRow({
    required this.data,
    required this.isFirst,
    required this.isLast,
  });

  final _TimelineEntryData data;
  final bool isFirst;
  final bool isLast;

  /// 时间列宽、列间距与线路所在的横向偏移。
  static const _timeWidth = 50.0;
  static const _gap = 10.0;
  static const _lineWidth = 14.0;
  static const _dotTop = 14.0;
  static const _lineLeft = _timeWidth + _gap + (_lineWidth - 2) / 2;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    return Stack(
      children: [
        // 贯穿整行的线路；首尾各自少画半截，看起来像起终点。
        Positioned(
          left: _lineLeft,
          top: isFirst ? _dotTop : 0,
          bottom: isLast ? _dotTop : 0,
          child: Container(width: 2, color: colors.line),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 时间刻度。
            SizedBox(
              width: _timeWidth,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      data.leading,
                      style: text.labelMedium?.copyWith(
                        color: colors.ink,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (data.trailing.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        data.trailing,
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
            const SizedBox(width: _gap),
            // 站点圆点。
            SizedBox(
              width: _lineWidth,
              child: Padding(
                padding: const EdgeInsets.only(top: _dotTop - 4),
                child: Center(
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: data.dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.canvas, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: _gap),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: data.child,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 时间线里的课程卡片。
class _LessonCard extends StatelessWidget {
  const _LessonCard({
    required this.lesson,
    required this.colorIndex,
    required this.colorScheme,
    required this.saturation,
  });

  final LessonOccurrence lesson;
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
      onTap: () =>
          showLessonDialog(context, lesson, originColor: tone.background),
      color: tone.background,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      semanticLabel: '${lesson.courseName}，$details',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lesson.courseName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: text.titleSmall?.copyWith(
                color: tone.foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
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

/// 时间线里的考试卡片。
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
      onTap: () => showExamDialog(
        context,
        exam,
        colorIndex: colorIndex,
        originColor: colors.accentSoft,
      ),
      color: colors.accentSoft,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      semanticLabel:
          '考试，${exam.courseName}${details.isEmpty ? '' : '，$details'}',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              const SizedBox(height: 4),
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
