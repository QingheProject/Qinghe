import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/data/repositories/sample_timetable_repository.dart';
import 'package:qinghe_app/features/schedule/controllers/schedule_controller.dart';

void main() {
  test('以周一为周起点并支持前后周与返回本周', () {
    final controller = ScheduleController(
      SampleTimetableRepository(),
      clock: () => DateTime(2026, 11, 21, 18, 30),
    );

    expect(controller.weekStart.value, DateTime(2026, 11, 16));
    expect(controller.days.last, DateTime(2026, 11, 22));
    expect(controller.teachingWeek, 11);
    expect(controller.isCurrentWeek, isTrue);
    expect(controller.currentMinute, 18 * 60 + 30);

    controller.nextWeek();
    expect(controller.weekStart.value, DateTime(2026, 11, 23));
    expect(controller.isCurrentWeek, isFalse);

    controller.previousWeek();
    expect(controller.weekStart.value, DateTime(2026, 11, 16));

    controller.previousWeek();
    controller.goToCurrentWeek();
    expect(controller.weekStart.value, DateTime(2026, 11, 16));
    expect(controller.isCurrentWeek, isTrue);
  });
}
