import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/app.dart';
import 'package:qinghe_app/data/import/timetable_import.dart';
import 'package:qinghe_app/data/models/semester_config.dart';
import 'package:qinghe_app/data/models/timetable_rule.dart';
import 'package:qinghe_app/features/schedule/controllers/schedule_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 以本周周一为第一教学周，保证显示的就是当前周；只保留日期部分。
final _now = DateTime.now();
final _monday = DateTime(_now.year, _now.month, _now.day - (_now.weekday - 1));

SemesterConfig _config() => SemesterConfig(
  name: '示例学期',
  week1Monday: _monday,
  weekCount: 18,
  periodStartTimes: const [
    '08:00',
    '08:55',
    '10:00',
    '10:55',
    '14:00',
    '14:55',
  ],
  periodDurationMinutes: 45,
);

List<TimetableRule> _rules() => [
  TimetableRule(
    id: 'R1',
    courseId: 'C1',
    name: '示例课程甲',
    weekday: 1,
    weeks: const [1, 2, 3, 4, 5],
    startPeriod: 1,
    endPeriod: 2,
    location: '示例教室',
  ),
  TimetableRule(
    id: 'R2',
    courseId: 'C2',
    name: '示例课程乙',
    weekday: 3,
    weeks: const [1, 2, 3, 4, 5],
    startPeriod: 3,
    endPeriod: 4,
  ),
];

Map<String, Object> _seeded() {
  final import = TimetableImport(_rules(), config: _config());
  return {
    'onboarding_completed': true,
    'local_timetables_v1': jsonEncode({
      'activeId': 't1',
      'tables': [
        {'id': 't1', ...import.toJson(), 'exams': <Object>[]},
      ],
    }),
  };
}

Future<ScheduleController> _boot(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(_seeded());
  await tester.pumpWidget(const QingheApp());
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('nav-schedule')));
  await tester.pumpAndSettle();
  return Get.find<ScheduleController>();
}

void main() {
  tearDown(Get.reset);

  testWidgets('默认是周视图，顶部提供日/周/月切换', (tester) async {
    await _boot(tester);

    expect(
      find.byKey(const ValueKey('schedule-view-switcher')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('schedule-view-week')), findsOneWidget);
    expect(find.byKey(const ValueKey('schedule-view-day')), findsOneWidget);
    expect(find.byKey(const ValueKey('schedule-view-month')), findsOneWidget);
    // 周视图显示整周课程。
    expect(find.text('示例课程甲'), findsOneWidget);
    expect(find.text('示例课程乙'), findsOneWidget);
  });

  testWidgets('日视图是横向日期轴 + 竖向时间线，顶栏显示当天', (tester) async {
    final controller = await _boot(tester);

    await tester.tap(find.byKey(const ValueKey('schedule-view-day')));
    await tester.pumpAndSettle();

    // 横向日期轴与纵向地铁线时间线都在；不再复用节次网格与星期表头。
    expect(find.byKey(const ValueKey('schedule-day-view')), findsOneWidget);
    expect(find.byKey(const ValueKey('schedule-day-axis')), findsOneWidget);
    expect(find.byKey(const ValueKey('schedule-grid')), findsNothing);
    expect(find.byKey(const ValueKey('schedule-rail-week')), findsNothing);

    // 顶栏的大标题变成当天日期。
    final heading = tester.widget<Text>(
      find.byKey(const ValueKey('schedule-day-label')),
    );
    final today = controller.today;
    expect(heading.data, '${today.month}月${today.day}日');

    // 点日期轴上的周一，跳到那天的时间线，顶栏跟着变。
    final mondayChip = find.byKey(
      ValueKey('schedule-axis-${_monday.year}${_monday.month}${_monday.day}'),
    );
    expect(mondayChip, findsOneWidget);
    await tester.tap(mondayChip);
    await tester.pumpAndSettle();

    expect(controller.displayedDate, _monday);
    final updated = tester.widget<Text>(
      find.byKey(const ValueKey('schedule-day-label')),
    );
    expect(updated.data, '${_monday.month}月${_monday.day}日');
    expect(find.text('示例课程甲'), findsOneWidget);
    expect(find.text('示例课程乙'), findsNothing);
  });

  testWidgets('日视图只显示选中那天的课，可以前后翻天', (tester) async {
    final controller = await _boot(tester);

    await tester.tap(find.byKey(const ValueKey('schedule-view-day')));
    await tester.pumpAndSettle();

    // 翻到周一，只显示示例课程甲。
    controller.goToDate(_monday);
    await tester.pumpAndSettle();
    expect(find.text('示例课程甲'), findsOneWidget);
    expect(find.text('示例课程乙'), findsNothing);

    // 再翻一天到周二：都没有课。
    controller.nextDate();
    await tester.pumpAndSettle();
    expect(find.text('示例课程甲'), findsNothing);
    expect(find.text('示例课程乙'), findsNothing);
    expect(find.text('这天没有课'), findsOneWidget);

    // 翻到周三：只显示示例课程乙。
    controller.nextDate();
    await tester.pumpAndSettle();
    expect(find.text('示例课程乙'), findsOneWidget);
    expect(find.text('示例课程甲'), findsNothing);
  });

  testWidgets('月视图显示整月日历，点某天跳到日视图', (tester) async {
    final controller = await _boot(tester);

    await tester.tap(find.byKey(const ValueKey('schedule-view-month')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('schedule-month-view')), findsOneWidget);
    // 今天的格子和带课的格子都在。
    final today = controller.today;
    expect(
      find.byKey(
        ValueKey('schedule-month-cell-${today.year}${today.month}${today.day}'),
      ),
      findsOneWidget,
    );
    // 周一那格存在且有课。
    expect(
      find.byKey(
        ValueKey(
          'schedule-month-cell-${_monday.year}${_monday.month}${_monday.day}',
        ),
      ),
      findsOneWidget,
    );

    // 点周一跳到日视图并显示那天的课。
    await tester.tap(
      find.byKey(
        ValueKey(
          'schedule-month-cell-${_monday.year}${_monday.month}${_monday.day}',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.viewMode.value, ScheduleViewMode.day);
    expect(controller.selectedDate.value, _monday);
    expect(find.text('示例课程甲'), findsOneWidget);
  });

  testWidgets('月视图可以翻月，回到本月按钮回到当前月', (tester) async {
    final controller = await _boot(tester);
    final now = DateTime.now();

    await tester.tap(find.byKey(const ValueKey('schedule-view-month')));
    await tester.pumpAndSettle();
    expect(find.text('${now.year}年${now.month}月'), findsOneWidget);

    controller.nextMonth();
    await tester.pumpAndSettle();
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    expect(find.text('${nextMonth.year}年${nextMonth.month}月'), findsOneWidget);
    // 离开本月后，顶栏出现「回到本月」。
    final todayButton = find.byKey(const ValueKey('schedule-today-button'));
    expect(todayButton, findsOneWidget);
    expect(
      find.descendant(of: todayButton, matching: find.text('回到本月')),
      findsOneWidget,
    );

    await tester.tap(todayButton);
    await tester.pumpAndSettle();
    expect(find.text('${now.year}年${now.month}月'), findsOneWidget);
  });

  testWidgets('切回周视图时显示回整周课程', (tester) async {
    final controller = await _boot(tester);

    await tester.tap(find.byKey(const ValueKey('schedule-view-day')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('schedule-view-week')));
    await tester.pumpAndSettle();

    expect(find.text('示例课程甲'), findsOneWidget);
    expect(find.text('示例课程乙'), findsOneWidget);
    expect(controller.viewMode.value, ScheduleViewMode.week);
  });
}
