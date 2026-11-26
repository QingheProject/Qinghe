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

  testWidgets('默认是周视图，顶部提供日/周切换', (tester) async {
    await _boot(tester);

    expect(
      find.byKey(const ValueKey('schedule-view-switcher')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('schedule-view-week')), findsOneWidget);
    expect(find.byKey(const ValueKey('schedule-view-day')), findsOneWidget);
    // 月视图已移除。
    expect(find.byKey(const ValueKey('schedule-view-month')), findsNothing);
    // 周视图显示整周课程。
    expect(find.text('示例课程甲'), findsOneWidget);
    expect(find.text('示例课程乙'), findsOneWidget);
  });

  testWidgets('日视图是一整条时间线：所有天都带小标题，没课的天画虚线', (tester) async {
    final controller = await _boot(tester);

    await tester.tap(find.byKey(const ValueKey('schedule-view-day')));
    await tester.pumpAndSettle();

    // 时间是整学期的连续列表，不是一天一页；也不复用节次网格与星期表头。
    expect(find.byKey(const ValueKey('schedule-day-view')), findsOneWidget);
    expect(find.byKey(const ValueKey('schedule-day-list')), findsOneWidget);
    expect(find.byKey(const ValueKey('schedule-grid')), findsNothing);
    expect(find.byKey(const ValueKey('schedule-rail-week')), findsNothing);

    // 列表里每天都有小标题，没课的天给出虚线占位。
    expect(find.byKey(const ValueKey('schedule-day-title')), findsWidgets);
    expect(find.byKey(const ValueKey('schedule-day-empty')), findsWidgets);

    // 顶栏大标题是当天日期。
    final today = controller.today;
    final heading = tester.widget<Text>(
      find.byKey(const ValueKey('schedule-day-label')),
    );
    expect(heading.data, '${today.month}月${today.day}日');
  });

  testWidgets('进入日视图时列表停在今天所在的那一天', (tester) async {
    final controller = await _boot(tester);

    await tester.tap(find.byKey(const ValueKey('schedule-view-day')));
    await tester.pumpAndSettle();

    final today = controller.today;
    final section = find.byKey(
      ValueKey('schedule-day-section-${today.year}${today.month}${today.day}'),
    );
    expect(section, findsOneWidget);
    final listTop = tester
        .getRect(find.byKey(const ValueKey('schedule-day-list')))
        .top;
    // 今天的区块应该停在内容区顶部，而不是学期开头。
    expect(tester.getRect(section).top, closeTo(listTop, 4));
    // 日期轴已经移除。
    expect(find.byKey(const ValueKey('schedule-day-axis')), findsNothing);
  });

  testWidgets('周视图左右滑动切周，页面跟手翻动而不是瞬移', (tester) async {
    final controller = await _boot(tester);
    final start = controller.weekStart.value;
    final pages = find.byKey(const ValueKey('schedule-week-pages'));
    expect(pages, findsOneWidget);

    // 拖动一小段但不够翻页：页面已经跟着手移动，周次还没变。
    final gesture = await tester.startGesture(tester.getCenter(pages));
    // 先越过触摸阈值，再继续拖动，页面才会跟手移动。
    await gesture.moveBy(const Offset(-20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-100, 0));
    await tester.pump();
    expect(controller.weekStart.value, start);
    final pageController = tester
        .widget<PageView>(
          find.descendant(of: pages, matching: find.byType(PageView)).first,
        )
        .controller!;
    expect(pageController.page, greaterThan(0.1));
    expect(pageController.page, lessThan(1.0));
    await gesture.up();
    await tester.pumpAndSettle();
    // 拖动不够一页，松手回到原来的一周。
    expect(controller.weekStart.value, start);
    expect(pageController.page, closeTo(0, 0.01));

    // 向右回翻前，先向左快速翻一页。
    await tester.fling(pages, const Offset(-320, 0), 1200);
    await tester.pumpAndSettle();
    expect(controller.weekStart.value, start.add(const Duration(days: 7)));

    // 向右回翻。
    await tester.fling(pages, const Offset(320, 0), 1200);
    await tester.pumpAndSettle();
    expect(controller.weekStart.value, start);

    // 轻微抖动不会切周。
    await tester.drag(pages, const Offset(-20, 0));
    await tester.pumpAndSettle();
    expect(controller.weekStart.value, start);
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

  testWidgets('日视图顶部按钮打开日历抽屉，点某天跳到那天', (tester) async {
    final controller = await _boot(tester);

    await tester.tap(find.byKey(const ValueKey('schedule-view-day')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('schedule-week-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('schedule-calendar-sheet')),
      findsOneWidget,
    );
    expect(find.text('选择日期'), findsOneWidget);

    // 点本周周一，抽屉关闭并跳到那天。
    final mondayCell = find.byKey(
      ValueKey(
        'schedule-calendar-day-${_monday.year}${_monday.month}${_monday.day}',
      ),
    );
    expect(mondayCell, findsOneWidget);
    await tester.tap(mondayCell);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('schedule-calendar-sheet')), findsNothing);
    expect(controller.viewMode.value, ScheduleViewMode.day);
    expect(controller.selectedDate.value, _monday);
    expect(
      find.byKey(
        ValueKey(
          'schedule-day-section-${_monday.year}${_monday.month}${_monday.day}',
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('滚动时当天标题飞出内容区，画在内容区之上而不是被裁掉', (tester) async {
    await _boot(tester);

    await tester.tap(find.byKey(const ValueKey('schedule-view-day')));
    await tester.pumpAndSettle();

    final list = find.byKey(const ValueKey('schedule-day-list'));
    final listTop = tester.getRect(list).top;
    final flying = find.byKey(const ValueKey('schedule-flying-title'));

    // 还没滚动时，标题留在列表里，没有飞行层。
    expect(flying, findsNothing);

    // 往下滚一点点，让当天标题进入「飞向顶栏」的区间。
    await tester.drag(list, const Offset(0, -18));
    await tester.pumpAndSettle();

    expect(flying, findsOneWidget);
    final flyingRect = tester.getRect(
      find.byKey(const ValueKey('schedule-flying-date')),
    );
    // 飞行标题已经越过内容区顶边，位于顶栏区域，说明没有被裁切遮盖。
    expect(flyingRect.top, lessThan(listTop));

    // 飞行途中顶栏的那份日期让位，避免两个日期同时出现；
    // 飞行文字本身没有透明度变化。
    final headerOpacity = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('schedule-day-label')),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(headerOpacity.opacity, 0);
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('schedule-flying-date')),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );

    // 往回滚（多滚一点，抵消手势的触摸阈值），飞行层收回，标题回到列表里。
    await tester.drag(list, const Offset(0, 40));
    await tester.pumpAndSettle();
    expect(flying, findsNothing);
    final restored = tester.widget<Opacity>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('schedule-day-label')),
            matching: find.byType(Opacity),
          )
          .first,
    );
    expect(restored.opacity, 1);
  });
}
