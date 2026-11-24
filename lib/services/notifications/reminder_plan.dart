import 'package:qinghe_app/data/models/lesson_occurrence.dart';

/// 一条待发的上课提醒。
class CourseReminder {
  const CourseReminder({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
  });

  /// 通知编号，同一天同一节课始终相同，便于取消与覆盖。
  final int id;
  final DateTime when;
  final String title;
  final String body;
}

/// 提前多久提醒（分钟）。0 表示关闭。
const reminderLeadOptions = [0, 5, 10, 15, 30];

/// 最多排多久以内的提醒，避免一次排太多。
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
          body: _reminderBody(lesson, start),
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

/// 提醒编号：日期 + 起始节次，保证同一节课每次都是同一个编号。
int reminderIdFor(DateTime day, int startPeriod) {
  final dayKey = day.year * 10000 + day.month * 100 + day.day;
  return (dayKey * 100 + startPeriod) % 0x7fffffff;
}

String _reminderBody(LessonOccurrence lesson, DateTime start) {
  final time = '${_two(start.hour)}:${_two(start.minute)}';
  final periods = lesson.startPeriod == lesson.endPeriod
      ? '第 ${lesson.startPeriod} 节'
      : '第 ${lesson.startPeriod}–${lesson.endPeriod} 节';
  final location = lesson.location.trim();
  return location.isEmpty ? '$time · $periods' : '$time · $periods · $location';
}

String _two(int value) => value.toString().padLeft(2, '0');
