import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_theme.dart';
import 'package:qinghe_app/data/sources/swust_source.dart';
import 'package:qinghe_app/features/timetable_import/controllers/jwxt_import_controller.dart';
import 'package:qinghe_app/features/timetable_import/views/jwxt_import_page.dart';
import 'package:qinghe_app/features/timetable_import/widgets/jwxt_browser.dart';

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
  test('控制器按学期读取课表并交出待导入草稿', () async {
    late _FakeBrowser browser;
    final controller = JwxtImportController(swustSource);
    browser = _FakeBrowser(onMessage: controller.handleMessage);
    controller.attach(browser);

    await controller.begin();
    expect(browser.opened.single, swustSource.entry);
    expect(controller.stage.value, JwxtImportStage.awaitingLogin);

    final readingSemesters = controller.readSemesters();
    await Future<void>.delayed(Duration.zero);
    expect(browser.scripts.last, contains('xskbcxZccx_cxXskbcxIndex.html'));
    browser.reply({'kind': 'semesters', 'html': _semesters});
    await readingSemesters;

    expect(controller.stage.value, JwxtImportStage.choosingSemester);
    expect(controller.year.value, '2026');
    expect(controller.term.value, '3');
    expect(controller.semesterLabel, '2026-2027 第一学期');

    final readingTimetable = controller.readTimetable();
    await Future<void>.delayed(Duration.zero);
    expect(browser.scripts.last, contains('xskbcxMobile_cxXsKb.html'));
    browser.reply({'kind': 'timetable', 'body': _timetableBody});
    await Future<void>.delayed(Duration.zero);
    // 课表读到后会顺带读取考试，考试失败也不影响课表。
    expect(browser.scripts.last, contains('kscx_cxXsksxxIndex.html'));
    browser.reply({'kind': 'exams', 'body': _examBody});
    await readingTimetable;

    expect(controller.stage.value, JwxtImportStage.fetched);
    expect(controller.skipped, isEmpty);
    final draft = controller.takeDraft();
    expect(draft, isNotNull);
    expect(draft!.table.rules.single.name, '示例课程');
    expect(draft.table.rules.single.weekday, 1);
    expect(draft.exams.single.location, '示例考场');
  });

  test('考试读取失败时课表仍可导入，并记录考试原因', () async {
    late _FakeBrowser browser;
    final controller = JwxtImportController(swustSource);
    browser = _FakeBrowser(onMessage: controller.handleMessage);
    controller.attach(browser);

    await controller.begin();
    final readingSemesters = controller.readSemesters();
    await Future<void>.delayed(Duration.zero);
    browser.reply({'kind': 'semesters', 'html': _semesters});
    await readingSemesters;

    final readingTimetable = controller.readTimetable();
    await Future<void>.delayed(Duration.zero);
    browser.reply({'kind': 'timetable', 'body': _timetableBody});
    await Future<void>.delayed(Duration.zero);
    browser.reply({'kind': 'exams', 'body': '<html>登录页</html>'});
    await readingTimetable;

    expect(controller.stage.value, JwxtImportStage.fetched);
    expect(controller.examResult.value, isNull);
    expect(controller.examIssue.value, contains('不是考试数据'));
    final draft = controller.takeDraft();
    expect(draft?.table.rules, hasLength(1));
    expect(draft?.exams, isEmpty);
  });

  test('页面请求失败时停在失败阶段并给出提示', () async {
    late _FakeBrowser browser;
    final controller = JwxtImportController(swustSource);
    browser = _FakeBrowser(onMessage: controller.handleMessage);
    controller.attach(browser);

    await controller.begin();
    final reading = controller.readSemesters();
    await Future<void>.delayed(Duration.zero);
    browser.reply({'kind': 'error', 'status': 302});
    await reading;

    expect(controller.stage.value, JwxtImportStage.failed);
    expect(controller.error.value, contains('302'));
    expect(controller.takeDraft(), isNull);
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
    expect(find.text('请在上方页面完成登录，然后读取课表。'), findsOneWidget);

    await tester.tap(find.text('我已登录，读取学期'));
    await tester.pump();
    expect(browser.scripts.single, contains('xskbcxZccx_cxXskbcxIndex.html'));

    browser.reply({'kind': 'semesters', 'html': _semesters});
    await tester.pump();
    expect(find.text('选择要导入的学年与学期。'), findsOneWidget);
    expect(find.text('学年'), findsOneWidget);

    await tester.tap(find.text('读取本学期课表'));
    await tester.pump();
    browser.reply({'kind': 'timetable', 'body': _timetableBody});
    await tester.pump();
    browser.reply({'kind': 'exams', 'body': _examBody});
    await tester.pump();

    expect(find.text('已读取 1 条上课安排'), findsOneWidget);
    expect(find.text('考试信息 1 场'), findsOneWidget);
    expect(find.text('使用这份课表'), findsOneWidget);
  });
}
