import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/data/repositories/sample_timetable_repository.dart';
import 'package:qinghe_app/features/home/controllers/home_controller.dart';

void main() {
  test('活跃图表使用周一至周日的实际课次，跨年与换周持续正确', () {
    var now = DateTime(2027, 1, 1, 10);
    final controller = HomeController(
      SampleTimetableRepository(),
      clock: () => now,
    );

    var week = controller.weekActivity;
    expect(week.first.date, DateTime(2026, 12, 28));
    expect(week.last.date, DateTime(2027, 1, 3));
    expect(week.map((day) => day.count), [2, 2, 3, 3, 2, 0, 0]);

    now = DateTime(2027, 1, 4, 0, 1);
    controller.refreshClock();
    week = controller.weekActivity;
    expect(week.first.date, DateTime(2027, 1, 4));
    expect(week.last.date, DateTime(2027, 1, 10));
  });

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
