import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/data/models/semester_config.dart';
import 'package:qinghe_app/data/models/timetable.dart';
import 'package:qinghe_app/data/models/timetable_exam.dart';
import 'package:qinghe_app/data/models/timetable_rule.dart';

SemesterConfig _config() => SemesterConfig(
  name: '测试学期',
  week1Monday: DateTime(2026, 9, 7),
  weekCount: 18,
  periodStartTimes: const ['08:00', '08:55', '10:00', '10:55'],
  periodDurationMinutes: 45,
);

TimetableExam _exam({
  String id = 'E1',
  String name = '示例课程',
  DateTime? date,
  int? start,
  int? end,
  String location = '',
}) => TimetableExam(
  id: id,
  courseName: name,
  date: date ?? DateTime(2026, 11, 25),
  startMinute: start,
  endMinute: end,
  location: location,
);

void main() {
  test('按日期与时间排序，并按天取出考试', () {
    final table = Timetable(
      id: 't1',
      config: _config(),
      rules: const [],
      exams: [
        _exam(id: 'E3', date: DateTime(2026, 11, 27), start: 9 * 60),
        _exam(id: 'E1', date: DateTime(2026, 11, 25), start: 14 * 60),
        _exam(id: 'E2', date: DateTime(2026, 11, 25), start: 9 * 60),
      ],
    );

    expect(table.exams.map((exam) => exam.id), ['E2', 'E1', 'E3']);
    expect(table.examsOn(DateTime(2026, 11, 25)), hasLength(2));
    expect(table.examsOn(DateTime(2026, 11, 26)), isEmpty);
  });

  test('最近的考试跳过已经结束的日子', () {
    final table = Timetable(
      id: 't1',
      config: _config(),
      rules: const [],
      exams: [
        _exam(id: 'E1', date: DateTime(2026, 11, 20)),
        _exam(id: 'E2', date: DateTime(2026, 11, 25)),
      ],
    );

    expect(table.nextExamOn(DateTime(2026, 11, 21))?.id, 'E2');
    expect(table.nextExamOn(DateTime(2026, 11, 25))?.id, 'E2');
    expect(table.nextExamOn(DateTime(2026, 11, 26)), isNull);
  });

  test('按真实时间轴算出考试占用的行偏移与高度，跳过课间空档', () {
    final table = Timetable(id: 't1', config: _config(), rules: const []);
    // 节次：08:00–08:45、08:55–09:40、10:00–10:45、10:55–11:40。

    // 整两节：从第一节顶边到第二节底边，正好 2 行。
    final full = table.examLayout(_exam(start: 8 * 60, end: 9 * 60 + 40))!;
    expect(full.top, closeTo(0, 0.001));
    expect(full.height, closeTo(2, 0.001));

    // 09:00–11:00：起点在第二节中段、终点在第四节前段，高度按时间算是 2 行，
    // 不是用「120 ÷ 45」估出来的 3 行。
    final partial = table.examLayout(_exam(start: 9 * 60, end: 11 * 60))!;
    expect(partial.top, closeTo(1 + 5 / 45, 0.001));
    expect(partial.height, closeTo(2, 0.001));

    // 只有开始时间时按默认时长往后推。
    final noEnd = table.examLayout(_exam(start: 8 * 60))!;
    expect(noEnd.height, closeTo(1 + 35 / 45, 0.001));

    // 落在课间：贴到下一节的上边缘。
    expect(table.offsetInRows(9 * 60 + 45), closeTo(2, 0.001));
    // 早于第一节贴顶部，晚于最后一节贴底部。
    expect(table.offsetInRows(7 * 60), closeTo(0, 0.001));
    expect(table.offsetInRows(22 * 60), closeTo(4, 0.001));

    // 极短的考试也留出一条能点到的高度。
    final tiny = table.examLayout(_exam(start: 9 * 60 + 20, end: 9 * 60 + 25))!;
    expect(tiny.height, greaterThanOrEqualTo(0.35));

    // 没有开考时间的考试不进网格。
    expect(table.examLayout(_exam()), isNull);
  });

  test('考试可以序列化后原样还原', () {
    final exam = _exam(
      date: DateTime(2027, 1, 12),
      start: 9 * 60,
      end: 11 * 60,
      location: '示例楼 A201',
    );

    final restored = TimetableExam.fromJson(exam.toJson());

    expect(restored.id, exam.id);
    expect(restored.courseName, exam.courseName);
    expect(restored.date, DateTime(2027, 1, 12));
    expect(restored.startMinute, 9 * 60);
    expect(restored.endMinute, 11 * 60);
    expect(restored.location, '示例楼 A201');
    expect(restored.timeLabel, '09:00–11:00');
  });

  test('考试沿用同名课程的配色下标，找不到课程时用课程名兜底', () {
    final table = Timetable(
      id: 't1',
      config: _config(),
      rules: [
        TimetableRule(
          id: 'R1',
          courseId: 'C9',
          name: '示例课程',
          weekday: 1,
          weeks: const [1],
          startPeriod: 1,
          endPeriod: 2,
        ),
      ],
    );

    expect(table.examColorIndex(_exam(name: '示例课程')), courseColorIndex('C9'));
    expect(
      table.examColorIndex(_exam(name: '另一门课')),
      courseColorIndex('exam|另一门课'),
    );
  });

  test('日期无效时拒绝还原', () {
    expect(
      () => TimetableExam.fromJson({
        'id': 'E1',
        'courseName': '示例',
        'date': '2027-13-01',
      }),
      throwsA(isA<FormatException>()),
    );
  });
}
