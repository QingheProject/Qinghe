import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/app/theme/app_theme.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_week_switcher.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: Center(child: child)),
    ),
  );

  testWidgets('切周器显示当前教学周并回调前后周', (tester) async {
    var previous = 0;
    var next = 0;
    await pump(
      tester,
      ScheduleWeekSwitcher(
        teachingWeek: 11,
        direction: 1,
        onPrevious: () => previous++,
        onNext: () => next++,
      ),
    );

    expect(find.text('第 11 周'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('schedule-week-previous')));
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('schedule-week-next')));
    await tester.pump();

    expect(previous, 1);
    expect(next, 1);
  });

  testWidgets('学期外显示对应文案', (tester) async {
    await pump(
      tester,
      ScheduleWeekSwitcher(
        teachingWeek: null,
        direction: -1,
        onPrevious: () {},
        onNext: () {},
      ),
    );

    expect(find.text('学期外'), findsOneWidget);
  });

  testWidgets('回到本周按钮仅在非本周出现', (tester) async {
    var taps = 0;
    await pump(
      tester,
      ScheduleTodayButton(visible: false, onTap: () => taps++),
    );
    expect(find.byKey(const ValueKey('schedule-week-today')), findsNothing);

    await pump(tester, ScheduleTodayButton(visible: true, onTap: () => taps++));
    await tester.pumpAndSettle();

    final button = find.byKey(const ValueKey('schedule-week-today'));
    expect(button, findsOneWidget);
    await tester.tap(button);
    await tester.pump();
    expect(taps, 1);
  });
}
