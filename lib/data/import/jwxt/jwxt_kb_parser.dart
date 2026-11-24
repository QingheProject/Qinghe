import 'dart:convert';

import 'package:qinghe_app/data/import/jwxt/jwxt_ids.dart';
import 'package:qinghe_app/data/models/semester_config.dart';
import 'package:qinghe_app/data/models/timetable_rule.dart';

/// 教务系统课表接口的解析结果。
///
/// 真实教务数据里常有无法归入周课表的条目（例如没有星期与节次的实习安排），
/// 这些条目会被跳过并记录原因，由界面提示用户，而不是让整个导入失败。
class JwxtTimetableParse {
  const JwxtTimetableParse({required this.rules, required this.skipped});

  final List<TimetableRule> rules;

  /// 被跳过的条目说明，最多保留 [maxSkipped] 条。
  final List<String> skipped;

  static const maxSkipped = 10;

  /// 解析正方教务系统课表接口返回的 JSON。
  ///
  /// [semesterLabel] 会写入每条安排的来源备注，便于与其它来源区分。
  static JwxtTimetableParse parse(
    String body, {
    required String semesterLabel,
  }) {
    final Object? decoded;
    try {
      decoded = jsonDecode(body);
    } on FormatException {
      throw const FormatException('教务系统返回的内容不是课表数据，可能登录已失效，请重新登录后重试。');
    }
    final items = _items(decoded);
    if (items.isEmpty) throw const FormatException('教务系统没有返回任何上课安排。');

    final rules = <TimetableRule>[];
    final skipped = <String>[];
    final ids = <String>{};
    for (final (index, item) in items.indexed) {
      try {
        final rule = _rule(item, semesterLabel);
        if (ids.add(rule.id)) rules.add(rule);
      } on FormatException catch (error) {
        if (skipped.length < maxSkipped) {
          skipped.add('第 ${index + 1} 条：${error.message}');
        }
      }
    }
    if (rules.isEmpty) {
      throw FormatException('课表中的 ${items.length} 条安排都无法解析（${skipped.first}）。');
    }
    return JwxtTimetableParse(
      rules: List.unmodifiable(rules),
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
      for (final key in const ['kbList', 'kbList1']) {
        final value = decoded[key];
        if (value is List) {
          return [
            for (final item in value)
              if (item is Map<String, dynamic>) item,
          ];
        }
      }
      throw const FormatException('教务系统返回的数据里没有课表列表。');
    }
    throw const FormatException('教务系统返回的数据格式无法识别。');
  }

  static TimetableRule _rule(Map<String, dynamic> item, String semesterLabel) {
    final name = _text(item, const ['kcmc']);
    if (name == null) throw const FormatException('缺少课程名称。');
    final weekday = _weekday(item);
    final (startPeriod, endPeriod) = _periods(item);
    final weeks = _weeks(item);
    final teacher = _text(item, const ['xm', 'jsxm']) ?? '';
    final location = _text(item, const ['cdmc', 'jxdd']) ?? '';
    final code = _text(item, const ['kch', 'kch_id']);
    final type = name.contains('实验') ? 'lab' : 'regular';

    return TimetableRule(
      // 安排编号取自课程、星期、节次与周次，重导入同一学期的数据会命中同一条安排。
      id:
          'J${_fingerprint('rule|$name|$weekday|$startPeriod-$endPeriod|'
          '${weeks.join(',')}')}',
      courseId: code ?? 'J${_fingerprint('course|$name|$teacher')}',
      name: name,
      type: type,
      weekday: weekday,
      weeks: weeks,
      startPeriod: startPeriod,
      endPeriod: endPeriod,
      location: location,
      teacher: teacher,
      sourceNote: '教务系统 · $semesterLabel',
    );
  }

  static int _weekday(Map<String, dynamic> item) {
    final numeric = int.tryParse(_text(item, const ['xqj']) ?? '');
    if (numeric != null && numeric >= 1 && numeric <= 7) return numeric;
    final text = _text(item, const ['xqjmc', 'xqj']);
    final weekday = text == null ? null : _weekdayNames[text.trim()];
    if (weekday == null) throw const FormatException('无法识别上课星期。');
    return weekday;
  }

  static const _weekdayNames = {
    '星期一': 1,
    '星期二': 2,
    '星期三': 3,
    '星期四': 4,
    '星期五': 5,
    '星期六': 6,
    '星期日': 7,
    '星期天': 7,
    '周一': 1,
    '周二': 2,
    '周三': 3,
    '周四': 4,
    '周五': 5,
    '周六': 6,
    '周日': 7,
    '周天': 7,
  };

  static (int, int) _periods(Map<String, dynamic> item) {
    final text = _text(item, const ['jcs', 'jcor', 'jc']);
    if (text == null) throw const FormatException('缺少上课节次。');
    final numbers = [
      for (final match in RegExp(r'\d+').allMatches(text))
        int.parse(match.group(0)!),
    ];
    if (numbers.isEmpty) throw const FormatException('无法识别上课节次。');
    final start = numbers.first;
    final end = numbers.last;
    if (start < 1 || end < start || end > SemesterConfig.maxPeriods) {
      throw FormatException('节次「$text」超出 1–${SemesterConfig.maxPeriods} 节的范围。');
    }
    return (start, end);
  }

  static List<int> _weeks(Map<String, dynamic> item) {
    final text = _text(item, const ['zcd', 'zcmc']);
    if (text == null) throw const FormatException('缺少上课周次。');
    final cleaned = text
        .replaceAll(RegExp(r'[（()）]'), ' ')
        .replaceAll('周', ' ');
    final odd = cleaned.contains('单');
    final even = cleaned.contains('双');
    final weeks = <int>{};
    for (final part in cleaned.split(RegExp(r'[,，、;；]'))) {
      final digits = part.replaceAll(RegExp(r'[^\d-]'), '');
      if (digits.isEmpty) continue;
      final match = RegExp(r'^(\d+)(?:-(\d+))?$').firstMatch(digits);
      if (match == null) throw FormatException('无法识别周次「$text」。');
      final start = int.parse(match.group(1)!);
      final end = int.parse(match.group(2) ?? match.group(1)!);
      if (start < 1 || end < start || end > 60) {
        throw FormatException('周次「$text」超出 1–60 周的范围。');
      }
      for (var week = start; week <= end; week++) {
        if (odd && week.isEven) continue;
        if (even && week.isOdd) continue;
        weeks.add(week);
      }
    }
    if (weeks.isEmpty) throw FormatException('周次「$text」没有有效的教学周。');
    return weeks.toList()..sort();
  }

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

  /// FNV-1a 64 位，用于生成稳定且不暴露内容的编号。
  static String _fingerprint(String input) => jwxtFingerprint(input);
}
