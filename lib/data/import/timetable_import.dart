import 'dart:convert';

import 'package:qinghe_app/data/models/semester_config.dart';
import 'package:qinghe_app/data/models/timetable_rule.dart';

class TimetableImport {
  const TimetableImport(this.rules, {this.config});

  final List<TimetableRule> rules;
  final SemesterConfig? config;

  static const maxBytes = 1024 * 1024;
  static const maxRules = 2000;

  /// 可直接粘贴修改的 JSON 模板，字段顺序与 [toJson] 输出一致。
  static const jsonTemplate = '''
{
  "version": 1,
  "semester": {
    "name": "示例学期",
    "week1Monday": "2026-09-07",
    "weekCount": 18,
    "periodStartTimes": ["08:00", "08:55", "10:00", "10:55"],
    "periodDurationMinutes": 45
  },
  "courses": [
    {
      "id": "C001",
      "name": "示例课程甲",
      "type": "regular",
      "rules": [
        {
          "id": "R001",
          "weekday": 1,
          "weeks": [
            1, 2, 3, 4, 5, 6, 7, 8,
            9, 10, 11, 12, 13, 14, 15, 16
          ],
          "startPeriod": 1,
          "endPeriod": 2,
          "location": "示例教室",
          "teacher": "示例老师",
          "sourceNote": "手写导入"
        }
      ]
    }
  ]
}
''';

  /// 解析粘贴或读取到的 JSON 文本。
  factory TimetableImport.parseJson(String text) {
    if (text.startsWith('\uFEFF')) text = text.substring(1);
    if (text.length > maxBytes) {
      throw const FormatException('内容超过 1 MB，请精简后导入。');
    }
    final draft = _readJson(text);
    if (draft.rules.isEmpty || draft.rules.length > maxRules) {
      throw const FormatException('应包含 1–2000 条上课安排。');
    }
    return draft;
  }

  factory TimetableImport.fromJson(Map<String, dynamic> map) {
    if (map['version'] != 1) {
      throw const FormatException('仅支持青禾 JSON 版本 1。');
    }
    final semester = map['semester'];
    return TimetableImport(
      _readCourses(map['courses']),
      config: semester == null
          ? null
          : _readConfig(_object(semester, 'semester')),
    );
  }

  Map<String, Object> toJson() {
    final courses = <String, List<TimetableRule>>{};
    for (final rule in rules) {
      (courses[rule.courseId] ??= []).add(rule);
    }
    return {
      'version': 1,
      if (config case final semester?) 'semester': semester.toJson(),
      'courses': [
        for (final group in courses.values)
          {
            'id': group.first.courseId,
            'name': group.first.name,
            'type': group.first.type,
            'rules': [for (final rule in group) rule.toJson()],
          },
      ],
    };
  }

  static TimetableImport _readJson(String text) {
    final Object? decoded;
    try {
      decoded = jsonDecode(text);
    } on FormatException {
      throw const FormatException('JSON 格式无效，请检查括号、引号或逗号。');
    }
    return TimetableImport.fromJson(_object(decoded, 'JSON 根节点'));
  }

  static SemesterConfig _readConfig(Map<String, dynamic> input) {
    final day = SemesterConfig.parseDay(
      _text(input['week1Monday'], 'week1Monday'),
    );
    if (day == null) {
      throw const FormatException('semester.week1Monday 应为有效的 YYYY-MM-DD 日期。');
    }
    final times = input['periodStartTimes'];
    if (times is! List || times.any((value) => value is! String)) {
      throw const FormatException('semester.periodStartTimes 应为开始时间数组。');
    }
    return SemesterConfig(
      name: _text(input['name'], 'semester.name'),
      week1Monday: day,
      weekCount: _number(input['weekCount'], 'semester.weekCount'),
      periodStartTimes: times.cast<String>(),
      periodDurationMinutes: _number(
        input['periodDurationMinutes'],
        'semester.periodDurationMinutes',
      ),
    )..validate();
  }

  static List<TimetableRule> _readCourses(Object? input) {
    if (input is! List) throw const FormatException('courses 应为课程数组。');
    final result = <TimetableRule>[];
    final courseIds = <String>{};
    final ruleIds = <String>{};
    for (final (index, item) in input.indexed) {
      final field = 'courses[$index]';
      try {
        final course = _object(item, field);
        final courseId = _text(course['id'], 'id');
        if (!courseIds.add(courseId)) throw const FormatException('课程编号重复。');
        final name = _text(course['name'], 'name');
        final type = _type(course['type']);
        final rules = course['rules'];
        if (rules is! List || rules.isEmpty) {
          throw const FormatException('rules 应包含至少一条安排。');
        }
        for (final (ruleIndex, item) in rules.indexed) {
          try {
            final data = _object(item, 'rules');
            final weeks = data['weeks'];
            if (weeks is! List || weeks.any((value) => value is! int)) {
              throw const FormatException('weeks 应为周次整数数组。');
            }
            final rule = _rule(data, courseId, name, type, weeks.cast<int>());
            if (!ruleIds.add(rule.id)) throw const FormatException('安排编号重复。');
            result.add(rule);
          } on FormatException catch (error) {
            throw FormatException('rules[$ruleIndex]：${error.message}');
          }
        }
      } on FormatException catch (error) {
        throw FormatException('$field：${error.message}');
      }
    }
    return result;
  }

  static TimetableRule _rule(
    Map<String, dynamic> data,
    String courseId,
    String name,
    String type,
    List<int> weeks,
  ) {
    final weekday = _number(data['weekday'], '星期 (weekday)');
    final start = _number(data['startPeriod'], '开始节次 (startPeriod)');
    final end = _number(data['endPeriod'], '结束节次 (endPeriod)');
    if (weekday < 1 || weekday > 7) throw const FormatException('星期应为 1–7。');
    if (start < 1 || end < start || end > SemesterConfig.maxPeriods) {
      throw const FormatException('起止节次不正确。');
    }
    if (weeks.isEmpty || weeks.any((week) => week < 1 || week > 60)) {
      throw const FormatException('请填写 1–60 范围内的周次。');
    }
    return TimetableRule(
      id: _text(data['id'], '安排编号 (id)'),
      courseId: courseId,
      name: name,
      type: type,
      weekday: weekday,
      weeks: weeks,
      startPeriod: start,
      endPeriod: end,
      location: _text(data['location'], 'location', optional: true),
      teacher: _text(data['teacher'], 'teacher', optional: true),
      sourceNote: _text(data['sourceNote'], 'sourceNote', optional: true),
    );
  }

  static Map<String, dynamic> _object(Object? data, String field) {
    if (data is Map<String, dynamic>) return data;
    throw FormatException('$field 应为对象。');
  }

  static int _number(Object? value, String field) {
    if (value is int) return value;
    throw FormatException('$field 应为整数。');
  }

  static String _text(Object? value, String field, {bool optional = false}) {
    if (optional && value == null) return '';
    if (value is String && (optional || value.trim().isNotEmpty)) {
      final trimmed = value.trim();
      if (trimmed.length > 1000) throw FormatException('$field 超过 1000 个字符。');
      return trimmed;
    }
    throw FormatException('$field 应为${optional ? '' : '非空'}文本。');
  }

  static String _type(Object? value) {
    if (value == null || value == 'regular') return 'regular';
    if (value == 'lab') return 'lab';
    throw const FormatException('type 应为 regular 或 lab。');
  }
}
