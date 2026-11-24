import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/app/reminder_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('默认提前 15 分钟提醒', () async {
    final controller = ReminderController();
    await controller.load();

    expect(controller.leadMinutes.value, 15);
    expect(controller.enabled, isTrue);
    expect(controller.summary, '课前 15 分钟提醒');
  });

  test('修改后会写进本地存储，重新读取仍然生效', () async {
    final controller = ReminderController();
    await controller.setLeadMinutes(30);

    final reopened = ReminderController();
    await reopened.load();
    expect(reopened.leadMinutes.value, 30);
  });

  test('设为 0 表示关闭提醒', () async {
    final controller = ReminderController();
    await controller.setLeadMinutes(0);

    expect(controller.enabled, isFalse);
    expect(controller.summary, '已关闭');
  });

  test('负数会被忽略，不会写入存储', () async {
    final controller = ReminderController();
    await controller.setLeadMinutes(-5);

    expect(controller.leadMinutes.value, 15);
  });
}
