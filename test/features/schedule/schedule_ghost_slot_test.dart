import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/app.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/data/import/timetable_import.dart';
import 'package:qinghe_app/data/models/semester_config.dart';
import 'package:qinghe_app/data/models/timetable_rule.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_period_label.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 以本周周一为第一教学周，保证点到的格子落在当前显示的这一周。
final _monday = DateTime.now().subtract(
  Duration(days: DateTime.now().weekday - DateTime.monday),
);

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
    '16:00',
    '16:55',
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

void main() {
  tearDown(Get.reset);

  testWidgets('点空白格出现加号占位，再点进入添加课程页并保存', (tester) async {
    SharedPreferences.setMockInitialValues(_seeded());

    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-schedule')));
    await tester.pumpAndSettle();

    final appearance = Get.find<AppearanceController>();
    final railWidth = SchedulePeriodLabel.railWidthFor(
      showTime: appearance.scheduleShowTime.value,
      textLayout: appearance.scheduleRailTextLayout.value,
    );
    final rowHeight = appearance.scheduleRowHeight.value;
    final gridRect = tester.getRect(
      find.byKey(const ValueKey('schedule-grid')),
    );
    final days = appearance.scheduleShowWeekend.value ? 7 : 5;
    final dayWidth = (gridRect.width - railWidth) / days;

    // 周一第 6 节是空白的。
    final tapPoint = Offset(
      gridRect.left + railWidth + dayWidth * 0.5,
      gridRect.top + rowHeight * 5.5,
    );

    expect(find.byKey(const ValueKey('schedule-ghost-slot')), findsNothing);
    await tester.tapAt(tapPoint);
    await tester.pumpAndSettle();

    final ghost = find.byKey(const ValueKey('schedule-ghost-slot'));
    expect(ghost, findsOneWidget);

    // 再点占位格进入添加课程页。
    await tester.tap(ghost);
    await tester.pumpAndSettle();
    expect(find.text('添加课程'), findsWidgets);
    expect(find.text('保存到课表'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('add-lesson-name')),
      '新增示例课',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存到课表'));
    await tester.pumpAndSettle();

    final rules = Get.find<LocalTimetableRepository>().active!.rules;
    expect(rules, hasLength(2));
    final added = rules.last;
    expect(added.name, '新增示例课');
    expect(added.weekday, 1);
    expect(added.startPeriod, 6);
    expect(added.endPeriod, 6);
    expect(added.weeks, hasLength(18));
    // 保存后回到课表，占位格消失。
    expect(find.byKey(const ValueKey('schedule-ghost-slot')), findsNothing);
  });

  testWidgets('点已有课程的格子不会出现占位格', (tester) async {
    SharedPreferences.setMockInitialValues(_seeded());

    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-schedule')));
    await tester.pumpAndSettle();

    final appearance = Get.find<AppearanceController>();
    final railWidth = SchedulePeriodLabel.railWidthFor(
      showTime: appearance.scheduleShowTime.value,
      textLayout: appearance.scheduleRailTextLayout.value,
    );
    final rowHeight = appearance.scheduleRowHeight.value;
    final gridRect = tester.getRect(
      find.byKey(const ValueKey('schedule-grid')),
    );
    final days = appearance.scheduleShowWeekend.value ? 7 : 5;
    final dayWidth = (gridRect.width - railWidth) / days;

    // 先点空白格生成占位，再点周一第 1 节（已有课）应当把它清掉。
    await tester.tapAt(
      Offset(
        gridRect.left + railWidth + dayWidth * 0.5,
        gridRect.top + rowHeight * 5.5,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('schedule-ghost-slot')), findsOneWidget);

    await tester.tapAt(
      Offset(
        gridRect.left + railWidth + dayWidth * 0.5,
        gridRect.top + rowHeight * 0.5,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('schedule-ghost-slot')), findsNothing);
  });
}
