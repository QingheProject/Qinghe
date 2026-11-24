import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/app.dart';
import 'package:qinghe_app/data/import/timetable_import.dart';
import 'package:qinghe_app/data/models/semester_config.dart';
import 'package:qinghe_app/data/models/timetable_exam.dart';
import 'package:qinghe_app/data/models/timetable_rule.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 以本周周一为第一教学周，保证考试落在当前显示的这一周里。
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
];

Map<String, Object> _seededPreferences({required List<TimetableExam> exams}) {
  final import = TimetableImport(_rules(), config: _config());
  return {
    'onboarding_completed': true,
    'local_timetables_v1': jsonEncode({
      'activeId': 't1',
      'tables': [
        {
          'id': 't1',
          ...import.toJson(),
          'exams': [for (final exam in exams) exam.toJson()],
        },
      ],
    }),
  };
}

Finder _scrollableIn(String key) => find
    .descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(Scrollable),
    )
    .first;

void main() {
  tearDown(Get.reset);

  testWidgets('有考试的日子在课表里带标记，点开能看考试详情', (tester) async {
    final examDay = _monday.add(const Duration(days: 2));
    SharedPreferences.setMockInitialValues(
      _seededPreferences(
        exams: [
          TimetableExam(
            id: 'E1',
            courseName: '示例课程甲',
            date: examDay,
            startMinute: 9 * 60,
            endMinute: 11 * 60,
            location: '示例考场',
            seat: '12',
            note: '闭卷',
          ),
        ],
      ),
    );

    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-schedule')));
    await tester.pumpAndSettle();

    // 日期表头带考试标记。
    expect(find.byKey(const ValueKey('schedule-exam-dot')), findsOneWidget);

    // 考试按开考时间落在对应节次上。
    final card = find.byKey(const ValueKey('exam-E1'));
    expect(card, findsOneWidget);
    expect(find.textContaining('考试 09:00–11:00'), findsOneWidget);

    await tester.tap(card);
    await tester.pumpAndSettle();
    expect(find.text('示例考场'), findsWidgets);

    expect(find.text('座位'), findsOneWidget);
    expect(find.text('闭卷'), findsOneWidget);
  });

  testWidgets('考试信息页列出考试并可查看详情', (tester) async {
    final examDay = _monday.add(const Duration(days: 2));
    SharedPreferences.setMockInitialValues(
      _seededPreferences(
        exams: [
          TimetableExam(
            id: 'E1',
            courseName: '示例课程甲',
            date: examDay,
            startMinute: 9 * 60,
            endMinute: 11 * 60,
            location: '示例考场',
          ),
        ],
      ),
    );

    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-profile')));
    await tester.pumpAndSettle();

    final entry = find.byKey(const ValueKey('profile-exams'));
    await tester.scrollUntilVisible(
      entry,
      220,
      scrollable: _scrollableIn('profile-scroll'),
    );
    expect(find.text('1 场考试'), findsOneWidget);

    await tester.tap(entry);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('exam-list')), findsOneWidget);
    expect(find.textContaining('共 1 场考试'), findsOneWidget);
    expect(find.byKey(const ValueKey('exam-row-E1')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('exam-row-E1')));
    await tester.pumpAndSettle();
    expect(find.text('示例考场'), findsWidgets);
  });

  testWidgets('没有考试时考试信息页给出导入提示', (tester) async {
    SharedPreferences.setMockInitialValues(_seededPreferences(exams: const []));

    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-profile')));
    await tester.pumpAndSettle();

    final entry = find.byKey(const ValueKey('profile-exams'));
    await tester.scrollUntilVisible(
      entry,
      220,
      scrollable: _scrollableIn('profile-scroll'),
    );
    expect(find.text('尚未读取考试安排'), findsOneWidget);

    await tester.tap(entry);
    await tester.pumpAndSettle();
    expect(find.text('本学期还没有考试信息'), findsOneWidget);

    // 存在的课表会被读取出来，考试为空不影响其它数据。
    expect(Get.find<LocalTimetableRepository>().active?.rules, hasLength(1));
  });
}
