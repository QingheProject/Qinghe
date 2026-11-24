import 'dart:convert';

import 'package:qinghe_app/data/import/jwxt/jwxt_ids.dart';
import 'package:qinghe_app/data/models/timetable_exam.dart';

/// 教务系统考试接口的解析结果。
///
/// 考试条目在拥挤的响应里可能有缺日期的记录，这类条目会被跳过并记录原因，
/// 由界面提示用户，而不是让整个导入失败。
class JwxtExamParse {
  const JwxtExamParse({required this.exams, required this.skipped});

  final List<TimetableExam> exams;

  /// 被跳过的条目说明，最多保留 [maxSkipped] 条。
  final List<String> skipped;

  static const maxSkipped = 10;

  /// 解析正方教务系统考试查询接口返回的 JSON。
  ///
  /// 字段名在不同版本间会变，这里按常见别名逐个尝试；识别不出日期就跳过，
  /// 让「没有考试」和「接口改版」可以区分开。
  static JwxtExamParse parse(String body, {required String semesterLabel}) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw const FormatException('教务系统返回的内容不是考试数据，可能登录已失效，请重新登录后重试。');
    }
    final items = _items(decoded);
    final exams = <TimetableExam>[];
    final skipped = <String>[];
    final ids = <String>{};
    for (final (index, item) in items.indexed) {
      try {
        final exam = _exam(item, semesterLabel);
        if (ids.add(exam.id)) exams.add(exam);
      } on FormatException catch (error) {
        if (skipped.length < maxSkipped) {
          skipped.add('第 ${index + 1} 条：${error.message}');
        }
      }
    }
    if (items.isNotEmpty && exams.isEmpty) {
      throw FormatException('${items.length} 场考试都无法解析（${skipped.first}）。');
    }
    return JwxtExamParse(
      exams: List.unmodifiable(exams),
      skipped: List.unmodifiable(skipped),
    );
  }

  static List<Map<String, dynamic>> _items(Object? decoded) {
    if (decoded is List) {
      return [
        for (final item in decoded)
          if (item is Map<String, dynamic>) item,
      ];
    }
    if (decoded is Map<String, dynamic>) {
      for (final key in const ['items', 'rows', 'ksList', 'data']) {
        final value = decoded[key];
        if (value is List) {
          return [
            for (final item in value)
              if (item is Map<String, dynamic>) item,
          ];
        }
      }
      // 有的版本在没有考试时返回空字符串或 null 字段，视为没有考试。
      return const [];
    }
    throw const FormatException('教务系统返回的数据格式无法识别。');
  }

  static TimetableExam _exam(Map<String, dynamic> item, String semesterLabel) {
    final name = _text(item, const ['kcmc', 'kc_mc', 'courseName']);
    if (name == null) throw const FormatException('缺少课程名称。');
    final when = _when(item);
    if (when == null) throw const FormatException('无法识别考试日期。');
    final location = _text(item, const ['cdmc', 'ksdd', 'jxdd', 'cd_mc']) ?? '';
    final seat = _text(item, const ['zwh', 'seat']) ?? '';
    final note =
        _text(item, const ['ksfsmc', 'ksxzmc', 'kslxmc', 'ksmc', 'bz']) ?? '';

    return TimetableExam(
      id:
          'E${jwxtFingerprint('exam|$name|${TimetableExam.formatDay(when.date)}|'
          '${when.start ?? ''}|$location')}',
      courseName: name,
      date: when.date,
      startMinute: when.start,
      endMinute: when.end,
      location: location,
      seat: seat,
      note: note,
      sourceNote: '教务系统 · $semesterLabel',
    );
  }

  /// 考试时间可能放在一个字段里，也可能拆成日期与时间几个字段。
  static _ExamTime? _when(Map<String, dynamic> item) {
    final combined = _text(item, const [
      'kssj',
      'kssjms',
      'kssjmsc',
      'kssjmc',
      'kssjview',
      'kssj_str',
    ]);
    var date = combined == null ? null : _date(combined);
    final times = combined == null ? <int>[] : _minutes(combined);
    if (date == null) {
      final raw = _text(item, const ['ksrq', 'ks_rq', 'date', 'rq']);
      date = raw == null ? null : _date(raw);
    }
    if (date == null) return null;
    // 时间可能单独给出：起止时间常在 kssj2／kssj3 这类字段里。
    final start = times.isNotEmpty
        ? times.first
        : _minuteOf(_text(item, const ['kssj2', 'ksapsj', 'startTime']));
    final end = times.length > 1
        ? times[1]
        : _minuteOf(_text(item, const ['kssj3', 'ksapend', 'endTime']));
    return _ExamTime(date: date, start: start, end: end);
  }

  static int? _minuteOf(String? text) {
    if (text == null) return null;
    final minutes = _minutes(text);
    return minutes.isEmpty ? null : minutes.first;
  }

  static DateTime? _date(String text) {
    final match = RegExp(
      r'(\d{4})\s*[-/.年]\s*(\d{1,2})\s*[-/.月]\s*(\d{1,2})',
    ).firstMatch(text);
    if (match == null) return null;
    final year = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    if (month < 1 || month > 12 || day < 1 || day > 31) return null;
    final date = DateTime(year, month, day);
    if (date.month != month || date.day != day) return null;
    return date;
  }

  static List<int> _minutes(String text) => [
    for (final match in RegExp(r'(\d{1,2})\s*[:：]\s*(\d{2})').allMatches(text))
      if (int.parse(match[1]!) < 24 && int.parse(match[2]!) < 60)
        int.parse(match[1]!) * 60 + int.parse(match[2]!),
  ];

  static String? _text(Map<String, dynamic> item, List<String> keys) {
    for (final key in keys) {
      final value = item[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text != 'null' && text != 'undefined') {
        return text;
      }
    }
    return null;
  }
}

class _ExamTime {
  const _ExamTime({required this.date, this.start, this.end});

  final DateTime date;
  final int? start;
  final int? end;
}
