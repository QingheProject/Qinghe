import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:csv/csv_settings_autodetection.dart';
import 'package:qinghe_app/data/models/semester_config.dart';
import 'package:qinghe_app/data/models/timetable_rule.dart';

enum TimetableFileType { csv, json }

class TimetableImport {
  const TimetableImport(this.rules, {this.config});

  final List<TimetableRule> rules;
  final SemesterConfig? config;

  static const _requiredColumns = [
    '课程编号',
    '安排编号',
    '课程名',
    '星期',
    '周次',
    '开始节次',
    '结束节次',
  ];
  static const _optionalColumns = ['课程类型', '地点', '教师', '来源备注'];
  static const maxBytes = 1024 * 1024;
  static const maxRules = 2000;

  static final csvTemplate =
      '${[..._requiredColumns, ..._optionalColumns].join(',')}\r\n'
      'C001,R001,示例课程甲,1,1-16,1,2,普通,示例教室,,\r\n';

  factory TimetableImport.parse(String text, TimetableFileType type) {
    if (text.startsWith('\uFEFF')) text = text.substring(1);
    final draft = switch (type) {
      TimetableFileType.csv => TimetableImport(_readCsv(text)),
      TimetableFileType.json => _readJson(text),
    };
    if (draft.rules.isEmpty || draft.rules.length > maxRules) {
      throw const FormatException('文件应包含 1–2000 条上课安排。');
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

  static List<TimetableRule> _readCsv(String text) {
    final List<List<dynamic>> rows;
    try {
      rows = const CsvToListConverter(
        shouldParseNumbers: false,
        allowInvalid: false,
        csvSettingsDetector: FirstOccurrenceSettingsDetector(
          eols: ['\r\n', '\n', '\r'],
        ),
      ).convert(text);
    } on FormatException {
      throw const FormatException('CSV 表格结构无效，请检查引号与换行。');
    }
    if (rows.isEmpty) throw const FormatException('CSV 文件为空。');
    final headers = rows.first.map((cell) => cell.toString().trim()).toList();
    final known = {..._requiredColumns, ..._optionalColumns};
    if (!headers.toSet().containsAll(_requiredColumns) ||
        headers.toSet().length != headers.length ||
        headers.any((name) => !known.contains(name))) {
      throw const FormatException('CSV 表头与青禾模板不符，请检查缺少、重复或未知的列。');
    }
    final columns = {for (final (index, name) in headers.indexed) name: index};
    final result = <TimetableRule>[];
    final ruleIds = <String>{};
    final courses = <String, (String, String)>{};
    for (final (index, row) in rows.skip(1).indexed) {
      if (row.length == 1 && row.single.toString().trim().isEmpty) continue;
      try {
        if (row.length != headers.length) {
          throw const FormatException('列数与表头不一致。');
        }
        String? cell(String name) => columns[name] == null
            ? null
            : row[columns[name]!].toString().trim();
        final courseId = _text(cell('课程编号'), '课程编号');
        final name = _text(cell('课程名'), '课程名');
        final type = switch (cell('课程类型')) {
          null || '' || '普通' => 'regular',
          '实验' => 'lab',
          _ => throw const FormatException('课程类型应为普通或实验。'),
        };
        if (courses[courseId] != null && courses[courseId] != (name, type)) {
          throw const FormatException('同一课程编号的名称与类型应一致。');
        }
        courses[courseId] = (name, type);
        final rule = _rule(
          {
            'id': cell('安排编号'),
            'weekday': int.tryParse(cell('星期')!),
            'startPeriod': int.tryParse(cell('开始节次')!),
            'endPeriod': int.tryParse(cell('结束节次')!),
            'location': cell('地点'),
            'teacher': cell('教师'),
            'sourceNote': cell('来源备注'),
          },
          courseId,
          name,
          type,
          _csvWeeks(cell('周次')!),
        );
        if (!ruleIds.add(rule.id)) throw const FormatException('安排编号重复。');
        result.add(rule);
      } on FormatException catch (error) {
        throw FormatException('第 ${index + 1} 条数据：${error.message}');
      }
    }
    return result;
  }

  static List<int> _csvWeeks(String text) {
    final weeks = <int>[];
    for (final part in text.split(',')) {
      final match = RegExp(r'^(\d+)(?:\s*-\s*(\d+))?$').firstMatch(part.trim());
      final start = int.tryParse(match?[1] ?? '');
      final end = int.tryParse(match?[2] ?? '') ?? start;
      if (start == null ||
          end == null ||
          start < 1 ||
          end < start ||
          end > 60) {
        throw const FormatException('周次格式不正确，请使用 1–60 范围内的周次，例如 1-8 或 1,3,5。');
      }
      for (var week = start; week <= end; week++) {
        weeks.add(week);
      }
    }
    return weeks;
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
