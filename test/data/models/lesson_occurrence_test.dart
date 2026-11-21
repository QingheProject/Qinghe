import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';

LessonOccurrence _lesson(String id, int start, int end) => LessonOccurrence(
  id: id,
  courseName: '示例课程$id',
  startPeriod: 1,
  endPeriod: 2,
  startMinute: start,
  endMinute: end,
);

void main() {
  final morning = _lesson('甲', 480, 580);
  final noon = _lesson('乙', 600, 700);

  test('上课状态采用半开区间，结束时刻即为已结束', () {
    expect(morning.statusAt(479), LessonStatus.upcoming);
    expect(morning.statusAt(480), LessonStatus.ongoing);
    expect(morning.statusAt(579), LessonStatus.ongoing);
    expect(morning.statusAt(580), LessonStatus.finished);
  });

  test('进度限制在 0 到 1 之间', () {
    expect(morning.progressAt(400), 0);
    expect(morning.progressAt(530), 0.5);
    expect(morning.progressAt(900), 1);
  });

  test('重点课程优先取正在上的课', () {
    expect(pickFocusLesson([noon, morning], 500), same(morning));
  });

  test('课间时重点课程为下一节', () {
    expect(pickFocusLesson([noon, morning], 590), same(noon));
  });

  test('全部结束后没有重点课程', () {
    expect(pickFocusLesson([noon, morning], 700), isNull);
    expect(pickFocusLesson(const [], 600), isNull);
  });
}
