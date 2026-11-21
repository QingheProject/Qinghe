import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/theme/app_theme.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_period_label.dart';

void main() {
  group('节次栏宽度', () {
    test('隐藏时间时只留节次数字的宽度', () {
      expect(
        SchedulePeriodLabel.railWidthFor(
          showTime: false,
          textLayout: ScheduleRailTextLayout.sideBySide,
        ),
        28,
      );
    });

    test('竖排布局宽度一致，并排布局额外加宽', () {
      final periodFirst = SchedulePeriodLabel.railWidthFor(
        showTime: true,
        textLayout: ScheduleRailTextLayout.periodFirst,
      );
      final timeFirst = SchedulePeriodLabel.railWidthFor(
        showTime: true,
        textLayout: ScheduleRailTextLayout.timeFirst,
      );
      final sideBySide = SchedulePeriodLabel.railWidthFor(
        showTime: true,
        textLayout: ScheduleRailTextLayout.sideBySide,
      );

      expect(periodFirst, timeFirst);
      expect(sideBySide, greaterThan(periodFirst));
    });
  });

  group('节次与时间的排列', () {
    Future<void> pumpLabel(
      WidgetTester tester,
      ScheduleRailTextLayout layout, {
      bool showTime = true,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: SchedulePeriodLabel.railWidthFor(
                  showTime: showTime,
                  textLayout: layout,
                ),
                child: SchedulePeriodLabel(
                  period: 3,
                  showTime: showTime,
                  startTime: '10:00',
                  endTime: '10:45',
                  alignment: ScheduleTimeAlignment.center,
                  textLayout: layout,
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('节次在上时数字位于时间之上', (tester) async {
      await pumpLabel(tester, ScheduleRailTextLayout.periodFirst);

      final periodTop = tester.getTopLeft(find.text('3')).dy;
      final timeTop = tester.getTopLeft(find.text('10:00')).dy;
      expect(periodTop, lessThan(timeTop));
    });

    testWidgets('时间在上时时间位于数字之上', (tester) async {
      await pumpLabel(tester, ScheduleRailTextLayout.timeFirst);

      final periodTop = tester.getTopLeft(find.text('3')).dy;
      final timeTop = tester.getTopLeft(find.text('10:00')).dy;
      expect(timeTop, lessThan(periodTop));
    });

    testWidgets('并排时数字位于时间左侧且共用一行', (tester) async {
      await pumpLabel(tester, ScheduleRailTextLayout.sideBySide);

      final periodBox = tester.getRect(find.text('3'));
      final timeBox = tester.getRect(find.text('10:00'));
      expect(periodBox.right, lessThanOrEqualTo(timeBox.left));
      expect(periodBox.center.dy, closeTo(timeBox.center.dy, 12));
    });

    testWidgets('关闭时间后只剩节次数字', (tester) async {
      await pumpLabel(
        tester,
        ScheduleRailTextLayout.periodFirst,
        showTime: false,
      );

      expect(find.text('3'), findsOneWidget);
      expect(find.text('10:00'), findsNothing);
      expect(find.text('10:45'), findsNothing);
    });

    testWidgets('节次数字比时间更醒目，两者颜色不同', (tester) async {
      await pumpLabel(tester, ScheduleRailTextLayout.periodFirst);

      final periodStyle = tester.widget<Text>(find.text('3')).style!;
      final timeStyle = tester.widget<Text>(find.text('10:00')).style!;

      expect(periodStyle.fontWeight, FontWeight.w800);
      expect(periodStyle.fontSize, greaterThan(timeStyle.fontSize!));
      expect(periodStyle.color, isNot(timeStyle.color));
      expect(
        timeStyle.fontWeight!.index,
        lessThan(periodStyle.fontWeight!.index),
      );
    });
  });
}
