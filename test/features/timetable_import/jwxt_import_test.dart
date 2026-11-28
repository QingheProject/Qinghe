import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_theme.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/app/widgets/app_sheet.dart';
import 'package:qinghe_app/data/import/jwxt/jwxt_grades.dart';
import 'package:qinghe_app/data/repositories/local_academic_repository.dart';
import 'package:qinghe_app/data/sources/swust_source.dart';
import 'package:qinghe_app/features/timetable_import/controllers/jwxt_import_controller.dart';
import 'package:qinghe_app/features/timetable_import/views/jwxt_grades_page.dart';
import 'package:qinghe_app/features/timetable_import/views/jwxt_import_page.dart';
import 'package:qinghe_app/features/timetable_import/widgets/jwxt_browser.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _semesters = '''
<select id="xnm" name="xnm">
  <option value="2026" selected>2026-2027</option>
</select>
<select id="xqm" name="xqm">
  <option value="3" selected>1</option>
  <option value="12">2</option>
</select>
''';

final _timetableBody = jsonEncode({
  'kbList': [
    {
      'kcmc': '示例课程',
      'kch': 'C001',
      'xm': '示例教师',
      'cdmc': '示例教学楼 101',
      'xqj': '1',
      'jcs': '1-2节',
      'zcd': '1-16周',
    },
  ],
});

final _examBody = jsonEncode({
  'items': [
    {
      'kcmc': '示例课程',
      'kssj': '2027-01-12 09:00-11:00',
      'cdmc': '示例考场',
      'zwh': '12',
      'ksfsmc': '闭卷',
    },
  ],
});

class _FakeBrowser implements JwxtBrowser {
  _FakeBrowser({required this.onMessage});

  final ValueChanged<String> onMessage;
  final scripts = <String>[];
  final opened = <Uri>[];
  var disposed = false;

  void reply(Map<String, Object?> payload) => onMessage(jsonEncode(payload));

  @override
  Widget get view => const SizedBox.expand();

  @override
  Future<void> open(Uri uri) async => opened.add(uri);

  @override
  Future<void> reload() async {}

  @override
  Future<void> run(String script) async => scripts.add(script);

  @override
  Future<void> dispose() async => disposed = true;
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Get.put(LocalAcademicRepository());
  });
  tearDown(Get.reset);

  test('旧缓存可筛选和去重，重复保存不会增加学分', () async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'local_academic_report_v1',
      jsonEncode({
        'school': swustSource.school,
        'semester': '2026-2027 第一学期',
        'grades': [
          {'course': '示例课程', 'credit': 2, 'point': 0, 'examType': '正常考试'},
          {'course': '示例课程', 'credit': 2, 'point': 3, 'examType': '补考'},
          {'course': '示例课程', 'credit': 2, 'point': 3, 'examType': '补考'},
        ],
      }),
    );

    final repository = LocalAcademicRepository();
    await repository.load();
    final report = repository.latestFor(swustSource.school)!;
    final grades = report.grades;
    expect(grades.grades, hasLength(2));
    expect(grades.years, ['2026-2027']);
    expect(grades.termsFor('2026-2027'), ['第一学期']);
    final selected = grades.filtered(year: '2026-2027', term: '第一学期');
    expect(selected.totalCredits, 2);
    expect(selected.estimatedGpa, 3);
    await repository.save(report);
    await repository.save(report);
    await repository.load();
    expect(
      repository.latestFor(swustSource.school)?.grades.grades,
      hasLength(2),
    );
  });

  testWidgets('查询全部成绩，按学年和学期筛选学分与加权绩点', (tester) async {
    late _FakeBrowser browser;
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.light,
        home: JwxtImportPage(
          source: swustSource,
          browserBuilder: ({required onMessage}) =>
              browser = _FakeBrowser(onMessage: onMessage),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('一键读取'));
    await tester.pump();
    browser.reply({'kind': 'semesters', 'html': _semesters});
    await tester.pump();
    browser.reply({'kind': 'timetable', 'body': _timetableBody});
    await tester.pump();
    browser.reply({'kind': 'exams', 'body': _examBody});
    await tester.pump();
    expect(browser.scripts, hasLength(4));
    expect(browser.scripts.last, contains('xnm=&xqm=&'));
    expect(browser.scripts.last, contains('course: scalar(row.kcmc)'));
    expect(browser.scripts.last, contains('courseCode: scalar(row.kch'));
    expect(browser.scripts.last, isNot(contains('row.xm')));
    expect(browser.scripts.last, isNot(contains('row.xh')));
    browser.reply({'kind': 'grades', 'rows': [], 'requestId': 0});
    await tester.pump();
    expect(find.text('正在读取全部成绩…'), findsOneWidget);
    browser.reply({
      'kind': 'grades',
      'requestId': 1,
      'rows': [
        {
          'course': '示例课程甲',
          'courseCode': 'C001',
          'score': '良好',
          'credit': '2',
          'point': '4',
          'courseType': '专业必修',
          'examType': '补考',
          'year': 2026,
          'termCode': '3',
          'name': '<姓名>',
          'studentNumber': '<学号>',
        },
        {
          'course': '示例课程甲',
          'courseCode': 'C001',
          'score': '不及格',
          'credit': 2,
          'point': 0,
          'examType': '正常考试',
          'year': 2026,
          'termCode': '3',
        },
        {
          'course': '示例课程乙',
          'score': 75,
          'credit': 1,
          'point': 1,
          'year': '2026-2027学年',
          'term': '2',
        },
        {
          'course': '示例课程丙',
          'credit': 3,
          'point': 2,
          'year': 2025,
          'term': '第一学期',
        },
      ],
    });
    await tester.pumpAndSettle();
    expect(find.text('全部成绩 · 4 条'), findsOneWidget);
    await tester.tap(find.text('查看成绩与绩点'));
    await tester.pumpAndSettle();
    expect(find.text('课程成绩 · 3 门'), findsOneWidget);
    expect(find.text('良好'), findsOneWidget);
    expect(find.text('专业必修'), findsOneWidget);
    final courseCard = find.ancestor(
      of: find.text('示例课程甲'),
      matching: find.byType(AppPanel),
    );
    final normal = find.descendant(of: courseCard, matching: find.text('正常考试'));
    final makeup = find.descendant(of: courseCard, matching: find.text('补考'));
    expect(courseCard, findsOneWidget);
    expect(normal, findsOneWidget);
    expect(makeup, findsOneWidget);
    expect(
      tester.getTopLeft(normal).dy,
      lessThan(tester.getTopLeft(makeup).dy),
    );
    expect(tester.widget<Text>(makeup).style?.color, AppColors.light.accent);
    expect(find.text('2.50'), findsOneWidget);
    expect(find.text('/ 5'), findsOneWidget);
    final gpaRing = find.byType(CircularProgressIndicator);
    double? ratio() => tester.widget<CircularProgressIndicator>(gpaRing).value;
    expect(ratio(), 0.5);
    expect(find.text('课程学分合计'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
    expect(find.text('<姓名>'), findsNothing);
    expect(find.text('<学号>'), findsNothing);
    expect(find.text('使用这份课表'), findsNothing);
    final coursesToggle = find.byKey(const ValueKey('academic-courses-toggle'));
    await tester.tap(coursesToggle);
    await tester.pumpAndSettle();
    expect(find.text('示例课程甲'), findsNothing);
    expect(find.text('课程成绩 · 3 门'), findsOneWidget);
    final yearFilter = find.byKey(const ValueKey('academic-year-filter'));
    final sheet = find.byType(AppSheet);
    Finder sheetOption(String label) =>
        find.descendant(of: sheet, matching: find.text(label));
    await tester.tap(yearFilter);
    await tester.pumpAndSettle();
    expect(sheetOption('选择学年'), findsOneWidget);
    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();
    expect(sheet, findsNothing);
    expect(find.text('课程成绩 · 3 门'), findsOneWidget);

    await tester.tap(yearFilter);
    await tester.pumpAndSettle();
    await tester.tap(sheetOption('2026-2027'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(ratio(), allOf(greaterThan(0.5), lessThan(0.6)));
    await tester.pumpAndSettle();
    expect(find.text('课程成绩 · 2 门'), findsOneWidget);
    expect(find.text('3.00'), findsOneWidget);
    expect(ratio(), 0.6);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('示例课程甲'), findsNothing);
    await tester.tap(coursesToggle);
    await tester.pumpAndSettle();
    expect(find.text('示例课程甲'), findsOneWidget);
    expect(find.text('示例课程丙'), findsNothing);

    final termFilter = find.byKey(
      const ValueKey('academic-term-filter-2026-2027'),
    );
    await tester.tap(termFilter);
    await tester.pumpAndSettle();
    expect(sheetOption('选择学期'), findsOneWidget);
    await tester.tap(sheetOption('第二学期'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    expect(ratio(), allOf(greaterThan(0.2), lessThan(0.6)));
    await tester.pumpAndSettle();
    expect(ratio(), 0.2);
    expect(find.text('课程成绩 · 1 门'), findsOneWidget);
    expect(find.text('1.00'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('示例课程乙'), findsOneWidget);
    expect(find.text('示例课程甲'), findsNothing);

    await tester.tap(yearFilter);
    await tester.pumpAndSettle();
    await tester.tap(sheetOption('2025-2026'));
    await tester.pumpAndSettle();
    expect(find.text('全部学期'), findsOneWidget);
    expect(find.text('2.00'), findsOneWidget);
    expect(find.text('示例课程丙'), findsOneWidget);

    final restored = LocalAcademicRepository();
    await restored.load();
    expect(restored.latestFor(swustSource.school)?.grades.estimatedGpa, 2.5);
    expect(restored.latestFor(swustSource.school)?.grades.years, [
      '2026-2027',
      '2025-2026',
    ]);
    expect(restored.latestFor('另一所示例大学'), isNull);
    final preferences = await SharedPreferences.getInstance();
    final persisted = preferences.getString('local_academic_report_v1');
    expect(persisted, isNot(contains('<姓名>')));
    expect(persisted, isNot(contains('<学号>')));
  });

  testWidgets('个人成绩在窄屏大字号下可用键盘筛选并滚动查看课程', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkFor(AppAccentTone.violet),
        home: JwxtGradesPage(
          semester: '全部成绩',
          gpaMaximum: 5,
          grades: JwxtGrades.parse([
            {
              'course': '示例课程名称较长时仍然可以完整阅读',
              'score': '优秀',
              'examType': '正常考试',
              'year': 2026,
              'termCode': '3',
            },
            {
              'course': '示例课程名称较长时仍然可以完整阅读',
              'score': '通过',
              'examType': '补考',
              'year': 2026,
              'termCode': '3',
            },
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final ringAnimation = find.byType(TweenAnimationBuilder<double>);
    expect(
      tester.widget<TweenAnimationBuilder<double>>(ringAnimation).duration,
      const Duration(milliseconds: 1),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('选择学年'), findsOneWidget);
    for (var index = 0; index < 3; index++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('2026-2027 学年 · 全部学期'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('通过'), 160);
    expect(find.text('示例课程名称较长时仍然可以完整阅读'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('一键读取依次请求学期、课表、考试和成绩并交出草稿', () async {
    late _FakeBrowser browser;
    final controller = JwxtImportController(
      swustSource,
      Get.find<LocalAcademicRepository>(),
    );
    browser = _FakeBrowser(onMessage: controller.handleMessage);
    controller.attach(browser);

    await controller.begin();
    expect(browser.opened.single, swustSource.entry);
    expect(controller.stage.value, JwxtImportStage.awaitingLogin);

    final reading = controller.readAll();
    await controller.readAll();
    await Future<void>.delayed(Duration.zero);
    expect(browser.scripts.single, contains('xskbcxZccx_cxXskbcxIndex.html'));
    browser.reply({'kind': 'semesters', 'html': _semesters});
    await Future<void>.delayed(Duration.zero);

    expect(controller.stage.value, JwxtImportStage.readingTimetable);
    expect(controller.year.value, '2026');
    expect(controller.term.value, '3');
    expect(controller.semesterLabel, '2026-2027 第一学期');

    expect(browser.scripts.last, contains('xskbcxMobile_cxXsKb.html'));
    browser.reply({'kind': 'timetable', 'body': _timetableBody});
    await Future<void>.delayed(Duration.zero);
    // 课表读到后会顺带读取考试，考试失败也不影响课表。
    expect(browser.scripts.last, contains('kscx_cxXsksxxIndex.html'));
    browser.reply({'kind': 'exams', 'body': _examBody});
    await Future<void>.delayed(Duration.zero);
    expect(controller.stage.value, JwxtImportStage.readingGrades);
    expect(controller.takeDraft(), isNull);
    browser.reply({'kind': 'grades', 'rows': [], 'requestId': 1});
    await reading;

    expect(controller.stage.value, JwxtImportStage.fetched);
    expect(controller.skipped, isEmpty);
    final draft = controller.takeDraft();
    expect(draft, isNotNull);
    expect(draft!.table.rules.single.name, '示例课程');
    expect(draft.table.rules.single.weekday, 1);
    expect(draft.exams.single.location, '示例考场');

    controller.selectSemester(null, '12');
    expect(controller.takeDraft(), isNull);
    final rereading = controller.readAll();
    await Future<void>.delayed(Duration.zero);
    expect(
      browser.scripts.last,
      contains('"&xqm=" + encodeURIComponent("12")'),
    );
    browser.reply({'kind': 'timetable', 'body': _timetableBody});
    await Future<void>.delayed(Duration.zero);
    browser.reply({'kind': 'exams', 'body': _examBody});
    await Future<void>.delayed(Duration.zero);
    browser.reply({'kind': 'grades', 'rows': [], 'requestId': 2});
    await rereading;
    expect(controller.semesterLabel, '2026-2027 第二学期');
  });

  test('考试和成绩读取失败时课表仍可导入，并记录各自原因', () async {
    late _FakeBrowser browser;
    final controller = JwxtImportController(
      swustSource,
      Get.find<LocalAcademicRepository>(),
    );
    browser = _FakeBrowser(onMessage: controller.handleMessage);
    controller.attach(browser);

    await controller.begin();
    final reading = controller.readAll();
    await Future<void>.delayed(Duration.zero);
    browser.reply({'kind': 'semesters', 'html': _semesters});
    await Future<void>.delayed(Duration.zero);
    browser.reply({'kind': 'timetable', 'body': _timetableBody});
    await Future<void>.delayed(Duration.zero);
    browser.reply({'kind': 'exams', 'body': '<html>登录页</html>'});
    await Future<void>.delayed(Duration.zero);
    browser.reply({'kind': 'error', 'reason': 'gradesFormat', 'requestId': 1});
    await reading;

    expect(controller.stage.value, JwxtImportStage.fetched);
    expect(controller.examResult.value, isNull);
    expect(controller.examIssue.value, contains('不是考试数据'));
    expect(controller.gradesIssue.value, contains('成绩接口未返回'));
    final draft = controller.takeDraft();
    expect(draft?.table.rules, hasLength(1));
    expect(draft?.exams, isEmpty);
  });

  test('页面请求失败时停在失败阶段并给出提示', () async {
    late _FakeBrowser browser;
    final controller = JwxtImportController(
      swustSource,
      Get.find<LocalAcademicRepository>(),
    );
    browser = _FakeBrowser(onMessage: controller.handleMessage);
    controller.attach(browser);

    await controller.begin();
    final reading = controller.readAll();
    await Future<void>.delayed(Duration.zero);
    browser.reply({'kind': 'error', 'status': 302});
    await reading;

    expect(controller.stage.value, JwxtImportStage.failed);
    expect(controller.error.value, contains('302'));
    expect(controller.takeDraft(), isNull);
  });

  test('课表请求失败时仍可读取和保存全部成绩', () async {
    final repository = Get.find<LocalAcademicRepository>();
    final controller = JwxtImportController(swustSource, repository);
    final browser = _FakeBrowser(onMessage: controller.handleMessage);
    controller.attach(browser);
    await controller.begin();

    final reading = controller.readAll();
    await Future<void>.delayed(Duration.zero);
    browser.reply({'kind': 'semesters', 'html': _semesters});
    await Future<void>.delayed(Duration.zero);
    browser.reply({'kind': 'error', 'status': 500});
    await Future<void>.delayed(Duration.zero);
    browser.reply({
      'kind': 'grades',
      'requestId': 1,
      'rows': [
        {'course': '示例课程', 'credit': 2, 'point': 3},
      ],
    });
    await reading;

    expect(controller.stage.value, JwxtImportStage.failed);
    expect(controller.error.value, contains('500'));
    expect(controller.takeDraft(), isNull);
    expect(controller.gradesResult.value?.estimatedGpa, 3);
    expect(repository.latestFor(swustSource.school)?.grades.totalCredits, 2);
  });

  testWidgets('导入页按阶段给出提示，并展示读取到的安排数量', (tester) async {
    late _FakeBrowser browser;
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightFor(AppAccentTone.qinghe),
        home: JwxtImportPage(
          source: swustSource,
          browserBuilder: ({required onMessage}) =>
              browser = _FakeBrowser(onMessage: onMessage),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('西南科技大学 · 教务系统'), findsOneWidget);
    expect(find.text('请先在上方页面登录，再点击「一键读取」。'), findsOneWidget);
    expect(find.text('读取全部成绩与绩点'), findsNothing);

    await tester.tap(find.text('一键读取'));
    await tester.pump();
    expect(browser.scripts.single, contains('xskbcxZccx_cxXskbcxIndex.html'));

    browser.reply({'kind': 'semesters', 'html': _semesters});
    await tester.pump();
    expect(find.text('正在读取课表…'), findsOneWidget);
    browser.reply({'kind': 'timetable', 'body': _timetableBody});
    await tester.pump();
    browser.reply({'kind': 'exams', 'body': _examBody});
    await tester.pump();
    expect(find.text('正在读取全部成绩…'), findsOneWidget);
    expect(find.text('使用这份课表'), findsNothing);
    browser.reply({'kind': 'error', 'reason': 'gradesFormat', 'requestId': 1});
    await tester.pump();

    expect(find.text('已读取 1 条上课安排'), findsOneWidget);
    expect(find.text('考试信息 1 场'), findsOneWidget);
    expect(find.text('成绩未获取'), findsOneWidget);
    expect(find.text('学年'), findsOneWidget);
    expect(find.text('使用这份课表'), findsOneWidget);
  });
}
