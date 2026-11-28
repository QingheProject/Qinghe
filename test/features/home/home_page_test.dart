import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/student_profile_controller.dart';
import 'package:qinghe_app/app/theme/app_theme.dart';
import 'package:qinghe_app/app/widgets/app_detail_dialog.dart';
import 'package:qinghe_app/data/import/jwxt/jwxt_grades.dart';
import 'package:qinghe_app/data/repositories/local_academic_repository.dart';
import 'package:qinghe_app/data/repositories/sample_timetable_repository.dart';
import 'package:qinghe_app/data/sources/swust_source.dart';
import 'package:qinghe_app/features/home/controllers/home_controller.dart';
import 'package:qinghe_app/features/home/views/home_page.dart';
import 'package:qinghe_app/features/home/widgets/course_activity_heatmap.dart';
import 'package:qinghe_app/features/home/widgets/today_lessons.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('热力表在时间线之上，课程卡留有间距且可打开详情', (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1024, 800);
    addTearDown(tester.view.reset);
    addTearDown(Get.reset);
    SharedPreferences.setMockInitialValues({});
    final profile = Get.put(StudentProfileController());
    await profile.save(school: swustSource.school, nickname: '');
    final academics = Get.put(LocalAcademicRepository());
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
    final chart = find.byType(CourseActivityHeatmap);
    Finder course(String name) =>
        find.descendant(of: agenda, matching: find.text(name));
    expect(
      tester.getBottomLeft(chart).dy,
      lessThan(tester.getTopLeft(agenda).dy),
    );
    final cells = find.descendant(
      of: chart,
      matching: find.byType(AspectRatio),
    );
    expect(cells, findsNWidgets(28));
    expect(tester.getSize(cells.first).aspectRatio, closeTo(1, 0.001));
    final firstCell = tester.widget<DecoratedBox>(
      find.descendant(of: cells.first, matching: find.byType(DecoratedBox)),
    );
    expect(
      (firstCell.decoration as BoxDecoration).color,
      const Color(0xFF77BD91),
    );
    expect(
      find.descendant(
        of: cells,
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Text && RegExp(r'\d').hasMatch(widget.data ?? ''),
        ),
      ),
      findsNothing,
    );
    expect(find.text('10/26'), findsOneWidget);
    expect(find.text('11/16'), findsOneWidget);
    expect(find.bySemanticsLabel('今天，11月20日，2 次课'), findsOneWidget);
    semantics.dispose();
    await tester.tap(cells.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final bubble = find.text('课程: 2');
    final fade = find.ancestor(
      of: bubble,
      matching: find.byType(FadeTransition),
    );
    double bubbleOpacity() =>
        tester.widget<FadeTransition>(fade.first).opacity.value;
    expect(
      tester.getBottomLeft(bubble).dy,
      lessThan(tester.getTopLeft(cells.first).dy),
    );
    expect(bubbleOpacity(), allOf(greaterThan(0), lessThan(1)));
    await tester.pump(const Duration(milliseconds: 150));
    expect(bubbleOpacity(), 1);
    Tooltip.dismissAllToolTips();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 25));
    expect(bubbleOpacity(), allOf(greaterThan(0), lessThan(1)));
    await tester.pumpAndSettle();
    expect(bubble, findsNothing);
    expect(
      tester.getTopLeft(course('示例课程甲')).dy,
      greaterThan(tester.getTopLeft(course('示例课程戊')).dy),
    );
    final timelineCards = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key as ValueKey<String>).value.startsWith('today-lesson-'),
    );
    expect(timelineCards, findsNWidgets(2));
    expect(
      tester.getTopLeft(timelineCards.last).dy -
          tester.getBottomLeft(timelineCards.first).dy,
      greaterThanOrEqualTo(12),
    );
    expect(find.text('未获取到成绩与绩点'), findsOneWidget);

    await academics.save((
      school: swustSource.school,
      semester: '示例学期',
      grades: JwxtGrades.parse([
        {'course': '示例课程', 'credit': 2, 'point': 3.5, 'courseType': '必修'},
      ]),
    ));
    await tester.pumpAndSettle();
    expect(find.text('未获取到成绩与绩点'), findsNothing);
    expect(find.text('3.50'), findsOneWidget);
    expect(find.text('/ 5'), findsOneWidget);
    expect(find.text('课程学分合计'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('必修'), findsNothing);
    expect(
      tester.getTopLeft(find.text('绩点')).dy,
      tester.getTopLeft(find.text('学分')).dy,
    );
    expect(find.byTooltip('查看课表'), findsNothing);
    expect(find.byTooltip('成绩与学分详情'), findsNothing);

    await tester.tap(course('示例课程甲'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<AppDetailDialog>(find.byType(AppDetailDialog)).title,
      '示例课程甲',
    );
    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('绩点'));
    await tester.pumpAndSettle();
    expect(find.text('示例课程'), findsOneWidget);
    expect(find.text('个人成绩'), findsOneWidget);
    expect(find.text('课程学分合计'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    tester.view.physicalSize = const Size(320, 800);
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(chart).dy, lessThan(tester.getTopLeft(agenda).dy));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
