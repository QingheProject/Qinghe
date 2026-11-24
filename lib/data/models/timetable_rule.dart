import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/data/models/semester_config.dart';

/// 课程配色下标：由课程编号算出的稳定散列，同一门课在课表里颜色一致。
int courseColorIndex(String courseId) => courseId.codeUnits.fold(
  0,
  (hash, unit) => ((hash * 31) + unit) & 0x7fffffff,
);

class TimetableRule {
  TimetableRule({
    required this.id,
    required this.courseId,
    required this.name,
    required this.weekday,
    required List<int> weeks,
    required this.startPeriod,
    required this.endPeriod,
    this.location = '',
    this.teacher = '',
    this.type = 'regular',
    this.sourceNote = '',
  }) : weeks = List.unmodifiable(weeks.toSet().toList()..sort());

  final String id;
  final String courseId;
  final String name;
  final int weekday;
  final List<int> weeks;
  final int startPeriod;
  final int endPeriod;
  final String location;
  final String teacher;
  final String type;
  final String sourceNote;

  TimetableRule withCourseFrom(TimetableRule course) => TimetableRule(
    id: id,
    courseId: courseId,
    name: course.name,
    type: course.type,
    weekday: weekday,
    weeks: weeks,
    startPeriod: startPeriod,
    endPeriod: endPeriod,
    location: location,
    teacher: teacher,
    sourceNote: sourceNote,
  );

  void validateFor(SemesterConfig semester) {
    if (weeks.last > semester.weekCount) {
      throw FormatException('「$name」有超出学期范围的周次。');
    }
    if (endPeriod > semester.periodStartTimes.length) {
      throw FormatException('「$name」包含节次表中不存在的节次。');
    }
  }

  LessonOccurrence lessonFor(SemesterConfig semester, DateTime day) {
    final colorIndex = courseColorIndex(courseId);
    return LessonOccurrence(
      id: '${day.year}-${day.month}-${day.day}:$id',
      courseName: name,
      startPeriod: startPeriod,
      endPeriod: endPeriod,
      startMinute: semester.startMinute(startPeriod),
      endMinute:
          semester.startMinute(endPeriod) + semester.periodDurationMinutes,
      location: location,
      teacher: teacher,
      colorIndex: colorIndex,
      courseId: courseId,
      ruleId: id,
    );
  }

  Map<String, Object> toJson() => {
    'id': id,
    'weekday': weekday,
    'weeks': weeks,
    'startPeriod': startPeriod,
    'endPeriod': endPeriod,
    'location': location,
    'teacher': teacher,
    'sourceNote': sourceNote,
  };
}
