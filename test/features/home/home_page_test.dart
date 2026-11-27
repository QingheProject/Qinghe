import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/theme/app_theme.dart';
import 'package:qinghe_app/app/widgets/app_detail_dialog.dart';
import 'package:qinghe_app/data/repositories/sample_timetable_repository.dart';
import 'package:qinghe_app/features/home/controllers/home_controller.dart';
import 'package:qinghe_app/features/home/views/home_page.dart';
import 'package:qinghe_app/features/home/widgets/today_lessons.dart';
import 'package:qinghe_app/features/home/widgets/week_activity_chart.dart';

void main() {
  testWidgets('今日课程可打开详情，活跃图随窗口切换排版', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1024, 800);
    addTearDown(tester.view.reset);
    addTearDown(Get.reset);
    Get.put(
      HomeController(
        SampleTimetableRepository(),
        clock: () => DateTime(2026, 11, 20, 10, 10),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: const Scaffold(body: HomePage()),
      ),
    );
    await tester.pumpAndSettle();

    final agenda = find.byType(TodayLessons);
    final chart = find.byType(WeekActivityChart);
    Finder course(String name) =>
        find.descendant(of: agenda, matching: find.text(name));
    expect(
      tester.getTopLeft(chart).dx,
      greaterThan(tester.getTopLeft(agenda).dx),
    );
    expect(find.text('共 12 次课'), findsOneWidget);
    expect(find.bySemanticsLabel('今天，星期五，2 次课'), findsOneWidget);
    semantics.dispose();
    expect(
      tester.getTopLeft(course('示例课程甲')).dy,
      greaterThan(tester.getTopLeft(course('示例课程戊')).dy),
    );

    await tester.tap(course('示例课程甲'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<AppDetailDialog>(find.byType(AppDetailDialog)).title,
      '示例课程甲',
    );
    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(320, 800);
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(
      tester.getTopLeft(chart).dy,
      greaterThan(tester.getTopLeft(agenda).dy),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
