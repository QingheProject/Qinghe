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
import 'package:qinghe_app/features/schedule/controllers/schedule_controller.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_period_label.dart';
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

void main() {
  tearDown(Get.reset);

  testWidgets('有考试的日子在课表里带标记，点开能看考试详情', (tester) async {
    // 选一个不是「今天」的日子：当天的标记点会盖住考试点。
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final examDay = [
      for (var offset = 0; offset < 7; offset++)
        _monday.add(Duration(days: offset)),
    ].firstWhere((day) => day != todayDate);
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
    await tester.tap(find.byKey(const ValueKey('nav-schedule')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('schedule-settings-button')));
    await tester.pumpAndSettle();

    expect(find.text('1 场考试'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('schedule-settings-exams')));
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
    await tester.tap(find.byKey(const ValueKey('nav-schedule')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('schedule-settings-button')));
    await tester.pumpAndSettle();

    expect(find.text('尚未读取考试安排'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('schedule-settings-exams')));
    await tester.pumpAndSettle();
    expect(find.text('本学期还没有考试信息'), findsOneWidget);

    // 存在的课表会被读取出来，考试为空不影响其它数据。
    expect(Get.find<LocalTimetableRepository>().active?.rules, hasLength(1));
  });

  testWidgets('周次在左上角，名称排在下面，右侧是周次与设置按钮', (tester) async {
    SharedPreferences.setMockInitialValues(_seededPreferences(exams: const []));

    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-schedule')));
    await tester.pumpAndSettle();

    final heading = tester.widget<Text>(
      find.byKey(const ValueKey('schedule-heading')),
    );
    expect(heading.data, '示例学期');
    final weekLabel = tester.widget<Text>(
      find.byKey(const ValueKey('schedule-week-label')),
    );
    expect(weekLabel.data, '第1周');

    final weekRect = tester.getRect(
      find.byKey(const ValueKey('schedule-week-label')),
    );
    final nameRect = tester.getRect(
      find.byKey(const ValueKey('schedule-heading')),
    );
    final weekButtonRect = tester.getRect(
      find.byKey(const ValueKey('schedule-week-button')),
    );
    final settingsRect = tester.getRect(
      find.byKey(const ValueKey('schedule-settings-button')),
    );

    // 周次与名称都排在左侧，两个按钮靠右上依次排列。
    expect(weekRect.left, lessThan(weekButtonRect.left));
    expect(settingsRect.left, greaterThan(weekButtonRect.right));
    expect(nameRect.top, greaterThan(weekRect.bottom));
    expect(nameRect.left, closeTo(weekRect.left, 2));
    // 右侧两个图标按钮在两行文字之间竖直居中。
    final blockCenter = (weekRect.top + nameRect.bottom) / 2;
    expect(weekButtonRect.center.dy, closeTo(blockCenter, 6));
    expect(settingsRect.center.dy, closeTo(weekButtonRect.center.dy, 1));
    // 周次比课表名称更大，是这块的主标题。
    expect(weekLabel.style!.fontSize!, greaterThan(heading.style!.fontSize!));
    // 日期小标题已经移除。
    expect(find.byKey(const ValueKey('schedule-date-range')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('顶部周次按钮打开抽屉，切换周次后可以回到本周', (tester) async {
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
          ),
        ],
      ),
    );

    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-schedule')));
    await tester.pumpAndSettle();

    // 标题显示课表名称与周次。
    expect(find.text('示例学期'), findsOneWidget);
    expect(find.byKey(const ValueKey('schedule-week-label')), findsOneWidget);

    final schedule = Get.find<ScheduleController>();
    expect(schedule.isCurrentWeek, isTrue);

    await tester.tap(find.byKey(const ValueKey('schedule-week-button')));
    await tester.pumpAndSettle();
    expect(find.text('切换周次'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('schedule-week-2')));
    await tester.pumpAndSettle();
    expect(schedule.isCurrentWeek, isFalse);
    expect(find.text('切换周次'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('schedule-today-button')));
    await tester.pumpAndSettle();
    expect(schedule.isCurrentWeek, isTrue);
  });

  testWidgets('节次栏上方显示当前教学周', (tester) async {
    SharedPreferences.setMockInitialValues(_seededPreferences(exams: const []));

    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-schedule')));
    await tester.pumpAndSettle();

    final railWeek = find.byKey(const ValueKey('schedule-rail-week'));
    expect(railWeek, findsOneWidget);
    expect(tester.widget<Text>(railWeek).data, '1周');

    // 它在节次栏里，位于日期表头那一行，并且在节次栏那一列居中。
    final railRect = tester.getRect(railWeek);
    final mondayRect = tester.getRect(find.text('一'));
    expect(railRect.right, lessThan(mondayRect.left));

    // 与下面第 1 节的格子对比：水平中心应当一致。
    final periodCell = tester.getRect(find.byType(SchedulePeriodLabel).first);
    expect(railRect.center.dx, closeTo(periodCell.center.dx, 1));
  });

  testWidgets('回到本周与右上角图标按钮同在一条水平线上', (tester) async {
    SharedPreferences.setMockInitialValues(_seededPreferences(exams: const []));

    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-schedule')));
    await tester.pumpAndSettle();

    // 切到下一周，右上角才会出现「回到本周」。
    await tester.tap(find.byKey(const ValueKey('schedule-week-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('schedule-week-2')));
    await tester.pumpAndSettle();

    final today = find.byKey(const ValueKey('schedule-today-button'));
    expect(today, findsOneWidget);

    final todayRect = tester.getRect(today);
    final weekRect = tester.getRect(
      find.byKey(const ValueKey('schedule-week-button')),
    );
    final settingsRect = tester.getRect(
      find.byKey(const ValueKey('schedule-settings-button')),
    );
    final nameRect = tester.getRect(
      find.byKey(const ValueKey('schedule-heading')),
    );

    // 三者纵向中心一致，并且都在课表名称右边。
    expect(todayRect.center.dy, closeTo(weekRect.center.dy, 1));
    expect(settingsRect.center.dy, closeTo(weekRect.center.dy, 1));
    expect(todayRect.left, greaterThan(nameRect.right));
    // 药丸按钮放在 34 高的槽里，不会撑高顶栏。
    expect(todayRect.height, lessThanOrEqualTo(34));
  });
}
