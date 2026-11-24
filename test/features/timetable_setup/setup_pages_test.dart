import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_theme.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:qinghe_app/features/timetable_setup/views/school_picker_page.dart';
import 'package:qinghe_app/features/timetable_setup/views/semester_config_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _app(Widget home) =>
    GetMaterialApp(theme: AppTheme.lightFor(AppAccentTone.qinghe), home: home);

/// 打开学校列表并等待返回值的入口按钮。
Widget _pickerHost(void Function(String?) onResult) => Builder(
  builder: (context) => Center(
    child: TextButton(
      onPressed: () async {
        final value = await Get.to<Object?>(() => const SchoolPickerPage());
        onResult(value is String ? value : null);
      },
      child: const Text('打开'),
    ),
  ),
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(Get.reset);

  testWidgets('学校列表带搜索、首字母分组与状态说明', (tester) async {
    await tester.pumpWidget(_app(const SchoolPickerPage()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('school-search-field')), findsOneWidget);
    expect(find.byKey(const ValueKey('school-list')), findsOneWidget);
    expect(find.byKey(const ValueKey('school-letter-X')), findsOneWidget);
    expect(find.text('西南科技大学'), findsOneWidget);
    expect(find.text('支持教务导入'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('搜索命中时保留学校，未命中时给出使用输入名称的入口', (tester) async {
    await tester.pumpWidget(_app(const SchoolPickerPage()));
    await tester.pumpAndSettle();

    final search = find.byKey(const ValueKey('school-search-field'));
    await tester.enterText(search, '西南');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('school-西南科技大学')), findsOneWidget);

    await tester.enterText(search, '示例大学');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('school-西南科技大学')), findsNothing);
    expect(find.text('没有找到「示例大学」'), findsOneWidget);
    expect(find.text('使用「示例大学」'), findsOneWidget);
  });

  testWidgets('选中列表中的学校后回传学校名', (tester) async {
    String? result;
    await tester.pumpWidget(_app(_pickerHost((value) => result = value)));
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('school-西南科技大学')));
    await tester.pumpAndSettle();

    expect(result, '西南科技大学');
  });

  testWidgets('列表之外的学校可以手动填写后使用', (tester) async {
    String? result;
    await tester.pumpWidget(_app(_pickerHost((value) => result = value)));
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('找不到学校？手动填写'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('school-other-field')),
      '示例大学',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('使用该学校'));
    await tester.pumpAndSettle();

    expect(result, '示例大学');
  });

  testWidgets('学期与节次页在没有待导入数据时只保存学期配置', (tester) async {
    Get.put(LocalTimetableRepository());
    await tester.pumpWidget(_app(const SemesterConfigPage()));
    await tester.pumpAndSettle();

    expect(find.text('待导入数据'), findsNothing);

    await tester.enterText(find.byKey(const ValueKey('semester-name')), '示例学期');
    await tester.enterText(
      find.byKey(const ValueKey('semester-monday')),
      '2026-09-07',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('保存学期配置'));
    await tester.pumpAndSettle();

    final repository = Get.find<LocalTimetableRepository>();
    expect(repository.timetables, hasLength(1));
    expect(repository.active?.config.name, '示例学期');
    expect(repository.active?.rules, isEmpty);
    expect(tester.takeException(), isNull);
  });
}
