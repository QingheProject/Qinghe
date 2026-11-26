import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/app.dart';
import 'package:qinghe_app/data/import/timetable_import.dart';
import 'package:qinghe_app/data/models/semester_config.dart';
import 'package:qinghe_app/data/models/timetable_rule.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

final _now = DateTime.now();
final _monday = DateTime(_now.year, _now.month, _now.day - (_now.weekday - 1));

Map<String, Object> _seeded() {
  final import = TimetableImport(
    [
      TimetableRule(
        id: 'R1',
        courseId: 'C1',
        name: '示例课程甲',
        weekday: 1,
        weeks: const [1],
        startPeriod: 1,
        endPeriod: 2,
        location: '示例教室',
        teacher: '示例老师',
      ),
    ],
    config: SemesterConfig(
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
    ),
  );
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

Future<void> _openDialog(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(_seeded());
  await tester.pumpWidget(const QingheApp());
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('nav-schedule')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('示例课程甲').first);
  await tester.pumpAndSettle();
}

void main() {
  tearDown(Get.reset);

  testWidgets('课程详情只有右上角关闭，编辑课程进入编辑页', (tester) async {
    await _openDialog(tester);

    // 底部不再有「关闭」与删除，只保留进入编辑页的入口。
    expect(find.widgetWithText(TextButton, '关闭'), findsNothing);
    expect(find.byTooltip('关闭'), findsOneWidget);
    expect(find.byKey(const ValueKey('lesson-sheet-edit')), findsOneWidget);
    expect(find.byKey(const ValueKey('lesson-sheet-delete')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('lesson-sheet-edit')));
    await tester.pumpAndSettle();

    // 复用添加课程页，进入编辑模式并回填原安排。
    expect(find.text('编辑课程'), findsWidgets);
    final name = tester.widget<TextField>(
      find.byKey(const ValueKey('add-lesson-name')),
    );
    expect(name.controller?.text, '示例课程甲');
  });

  testWidgets('删除课程放在编辑页里，删除这门课的全部安排', (tester) async {
    await _openDialog(tester);
    await tester.tap(find.byKey(const ValueKey('lesson-sheet-edit')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const ValueKey('edit-lesson-delete')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('edit-lesson-delete')));
    await tester.pumpAndSettle();
    expect(find.text('删除这门课程？'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('edit-lesson-delete-confirm')));
    await tester.pumpAndSettle();

    // 这门课的全部安排一起删除，课表里不再有它。
    final repository = Get.find<LocalTimetableRepository>();
    expect(repository.active!.rules, isEmpty);
    expect(find.text('示例课程甲'), findsNothing);
  });
}
