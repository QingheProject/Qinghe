import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/data/import/jwxt/jwxt_kb_parser.dart';
import 'package:qinghe_app/data/import/jwxt/jwxt_probe.dart';
import 'package:qinghe_app/data/import/jwxt/jwxt_scripts.dart';
import 'package:qinghe_app/data/import/jwxt/jwxt_semester_options.dart';
import 'package:qinghe_app/data/import/timetable_import.dart';
import 'package:qinghe_app/data/import/timetable_import_preview.dart';
import 'package:qinghe_app/data/models/semester_config.dart';
import 'package:qinghe_app/data/sources/school_registry.dart';
import 'package:qinghe_app/data/sources/swust_source.dart';

const _semesterHtml = '''
<select id="xnm" name="xnm" class="form-control">
  <option value="2026" selected>2026-2027</option>
  <option value="2025">2025-2026</option>
</select>
<select name="xqm" id="xqm" class="form-control">
  <option value="3" selected>1</option>
  <option value="12">2</option>
</select>
''';

String _kb(List<Map<String, Object?>> items) => jsonEncode({'kbList': items});

Map<String, Object?> _row({
  String name = '示例课程',
  Object? code = 'C001',
  String weekdayCode = '1',
  String weekdayName = '星期一',
  String periods = '1-2节',
  String weeks = '1-16周',
  String teacher = '示例教师',
  String location = '示例教学楼 101',
}) => {
  'kcmc': name,
  'kch': code,
  'jxbmc': '示例教学班',
  'xm': teacher,
  'cdmc': location,
  'xqj': weekdayCode,
  'xqjmc': weekdayName,
  'jcs': periods,
  'zcd': weeks,
  'xqmc': '2026-2027 第一学期',
};

SemesterConfig _config() => SemesterConfig(
  name: '2026-2027 第一学期',
  week1Monday: DateTime(2026, 9, 7),
  weekCount: 18,
  periodStartTimes: const [
    '08:00',
    '08:55',
    '10:10',
    '11:05',
    '14:00',
    '14:55',
  ],
  periodDurationMinutes: 45,
);

