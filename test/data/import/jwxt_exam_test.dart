import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/data/import/jwxt/jwxt_exam_parser.dart';

void main() {
  test('解析带完整时间的考试条目', () {
    final body = jsonEncode({
      'items': [
        {
          'kcmc': '示例课程甲',
          'kssj': '2027-01-12 09:00-11:00',
          'cdmc': '示例楼 A201',
          'zwh': '12',
          'ksfsmc': '闭卷',
        },
      ],
    });

    final parsed = JwxtExamParse.parse(body, semesterLabel: '2026-2027 第一学期');

    final exam = parsed.exams.single;
    expect(exam.courseName, '示例课程甲');
    expect(exam.date, DateTime(2027, 1, 12));
    expect(exam.startMinute, 9 * 60);
    expect(exam.endMinute, 11 * 60);
    expect(exam.timeLabel, '09:00–11:00');
    expect(exam.location, '示例楼 A201');
    expect(exam.seat, '12');
    expect(exam.note, '闭卷');
    expect(exam.sourceNote, '教务系统 · 2026-2027 第一学期');
    expect(parsed.skipped, isEmpty);
  });

  test('日期与时间分字段时也能解析', () {
    final body = jsonEncode({
      'rows': [
        {'kcmc': '示例课程乙', 'ksrq': '2027-01-15', 'kssj2': '14:30'},
      ],
    });

    final parsed = JwxtExamParse.parse(body, semesterLabel: '测试学期');

    final exam = parsed.exams.single;
    expect(exam.date, DateTime(2027, 1, 15));
    expect(exam.startMinute, 14 * 60 + 30);
    expect(exam.endMinute, isNull);
    expect(exam.timeLabel, '14:30');
  });

  test('只有日期的考试保留日期、不带时间', () {
    final body = jsonEncode([
      {'kcmc': '示例课程丙', 'kssj': '2027年1月20日 待定', 'cdmc': '示例楼 B101'},
    ]);

    final exam = JwxtExamParse.parse(body, semesterLabel: '测试学期').exams.single;

    expect(exam.date, DateTime(2027, 1, 20));
    expect(exam.hasTime, isFalse);
    expect(exam.timeLabel, isEmpty);
    expect(exam.durationMinutes, 90);
  });

  test('缺少日期的条目被跳过并记录原因', () {
    final body = jsonEncode({
      'items': [
        {'kcmc': '示例课程丁', 'kssj': '时间待定'},
        {'kcmc': '示例课程戊', 'kssj': '2027-01-18 08:00-10:00'},
      ],
    });

    final parsed = JwxtExamParse.parse(body, semesterLabel: '测试学期');

    expect(parsed.exams, hasLength(1));
    expect(parsed.exams.single.courseName, '示例课程戊');
    expect(parsed.skipped.single, contains('无法识别考试日期'));
  });

  test('没有考试时返回空列表', () {
    final parsed = JwxtExamParse.parse(
      jsonEncode({'items': const []}),
      semesterLabel: '测试学期',
    );

    expect(parsed.exams, isEmpty);
    expect(parsed.skipped, isEmpty);
  });

  test('返回登录页等内容时报错，提示重新登录', () {
    expect(
      () => JwxtExamParse.parse('<html>登录</html>', semesterLabel: '测试学期'),
      throwsA(
        isA<FormatException>().having(
          (error) => error.message,
          'message',
          contains('不是考试数据'),
        ),
      ),
    );
  });

  test('同一条考试重复出现时只保留一条', () {
    final item = {
      'kcmc': '示例课程己',
      'kssj': '2027-01-19 09:00-11:00',
      'cdmc': '示例楼 C301',
    };
    final parsed = JwxtExamParse.parse(
      jsonEncode({
        'items': [item, item],
      }),
      semesterLabel: '测试学期',
    );

    expect(parsed.exams, hasLength(1));
  });
}
