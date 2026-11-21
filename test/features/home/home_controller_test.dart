import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/data/repositories/sample_timetable_repository.dart';
import 'package:qinghe_app/features/home/controllers/home_controller.dart';

void main() {
  test('固定时刻下给出周次、重点课程与剩余节数', () {
    var now = DateTime(2026, 11, 20, 10, 10);
    final controller = HomeController(
      SampleTimetableRepository(),
      clock: () => now,
    );

    expect(controller.teachingWeek, 11);
    expect(controller.greeting, '早上好');
    expect(controller.lessons, hasLength(2));
    expect(
      controller.focusLesson?.statusAt(controller.minuteOfDay),
      LessonStatus.ongoing,
    );
    expect(controller.remainingCount, 2);

    now = DateTime(2026, 11, 21, 9);
    controller.refreshClock();
    expect(controller.lessons, isEmpty);
    expect(controller.focusLesson, isNull);
  });
}
