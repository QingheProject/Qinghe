import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_theme.dart';
import 'package:qinghe_app/data/models/semester_config.dart';
import 'package:qinghe_app/data/models/timetable.dart';
import 'package:qinghe_app/data/models/timetable_rule.dart';
import 'package:qinghe_app/features/profile/widgets/semester_progress_card.dart';

Timetable _table({int weekCount = 18, int ruleCount = 2}) => Timetable(
  id: 't1',
  config: SemesterConfig(
    name: '2026-2027 第一学期',
    week1Monday: DateTime(2026, 9, 7),
    weekCount: weekCount,
    periodStartTimes: const ['08:00', '08:55', '10:00', '10:55'],
    periodDurationMinutes: 45,
  ),
  rules: [
    for (var index = 0; index < ruleCount; index++)
      TimetableRule(
        id: 'R$index',
        courseId: 'C$index',
        name: '示例课程$index',
        weekday: 1,
        weeks: [for (var week = 1; week <= weekCount; week++) week],
        startPeriod: 1,
        endPeriod: 2,
      ),
  ],
);

Widget _app(Widget child) => GetMaterialApp(
  theme: AppTheme.lightFor(AppAccentTone.qinghe),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  test('学期进度取当前教学周占总周数的比例', () {
    final table = _table(weekCount: 18);
    // 2026-09-07 是第一周周一，11-23 相距 11 周，即第 12 周。
    expect(
      semesterProgressOf(table, DateTime(2026, 11, 23)),
      closeTo(12 / 18, 1e-9),
    );
    expect(
      semesterProgressOf(table, DateTime(2026, 9, 7)),
      closeTo(1 / 18, 1e-9),
    );
    expect(semesterProgressOf(table, DateTime(2027, 1, 11)), 1.0);
    expect(semesterProgressOf(table, DateTime(2026, 8, 1)), 0.0);
  });

  testWidgets('进度卡显示当前周、总周数与课程统计', (tester) async {
    final table = _table();
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 420,
          child: SemesterProgressCard(
            timetable: table,
            now: DateTime(2026, 11, 23),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('第 12 周 / 共 18 周'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('2 门课程'), findsOneWidget);
    expect(find.text('本周 2 节'), findsOneWidget);
    expect(find.text('2026-2027 第一学期'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('没有课表时给出导入提示', (tester) async {
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 420,
          child: SemesterProgressCard(
            timetable: null,
            now: DateTime(2026, 11, 23),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('还没有课表'), findsOneWidget);
  });
}
