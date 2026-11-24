import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_theme.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_week_sheet.dart';

final _monday = DateTime(2026, 11, 23);

List<ScheduleWeekSlot> _weeks({int count = 18, int current = 13}) => [
  for (var week = 1; week <= count; week++)
    (
      week: week,
      monday: _monday.add(Duration(days: 7 * (week - 1))),
      sunday: _monday.add(Duration(days: 7 * (week - 1) + 6)),
      isCurrent: week == current,
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
}
