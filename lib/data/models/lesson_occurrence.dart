enum LessonStatus { finished, ongoing, upcoming }

/// 某一天实际发生的一次课。时刻以当天零点起的分钟数表示。
class LessonOccurrence {
  const LessonOccurrence({
    required this.id,
    required this.courseName,
    required this.startPeriod,
    required this.endPeriod,
    required this.startMinute,
    required this.endMinute,
    this.location = '',
    this.teacher = '',
    this.colorIndex = 0,
  }) : assert(startPeriod <= endPeriod),
       assert(startMinute < endMinute);

  final String id;
  final String courseName;
  final int startPeriod;
  final int endPeriod;
  final int startMinute;
  final int endMinute;
  final String location;
  final String teacher;
  final int colorIndex;

  int get durationMinutes => endMinute - startMinute;

  /// 采用半开区间 [start, end)：结束时刻即视为已结束。
  LessonStatus statusAt(int minuteOfDay) {
    if (minuteOfDay >= endMinute) return LessonStatus.finished;
    if (minuteOfDay >= startMinute) return LessonStatus.ongoing;
    return LessonStatus.upcoming;
  }

  double progressAt(int minuteOfDay) =>
      ((minuteOfDay - startMinute) / durationMinutes).clamp(0.0, 1.0);
}

/// 选出当前应重点展示的课程：优先正在上的课，其次最近的下一节。
LessonOccurrence? pickFocusLesson(
  Iterable<LessonOccurrence> lessons,
  int minuteOfDay,
) {
  final sorted = lessons.toList()
    ..sort((a, b) => a.startMinute.compareTo(b.startMinute));
  for (final lesson in sorted) {
    if (lesson.statusAt(minuteOfDay) == LessonStatus.ongoing) return lesson;
  }
  for (final lesson in sorted) {
    if (lesson.statusAt(minuteOfDay) == LessonStatus.upcoming) return lesson;
  }
  return null;
}
