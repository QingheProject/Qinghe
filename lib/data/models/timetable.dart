import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/data/models/semester_config.dart';
import 'package:qinghe_app/data/models/teaching_week.dart';
import 'package:qinghe_app/data/models/timetable_rule.dart';

class Timetable {
  Timetable({
    required this.id,
    required this.config,
    required List<TimetableRule> rules,
  }) : rules = List.unmodifiable(rules);

  final String id;
  final SemesterConfig config;
  final List<TimetableRule> rules;

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
}
