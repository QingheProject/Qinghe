import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/services/notifications/reminder_plan.dart';

LessonOccurrence _lesson({
  required String name,
  required int startMinute,
  int duration = 45,
  int startPeriod = 1,
  int endPeriod = 2,
  String location = '',
}) => LessonOccurrence(
  id: '$name-$startMinute',
  courseName: name,
  startPeriod: startPeriod,
  endPeriod: endPeriod,
  startMinute: startMinute,
  endMinute: startMinute + duration,
  location: location,
);

void main() {
  final now = DateTime(2026, 11, 24, 9, 0); // 周二 09:00
  final today = DateTime(2026, 11, 24);

  group('上课提醒排期', () {
    test('按提前分钟数算出提醒时间，并带时间、节次与地点', () {
      final reminders = planCourseReminders(
        now: now,
        leadMinutes: 15,
        days: [
          (
            today,
            [_lesson(name: '示例课程甲', startMinute: 10 * 60, location: '示例教室')],
          ),
        ],
      );

      expect(reminders, hasLength(1));
      final reminder = reminders.single;
      expect(reminder.when, DateTime(2026, 11, 24, 9, 45));
      expect(reminder.title, '示例课程甲 即将开始');
      expect(reminder.body, '10:00 · 第 1–2 节 · 示例教室');
    });

    test('关闭提醒（0 分钟）时一条都不排', () {
      final reminders = planCourseReminders(
        now: now,
        leadMinutes: 0,
        days: [
          (today, [_lesson(name: '示例课程甲', startMinute: 10 * 60)]),
        ],
      );
      expect(reminders, isEmpty);
    });

    test('已经开始或提醒时间已过的课不排', () {
      final reminders = planCourseReminders(
        now: now,
        leadMinutes: 15,
        days: [
          (
            today,
            [
              // 08:30 的课已经上过了。
              _lesson(name: '早上第一节', startMinute: 8 * 60 + 30),
              // 09:10 的课，提前 15 分钟即 08:55，也已经过了。
              _lesson(name: '马上开始', startMinute: 9 * 60 + 10),
              // 09:20 的课，提前 15 分钟是 09:05，还没到。
              _lesson(name: '稍后一节课', startMinute: 9 * 60 + 20),
            ],
          ),
        ],
      );
      expect(reminders.map((item) => item.title), ['稍后一节课 即将开始']);
    });

    test('超出天数的课不排，且结果按时间升序', () {
      final reminders = planCourseReminders(
        now: now,
        leadMinutes: 10,
        horizonDays: 2,
        days: [
          (
            today.add(const Duration(days: 2)),
            [_lesson(name: '后天课程', startMinute: 8 * 60)],
          ),
          (
            today.add(const Duration(days: 1)),
            [
              _lesson(name: '明天下午', startMinute: 14 * 60),
              _lesson(name: '明天上午', startMinute: 8 * 60),
            ],
          ),
          (today, [_lesson(name: '今天下午', startMinute: 14 * 60)]),
        ],
      );

      expect(reminders.map((item) => item.title), [
        '今天下午 即将开始',
        '明天上午 即将开始',
        '明天下午 即将开始',
      ]);
      expect(
        reminders.every(
          (item) => item.when.isBefore(now.add(const Duration(days: 2))),
        ),
        isTrue,
      );
    });

    test('同一节课的提醒编号稳定，不同日期或节次则不同', () {
      expect(reminderIdFor(today, 1), reminderIdFor(today, 1));
      expect(
        reminderIdFor(today, 1),
        isNot(reminderIdFor(today.add(const Duration(days: 1)), 1)),
      );
      expect(reminderIdFor(today, 1), isNot(reminderIdFor(today, 2)));
    });

    test('超过上限时只保留最近的若干条', () {
      final lessons = [
        for (var index = 0; index < 10; index++)
          _lesson(
            name: '课程$index',
            startMinute: 10 * 60 + index * 10,
            startPeriod: index + 1,
            endPeriod: index + 1,
          ),
      ];
      final reminders = planCourseReminders(
        now: now,
        leadMinutes: 5,
        days: [(today, lessons)],
        maxCount: 3,
      );
      expect(reminders, hasLength(3));
      expect(reminders.first.title, '课程0 即将开始');
    });

    test('单节课只显示一个节次', () {
      final reminders = planCourseReminders(
        now: now,
        leadMinutes: 15,
        days: [
          (
            today,
            [
              _lesson(
                name: '单节课程',
                startMinute: 10 * 60,
                startPeriod: 3,
                endPeriod: 3,
              ),
            ],
          ),
        ],
      );
      expect(reminders.single.body, '10:00 · 第 3 节');
    });
  });
}