void main() {
  test('学期下拉框解析出学年与学期，并保留页面默认值', () {
    final options = JwxtSemesterOptions.parse(_semesterHtml);
    expect(options.years.map((year) => year.value), ['2026', '2025']);
    expect(options.terms.map((term) => term.value), ['3', '12']);
    expect(options.defaultYear, '2026');
    expect(options.defaultTerm, '3');
    expect(options.labelOf('2026', '3'), '2026-2027 第一学期');
    expect(options.labelOf('2025', '12'), '2025-2026 第二学期');
  });

  test('课表 HTML 缺少学年或学期时明确报错', () {
    expect(
      () => JwxtSemesterOptions.parse('<div>登录已失效</div>'),
      throwsFormatException,
    );
  });

  test('课表条目转换为安排，单双周与节次正确展开', () {
    final parse = JwxtTimetableParse.parse(
      _kb([
        _row(weeks: '1-8周(单)'),
        _row(name: '实验示例课程', periods: '3-4节', weeks: '2-6周(双)'),
        _row(
          weekdayCode: '5',
          weekdayName: '星期五',
          periods: '5-6节',
          weeks: '1,3,5周',
        ),
      ]),
      semesterLabel: '2026-2027 第一学期',
    );

    expect(parse.skipped, isEmpty);
    expect(parse.rules, hasLength(3));
    expect(parse.rules[0].weeks, [1, 3, 5, 7]);
    expect(parse.rules[0].weekday, 1);
    expect(parse.rules[0].startPeriod, 1);
    expect(parse.rules[0].endPeriod, 2);
    expect(parse.rules[1].weeks, [2, 4, 6]);
    expect(parse.rules[1].type, 'lab');
    expect(parse.rules[1].courseId, 'C001');
    expect(parse.rules[2].weekday, 5);
    expect(parse.rules[2].weeks, [1, 3, 5]);
    expect(parse.rules[2].sourceNote, '教务系统 · 2026-2027 第一学期');
  });

  test('无法归入周课表的条目被跳过并记录原因', () {
    final parse = JwxtTimetableParse.parse(
      _kb([
        _row(),
        {'kcmc': '生产实习', 'zcd': '1-4周'},
        _row(name: '晚间课程', periods: '17-18节'),
      ]),
      semesterLabel: '2026-2027 第一学期',
    );

    expect(parse.rules, hasLength(1));
    expect(parse.skipped, hasLength(2));
    expect(parse.skipped.first, contains('无法识别上课星期'));
    expect(parse.skipped.last, contains('超出'));
  });

  test('重复条目只保留一条，编号在重复解析时保持稳定', () {
    final body = _kb([_row(), _row()]);
    final first = JwxtTimetableParse.parse(body, semesterLabel: '学期');
    final second = JwxtTimetableParse.parse(body, semesterLabel: '学期');

    expect(first.rules, hasLength(1));
    expect(first.rules.single.id, second.rules.single.id);
  });

  test('同一学期重复导入不新增安排，地点变化记为更新', () {
    final config = _config();
    final first = TimetableImport(
      JwxtTimetableParse.parse(_kb([_row()]), semesterLabel: '学期').rules,
    );
    final preview = TimetableImportPreview(
      base: null,
      config: config,
      incoming: first.rules,
    );
    expect(preview.added, hasLength(1));

    final sameBody = TimetableImport(
      JwxtTimetableParse.parse(_kb([_row()]), semesterLabel: '学期').rules,
    );
    final again = TimetableImportPreview(
      base: null,
      config: config,
      incoming: sameBody.rules,
    );
    expect(again.rules, hasLength(1));

    final moved = TimetableImport(
      JwxtTimetableParse.parse(
        _kb([_row(location: '示例教学楼 202')]),
        semesterLabel: '学期',
      ).rules,
    );
    final changed = TimetableImportPreview(
      base: null,
      config: config,
      incoming: moved.rules,
    );
    expect(changed.rules.single.location, '示例教学楼 202');
  });

  test('非 JSON、空列表和超范围节次给出可理解的错误', () {
    expect(
      () => JwxtTimetableParse.parse('<html>login</html>', semesterLabel: '学期'),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('不是课表数据'),
        ),
      ),
    );
    expect(
      () => JwxtTimetableParse.parse('{"kbList":[]}', semesterLabel: '学期'),
      throwsFormatException,
    );
    expect(
      () => JwxtTimetableParse.parse(
        _kb([_row(periods: '17-18节')]),
        semesterLabel: '学期',
      ),
      throwsFormatException,
    );
  });

  test('缺编号的课程按课程名与教师生成稳定编号', () {
    final parse = JwxtTimetableParse.parse(
      _kb([_row(code: null)]),
      semesterLabel: '学期',
    );
    final rule = parse.rules.single;
    expect(rule.courseId, startsWith('J'));
    expect(rule.courseId.length, 17);
  });

  test('取数脚本使用来源路径并拒绝非数字学期编码', () {
    final semesters = JwxtScripts.semesters(swustSource);
    expect(
      semesters,
      contains('/kbcx/xskbcxZccx_cxXskbcxIndex.html?gnmkdm=N2154'),
    );
    expect(semesters, contains(JwxtScripts.channel));

    final timetable = JwxtScripts.timetable(
      swustSource,
      year: '2026',
      term: '3',
    );
    expect(timetable, contains('/kbcx/xskbcxMobile_cxXsKb.html'));
    expect(timetable, contains('xnm=" + encodeURIComponent("2026")'));
    expect(timetable, contains('kblx=2'));

    expect(
      () => JwxtScripts.timetable(swustSource, year: '2026-2027', term: '3'),
      throwsFormatException,
    );
  });

  test('来源登记表只对已验证学校开放', () {
    expect(SchoolRegistry.forSchool(' 西南科技大学 ')?.school, '西南科技大学');
    expect(SchoolRegistry.forSchool('示例大学'), isNull);
    expect(swustSource.isVerified, isTrue);
    expect(
      swustSource.isSignedIn(Uri.parse('https://jwxt.swust.edu.cn/')),
      isTrue,
    );
    expect(
      swustSource.isSignedIn(
        Uri.parse('https://jwxt.swust.edu.cn/xtgl/login_slogin.html'),
      ),
      isFalse,
    );
    expect(
      swustSource.isSignedIn(
        Uri.parse('https://jwxt.swust.edu.cn/sso/zfiotlogin'),
      ),
      isFalse,
    );
  });

  test('字段探测只报告结构，不泄露取值', () {
    final summary = JwxtProbe.describe(_kb([_row()]));
    expect(summary, contains('kbList'));
    expect(summary, contains('kcmc:String'));
    expect(summary, isNot(contains('示例课程')));
  });
}
