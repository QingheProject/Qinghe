import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/app/reminder_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('默认上课提前 15 分钟、考试提前 1 小时', () async {
    final controller = ReminderController();
    await controller.load();

    expect(controller.classLeadMinutes.value, 15);
    expect(controller.examLeadMinutes.value, 60);
    expect(controller.classEnabled, isTrue);
    expect(controller.examEnabled, isTrue);
  });

  test('自定义的时间会写进本地存储，重新读取仍然生效', () async {
    final controller = ReminderController();
    await controller.setClassLeadMinutes(7);
    await controller.setExamLeadMinutes(90);

    final reopened = ReminderController();
    await reopened.load();
    expect(reopened.classLeadMinutes.value, 7);
    expect(reopened.examLeadMinutes.value, 90);
  });

  test('关闭开关后提前量变成 0，再打开会恢复默认值', () async {
    final controller = ReminderController();
    await controller.setClassEnabled(false);
    expect(controller.classLeadMinutes.value, 0);
    expect(controller.classEnabled, isFalse);

    await controller.setClassEnabled(true);
    expect(
      controller.classLeadMinutes.value,
      ReminderController.defaultClassLeadMinutes,
    );
  });

  test('提前量被夹在 1 分钟到 2 天之间，负数当作关闭', () async {
    final controller = ReminderController();
    await controller.setExamLeadMinutes(99999);
    expect(controller.examLeadMinutes.value, ReminderController.maxLeadMinutes);

    await controller.setExamLeadMinutes(-5);
    expect(controller.examLeadMinutes.value, 0);
  });

  test('旧版本的单一提前量会迁移到上课提醒', () async {
    SharedPreferences.setMockInitialValues({
      'course_reminder_lead_minutes_v1': 10,
    });
    final controller = ReminderController();
    await controller.load();

    expect(controller.classLeadMinutes.value, 10);
  });
}
