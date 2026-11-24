import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_theme.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_week_sheet.dart';

final _monday = DateTime(2026, 11, 23);

LessonOccurrence _lesson(String name, int weekday, int start, int end) =>
    LessonOccurrence(
      id: '$name-$weekday-$start',
      courseName: name,
      startPeriod: start,
      endPeriod: end,
      startMinute: 8 * 60,
      endMinute: 9 * 60 + 40,
      colorIndex: 3,
    );

/// 单双周交替有课，用来检查缩略图确实按周次变化。
List<List<LessonOccurrence>> _days(int week) => [
  for (var offset = 0; offset < DateTime.daysPerWeek; offset++)
    offset == 0 && week.isOdd
        ? [_lesson('示例课程', 1, 1, 2)]
        : <LessonOccurrence>[],
];

List<ScheduleWeekSlot> _weeks({int count = 18, int current = 13}) => [
  for (var week = 1; week <= count; week++)
    (
      week: week,
      monday: _monday.add(Duration(days: 7 * (week - 1))),
      sunday: _monday.add(Duration(days: 7 * (week - 1) + 6)),
      isCurrent: week == current,
      days: _days(week),
    ),
];

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.lightFor(AppAccentTone.qinghe),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('周次按钮点击后触发回调', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(ScheduleWeekButton(onTap: () => taps++)));

    await tester.tap(find.byKey(const ValueKey('schedule-week-button')));
    await tester.pump();

    expect(taps, 1);
    expect(find.byTooltip('切换周次'), findsOneWidget);
  });

  testWidgets('周次抽屉列出全部周次，点击某一周后回传并关闭', (tester) async {
    int? selected;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showScheduleWeekSheet(
              context: context,
              weeks: _weeks(),
              selectedWeek: 13,
              currentWeek: 13,
              periodCount: 10,
              onSelect: (week) => selected = week,
            ),
            child: const Text('打开'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    expect(find.text('切换周次'), findsOneWidget);
    expect(find.byKey(const ValueKey('schedule-week-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('schedule-week-18')), findsOneWidget);
    // 本周（第 13 周）在无障碍标签里标出。
    expect(find.bySemanticsLabel(RegExp('第 13 周.*本周')), findsOneWidget);
    // 已经在本周时不显示「回到本周」。
    expect(find.byKey(const ValueKey('schedule-week-today')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('schedule-week-5')));
    await tester.pumpAndSettle();

    expect(selected, 5);
    expect(find.text('切换周次'), findsNothing);
  });

  testWidgets('不在本周时抽屉内提供回到本周', (tester) async {
    var back = 0;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showScheduleWeekSheet(
              context: context,
              weeks: _weeks(),
              selectedWeek: 3,
              currentWeek: 13,
              periodCount: 10,
              onSelect: (_) {},
              onBackToCurrentWeek: () => back++,
            ),
            child: const Text('打开'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('schedule-week-today')));
    await tester.pumpAndSettle();

    expect(back, 1);
    expect(find.text('切换周次'), findsNothing);
  });

  testWidgets('回到本周按钮在本周内不占位', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(ScheduleTodayButton(visible: false, onTap: () => taps++)),
    );
    expect(find.byKey(const ValueKey('schedule-today-button')), findsNothing);

    await tester.pumpWidget(
      _host(ScheduleTodayButton(visible: true, onTap: () => taps++)),
    );
    await tester.pumpAndSettle();

    final button = find.byKey(const ValueKey('schedule-today-button'));
    expect(button, findsOneWidget);
    await tester.tap(button);
    expect(taps, 1);
  });

  testWidgets('每个周次显示该周的缩略课表与课节数，并带图例', (tester) async {
    await tester.pumpWidget(_host(const SizedBox.shrink()));

    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showScheduleWeekSheet(
              context: context,
              weeks: _weeks(),
              selectedWeek: 13,
              currentWeek: 13,
              periodCount: 10,
              onSelect: (_) {},
            ),
            child: const Text('打开'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    // 图例说明颜色含义。
    expect(find.text('每周一张缩略课表'), findsOneWidget);
    expect(find.text('有课'), findsOneWidget);
    expect(find.text('本周'), findsOneWidget);

    // 单周有课、双周没课，缩略数据跟着周次变化。
    expect(find.bySemanticsLabel(RegExp('第 13 周.*1 节课.*本周')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('第 14 周.*0 节课')), findsOneWidget);
  });

  testWidgets('课少的周不会被拉伸：同一门课的方块高度一致', (tester) async {
    List<ScheduleWeekSlot> weeks = [
      (
        week: 3,
        monday: _monday,
        sunday: _monday.add(const Duration(days: 6)),
        isCurrent: false,
        // 这一周只有上午两节。
        days: [
          [_lesson('示例课程', 1, 1, 2)],
          for (var day = 1; day < DateTime.daysPerWeek; day++)
            <LessonOccurrence>[],
        ],
      ),
      (
        week: 4,
        monday: _monday.add(const Duration(days: 7)),
        sunday: _monday.add(const Duration(days: 13)),
        isCurrent: false,
        // 这一周有晚课，最大节次到 10。
        days: [
          [_lesson('示例课程', 1, 1, 2)],
          [_lesson('晚课', 2, 9, 10)],
          for (var day = 2; day < DateTime.daysPerWeek; day++)
            <LessonOccurrence>[],
        ],
      ),
    ];

    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showScheduleWeekSheet(
              context: context,
              weeks: weeks,
              selectedWeek: 3,
              currentWeek: 3,
              periodCount: 10,
              onSelect: (_) {},
            ),
            child: const Text('打开'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    final shortWeek = tester.getSize(
      find.byKey(const ValueKey('week-3-block-0-示例课程-1-1')),
    );
    final busyWeek = tester.getSize(
      find.byKey(const ValueKey('week-4-block-0-示例课程-1-1')),
    );
    final evening = tester.getSize(
      find.byKey(const ValueKey('week-4-block-1-晚课-2-9')),
    );

    // 两节课的方块在两个周次里一样高。
    expect(shortWeek.height, closeTo(busyWeek.height, 0.01));
    // 而且正好是整幅高度的 2/10（留出 1px 间隙）。
    expect(busyWeek.height, closeTo(104 / 10 * 2 - 1, 0.6));
    expect(evening.height, closeTo(busyWeek.height, 0.01));
  });
}
