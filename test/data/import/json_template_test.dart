import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/data/import/timetable_import.dart';

void main() {
  test('内置 JSON 模板可以直接导入', () {
    final draft = TimetableImport.parseJson(TimetableImport.jsonTemplate);

    expect(draft.rules, hasLength(1));
    final rule = draft.rules.single;
    expect(rule.name, isNotEmpty);
    expect(rule.weekday, 1);
    expect(rule.weeks, contains(1));
    expect(rule.startPeriod, 1);
    expect(rule.endPeriod, 2);
    expect(draft.config, isNotNull);
    expect(draft.config!.weekCount, greaterThanOrEqualTo(rule.weeks.last));
    expect(draft.config!.periodStartTimes.length, greaterThan(1));
  });

  test('模板导出后再导入得到同样的安排', () {
    final once = TimetableImport.parseJson(TimetableImport.jsonTemplate);
    final again = TimetableImport.parseJson(jsonEncode(once.toJson()));

    expect(again.rules.single.id, once.rules.single.id);
    expect(again.rules.single.weeks, once.rules.single.weeks);
    expect(again.config!.firstDay, once.config!.firstDay);
    expect(again.config!.periodStartTimes, once.config!.periodStartTimes);
  });

  test('空内容与非法 JSON 给出可读的报错', () {
    expect(
      () => TimetableImport.parseJson(''),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => TimetableImport.parseJson('{'),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('JSON'),
        ),
      ),
    );
  });
}
