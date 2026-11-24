import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/data/models/semester_config.dart';
import 'package:qinghe_app/data/models/teaching_week.dart';
import 'package:qinghe_app/data/models/timetable_exam.dart';
import 'package:qinghe_app/data/models/timetable_rule.dart';

class Timetable {
  Timetable({
    required this.id,
    required this.config,
    required List<TimetableRule> rules,
    List<TimetableExam> exams = const [],
  }) : rules = List.unmodifiable(rules),
       exams = List.unmodifiable(_sorted(exams));

  final String id;
  final SemesterConfig config;
  final List<TimetableRule> rules;

  /// 本学期的考试安排，按日期与时间排序。
  final List<TimetableExam> exams;

  static List<TimetableExam> _sorted(List<TimetableExam> exams) =>
      exams.toList()..sort((left, right) {
        final byDay = left.day.compareTo(right.day);
        if (byDay != 0) return byDay;
        return (left.startMinute ?? 0).compareTo(right.startMinute ?? 0);
      });

  int? teachingWeekOn(DateTime day) =>
      teachingWeekOf(day, config.week1Monday, weekCount: config.weekCount);

  List<LessonOccurrence> lessonsOn(DateTime day) {
    final week = teachingWeekOn(day);
    if (week == null) return const [];
    return [
      for (final rule in rules)
        if (rule.weekday == day.weekday && rule.weeks.contains(week))
          rule.lessonFor(config, day),
    ]..sort((left, right) => left.startMinute.compareTo(right.startMinute));
  }

  List<TimetableExam> examsOn(DateTime day) => [
    for (final exam in exams)
      if (exam.occursOn(day)) exam,
  ];

  /// 从 [from] 起最近的考试，用于首页与进度卡提示。
  TimetableExam? nextExamOn(DateTime from) {
    final today = DateTime(from.year, from.month, from.day);
    for (final exam in exams) {
      if (!exam.day.isBefore(today)) return exam;
    }
    return null;
  }

  /// 考试卡片的配色下标。
  ///
  /// 同一门课已经有上课安排时沿用那门课的颜色，考试卡与课程卡就成一家人；
  /// 找不到对应课程时用课程名算一个稳定颜色。
  int examColorIndex(TimetableExam exam) {
    for (final rule in rules) {
      if (rule.name == exam.courseName) return courseColorIndex(rule.courseId);
    }
    return courseColorIndex('exam|${exam.courseName}');
  }

  /// 考试在课表网格里的位置，单位是「节」。
  ///
  /// 直接按考试的起止时间换算到时间轴上：落在一节中间就从那一节的中段开始，
  /// 课间空档按上一节的下边缘处理。这样占用几格由时间算出来，
  /// 而不是用「时长 ÷ 每节时长」估算——节次之间有课间，那种算法会多占格子。
  ({double top, double height})? examLayout(TimetableExam exam) {
    final start = exam.startMinute;
    if (start == null) return null;
    final top = offsetInRows(start);
    if (top == null) return null;
    final bottom =
        offsetInRows(exam.endMinute ?? start + exam.durationMinutes) ?? top;
    final available = config.periodStartTimes.length - top;
    return (
      top: top,
      // 太短的考试也要留出能点到的一条，最长不超过网格剩余部分。
      height: (bottom - top).clamp(0.35, available < 0.35 ? 0.35 : available),
    );
  }

  /// 把一天中的分钟数换算成网格里从顶部算起的行偏移。
  ///
  /// 第 i 节覆盖 `[开始, 开始+每节时长]`；落在课间时贴到下一节的上边缘。
  double? offsetInRows(int minute) {
    final starts = <int>[];
    for (final time in config.periodStartTimes) {
      final value = SemesterConfig.parseMinute(time);
      if (value == null) return null;
      starts.add(value);
    }
    if (starts.isEmpty) return null;
    final duration = config.periodDurationMinutes;
    if (minute <= starts.first) return 0;
    for (var index = 0; index < starts.length; index++) {
      final end = starts[index] + duration;
      if (minute < starts[index]) return index.toDouble();
      if (minute <= end) return index + (minute - starts[index]) / duration;
    }
    return starts.length.toDouble();
  }
}
