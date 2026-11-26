import 'dart:convert';

import 'package:get/get.dart';
import 'package:qinghe_app/data/import/timetable_import.dart';
import 'package:qinghe_app/data/import/timetable_import_preview.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/data/models/timetable.dart';
import 'package:qinghe_app/data/models/timetable_exam.dart';
import 'package:qinghe_app/data/models/timetable_rule.dart';
import 'package:qinghe_app/data/repositories/timetable_source.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalTimetableRepository implements TimetableSource {
  static const _key = 'local_timetables_v1';
  final _state = const (<Timetable>[], null as String?).obs;
  bool _writing = false;
  bool readFailed = false;
  final _savedPreviews = Expando<bool>();

  List<Timetable> get timetables => _state.value.$1;
  Timetable? get active => find(_state.value.$2);

  Timetable? find(String? id) {
    for (final table in timetables) {
      if (table.id == id) return table;
    }
    return null;
  }

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    try {
      final stored = preferences.getString(_key);
      if (stored == null) return;
      final input = jsonDecode(stored) as Map<String, dynamic>;
      final tables = <Timetable>[
        for (final item in input['tables'] as List)
          _restoreTable(item as Map<String, dynamic>),
      ];
      final activeId = input['activeId'] as String?;
      if (tables.map((table) => table.id).toSet().length != tables.length ||
          (tables.isNotEmpty && !tables.any((table) => table.id == activeId))) {
        throw const FormatException('课表索引无效。');
      }
      _state.value = (List.unmodifiable(tables), activeId);
      readFailed = false;
    } on FormatException {
      readFailed = true;
    } on TypeError {
      readFailed = true;
    }
  }

  static Timetable _restoreTable(Map<String, dynamic> item) {
    final parsed = TimetableImport.fromJson(item);
    final config = parsed.config;
    if (config == null) throw const FormatException('缺少学期配置。');
    for (final rule in parsed.rules) {
      rule.validateFor(config);
    }
    return Timetable(
      id: item['id'] as String,
      config: config,
      rules: parsed.rules,
      exams: _restoreExams(item['exams']),
    );
  }

  /// 旧版本保存的课表没有考试字段，按空列表处理。
  static List<TimetableExam> _restoreExams(Object? input) {
    if (input == null) return const [];
    if (input is! List) throw const FormatException('考试安排应为数组。');
    return [
      for (final exam in input)
        if (exam is Map<String, dynamic>)
          TimetableExam.fromJson(exam)
        else
          throw const FormatException('考试安排格式无效。'),
    ];
  }

  /// 保存导入结果；[exams] 为空时保留原有考试安排。
  Future<void> save(
    TimetableImportPreview preview, {
    List<TimetableExam>? exams,
  }) async {
    if (_savedPreviews[preview] == true) return;
    final base = preview.base;
    if (base != null && !identical(find(base.id), base)) {
      throw const FormatException('学期已发生变化，请重新生成预览。');
    }
    final table = Timetable(
      id: base?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      config: preview.config,
      rules: preview.rules,
      exams: exams ?? base?.exams ?? const [],
    );
    await _write([
      for (final previous in timetables)
        if (previous.id != table.id) previous,
      table,
    ], table.id);
    _savedPreviews[preview] = true;
  }

  /// 在空白格里新增一门课。
  ///
  /// 课程与安排都用时间戳生成的编号，避免与导入的编号冲突；
  /// 周次为空时按整个学期处理。
  Future<TimetableRule> addLesson({
    required String name,
    required int weekday,
    required int startPeriod,
    required int endPeriod,
    List<int>? weeks,
    String location = '',
    String teacher = '',
  }) async {
    final table = active;
    if (table == null) throw const FormatException('当前没有可编辑的课表。');
    final courseName = name.trim();
    if (courseName.isEmpty) throw const FormatException('课程名称不能为空。');
    if (courseName.length > 40) {
      throw const FormatException('课程名称不能超过 40 个字符。');
    }
    if (weekday < 1 || weekday > 7) {
      throw const FormatException('星期应在 1–7 之间。');
    }
    final config = table.config;
    if (startPeriod < 1 ||
        endPeriod < startPeriod ||
        endPeriod > config.periodStartTimes.length) {
      throw const FormatException('节次超出当前学期的节次设置。');
    }
    final lessonWeeks = (weeks == null || weeks.isEmpty)
        ? [for (var week = 1; week <= config.weekCount; week++) week]
        : (weeks.toList()..sort());
    if (lessonWeeks.first < 1 || lessonWeeks.last > config.weekCount) {
      throw const FormatException('周次超出当前学期的教学周。');
    }

    final stamp = DateTime.now().microsecondsSinceEpoch;
    final rule = TimetableRule(
      id: 'M${stamp}r',
      courseId: 'M${stamp}c',
      name: courseName,
      weekday: weekday,
      weeks: lessonWeeks,
      startPeriod: startPeriod,
      endPeriod: endPeriod,
      location: location.trim(),
      teacher: teacher.trim(),
      sourceNote: '手动添加',
    );

    final updated = Timetable(
      id: table.id,
      config: config,
      rules: [...table.rules, rule],
      exams: table.exams,
    );
    await _write([
      for (final previous in timetables)
        if (previous.id != updated.id) previous,
      updated,
    ], updated.id);
    return rule;
  }

  /// 只更新当前学期的考试安排，不动上课安排。
  Future<void> replaceExams(List<TimetableExam> exams) async {
    final table = active;
    if (table == null) throw const FormatException('当前没有可更新的课表。');
    final updated = Timetable(
      id: table.id,
      config: table.config,
      rules: table.rules,
      exams: exams,
    );
    await _write([
      for (final previous in timetables)
        if (previous.id != updated.id) previous,
      updated,
    ], updated.id);
  }

  /// 按编号取一条上课安排。
  TimetableRule? findRule(String ruleId) {
    for (final rule in active?.rules ?? const <TimetableRule>[]) {
      if (rule.id == ruleId) return rule;
    }
    return null;
  }

  TimetableRule? _ruleIn(Timetable table, String ruleId) {
    for (final rule in table.rules) {
      if (rule.id == ruleId) return rule;
    }
    return null;
  }

  /// 编辑一条安排：课程名称同步到这门课的全部安排，
  /// 星期、节次、周次、地点与教师只改当前这一条。
  Future<void> updateRule({
    required String ruleId,
    required String name,
    required int weekday,
    required int startPeriod,
    required int endPeriod,
    required List<int> weeks,
    required String location,
    required String teacher,
  }) async {
    final table = active;
    if (table == null) throw const FormatException('当前没有可编辑的课表。');
    final existing = _ruleIn(table, ruleId);
    if (existing == null) throw const FormatException('这门课已不在课表中。');

    final courseName = name.trim();
    if (courseName.isEmpty) throw const FormatException('课程名称不能为空。');
    if (courseName.length > 40) {
      throw const FormatException('课程名称不能超过 40 个字符。');
    }
    if (weekday < 1 || weekday > 7) {
      throw const FormatException('星期应在 1–7 之间。');
    }
    if (startPeriod < 1 ||
        endPeriod < startPeriod ||
        endPeriod > table.config.periodStartTimes.length) {
      throw const FormatException('节次超出当前学期的节次设置。');
    }
    final lessonWeeks = weeks.toSet().toList()..sort();
    if (lessonWeeks.isEmpty) throw const FormatException('请至少选择一周。');
    if (lessonWeeks.first < 1 || lessonWeeks.last > table.config.weekCount) {
      throw const FormatException('周次超出当前学期的教学周。');
    }

    final updated = Timetable(
      id: table.id,
      config: table.config,
      rules: [
        for (final rule in table.rules)
          if (rule.courseId != existing.courseId)
            rule
          else
            TimetableRule(
              id: rule.id,
              courseId: rule.courseId,
              name: courseName,
              weekday: rule.id == ruleId ? weekday : rule.weekday,
              weeks: rule.id == ruleId ? lessonWeeks : rule.weeks,
              startPeriod: rule.id == ruleId ? startPeriod : rule.startPeriod,
              endPeriod: rule.id == ruleId ? endPeriod : rule.endPeriod,
              location: rule.id == ruleId ? location.trim() : rule.location,
              teacher: rule.id == ruleId ? teacher.trim() : rule.teacher,
              type: rule.type,
              sourceNote: rule.sourceNote,
            ),
      ],
      exams: table.exams,
    );
    await _write([
      for (final previous in timetables)
        if (previous.id != updated.id) previous,
      updated,
    ], updated.id);
  }

  /// 删除整门课程：这门课在课表里的全部安排一起移除。
  Future<void> removeCourse({required String courseId}) async {
    final table = active;
    if (table == null) throw const FormatException('当前没有可编辑的课表。');
    if (!table.rules.any((rule) => rule.courseId == courseId)) {
      throw const FormatException('这门课已不在课表中。');
    }

    final updated = Timetable(
      id: table.id,
      config: table.config,
      rules: [
        for (final rule in table.rules)
          if (rule.courseId != courseId) rule,
      ],
      exams: table.exams,
    );
    await _write([
      for (final previous in timetables)
        if (previous.id != updated.id) previous,
      updated,
    ], updated.id);
  }

  Future<void> _write(List<Timetable> tables, String activeId) async {
    if (readFailed) throw const FormatException('现有课表读取失败，暂时无法保存。');
    if (_writing) throw const FormatException('正在保存，请稍后重试。');
    _writing = true;
    try {
      final preferences = await SharedPreferences.getInstance();
      final saved = await preferences.setString(
        _key,
        jsonEncode({
          'activeId': activeId,
          'tables': [
            for (final table in tables)
              {
                'id': table.id,
                ...TimetableImport(table.rules, config: table.config).toJson(),
                'exams': [for (final exam in table.exams) exam.toJson()],
              },
          ],
        }),
      );
      if (!saved) throw const FormatException('保存失败，请重试。');
      _state.value = (List.unmodifiable(tables), activeId);
    } finally {
      _writing = false;
    }
  }

  @override
  int? teachingWeekOn(DateTime date) => active?.teachingWeekOn(date);

  @override
  List<LessonOccurrence> lessonsOn(DateTime date) =>
      active?.lessonsOn(date) ?? const [];
}
