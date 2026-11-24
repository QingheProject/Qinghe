import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/data/models/timetable_exam.dart';

/// 一条待发的提醒（上课或考试）。
class CourseReminder {
  const CourseReminder({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
  });

  /// 通知编号，同一场课/考试始终相同，便于取消与覆盖。
  final int id;
  final DateTime when;
  final String title;
  final String body;
}

/// 最多排多久以内的上课提醒，避免一次排太多。
const reminderHorizonDays = 14;

/// 最多同时排多少条提醒。
const reminderMaxCount = 64;

/// 把「某几天各有哪些课」摊平成一串上课提醒。
///
/// 纯计算，不碰通知插件，方便单测：已经开始的课不排、超出天数的课不排、
/// 结果按时间升序，超过上限时保留最近的若干条。
List<CourseReminder> planCourseReminders({
  required DateTime now,
  required int leadMinutes,
  required Iterable<(DateTime, List<LessonOccurrence>)> days,
  int horizonDays = reminderHorizonDays,
  int maxCount = reminderMaxCount,
}) {
  if (leadMinutes <= 0) return const [];

  final today = DateTime(now.year, now.month, now.day);
  final lastDay = today.add(Duration(days: horizonDays - 1));
  final reminders = <CourseReminder>[];

  for (final (date, lessons) in days) {
    final day = DateTime(date.year, date.month, date.day);
    if (day.isBefore(today) || day.isAfter(lastDay)) continue;
    for (final lesson in lessons) {
      final start = day.add(Duration(minutes: lesson.startMinute));
      if (!start.isAfter(now)) continue;
      final when = start.subtract(Duration(minutes: leadMinutes));
      if (!when.isAfter(now)) continue;
      reminders.add(
        CourseReminder(
          id: reminderIdFor(day, lesson.startPeriod),
          when: when,
          title: '${lesson.courseName} 即将开始',
          body: _lessonBody(lesson, start),
        ),
      );
    }
  }

  reminders.sort((left, right) => left.when.compareTo(right.when));
  if (reminders.length > maxCount) {
    return reminders.sublist(0, maxCount);
  }
  return reminders;
}

/// 把考试摊平成一串考前提醒；没有具体时间的考试不排。
List<CourseReminder> planExamReminders({
  required DateTime now,
  required int leadMinutes,
  required Iterable<TimetableExam> exams,
  int maxCount = reminderMaxCount,
}) {
  if (leadMinutes <= 0) return const [];

  final reminders = <CourseReminder>[];
  for (final exam in exams) {
    final startMinute = exam.startMinute;
    if (startMinute == null) continue;
    final start = DateTime(
      exam.date.year,
      exam.date.month,
      exam.date.day,
    ).add(Duration(minutes: startMinute));
    if (!start.isAfter(now)) continue;
    final when = start.subtract(Duration(minutes: leadMinutes));
    if (!when.isAfter(now)) continue;
    reminders.add(
      CourseReminder(
        id: examReminderIdFor(exam.date, exam.id),
        when: when,
        title: '${exam.courseName} 考试即将开始',
        body: _examBody(exam, start),
      ),
    );
  }

  reminders.sort((left, right) => left.when.compareTo(right.when));
  if (reminders.length > maxCount) {
    return reminders.sublist(0, maxCount);
  }
  return reminders;
}

/// 上课提醒编号：日期 + 起始节次，保证同一节课每次都是同一个编号。
int reminderIdFor(DateTime day, int startPeriod) {
  final dayKey = day.year * 10000 + day.month * 100 + day.day;
  return (dayKey * 100 + startPeriod) % 0x7fffffff;
}

/// 考试提醒编号：日期 + 考试编号的哈希，避开上课提醒的编号区间。
int examReminderIdFor(DateTime day, String examId) {
  final dayKey = day.year * 10000 + day.month * 100 + day.day;
  var hash = 0x811c9dc5;
  for (final unit in examId.codeUnits) {
    hash = (hash ^ unit) * 0x01000193 & 0xffffffff;
  }
  return (0x40000000 + (hash ^ dayKey) % 0x10000000) & 0x7fffffff;
}

String _lessonBody(LessonOccurrence lesson, DateTime start) {
  final time = _hm(start);
  final periods = lesson.startPeriod == lesson.endPeriod
      ? '第 ${lesson.startPeriod} 节'
      : '第 ${lesson.startPeriod}–${lesson.endPeriod} 节';
  final location = lesson.location.trim();
  return location.isEmpty ? '$time · $periods' : '$time · $periods · $location';
}

String _examBody(TimetableExam exam, DateTime start) {
  final parts = <String>[_hm(start)];
  final location = exam.location.trim();
  if (location.isNotEmpty) parts.add(location);
  final seat = exam.seat.trim();
  if (seat.isNotEmpty) parts.add('座位 $seat');
  return parts.join(' · ');
}

String _hm(DateTime time) =>
    '${time.hour.toString().padLeft(2, '0')}:'
    '${time.minute.toString().padLeft(2, '0')}';
