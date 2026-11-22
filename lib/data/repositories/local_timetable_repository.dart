import 'dart:convert';

import 'package:get/get.dart';
import 'package:qinghe_app/data/import/timetable_import.dart';
import 'package:qinghe_app/data/import/timetable_import_preview.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/data/models/timetable.dart';
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
    );
  }

  Future<void> save(TimetableImportPreview preview) async {
    if (_savedPreviews[preview] == true) return;
    final base = preview.base;
    if (base != null && !identical(find(base.id), base)) {
      throw const FormatException('学期已发生变化，请重新生成预览。');
    }
    final table = Timetable(
      id: base?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      config: preview.config,
      rules: preview.rules,
    );
    await _write([
      for (final previous in timetables)
        if (previous.id != table.id) previous,
      table,
    ], table.id);
    _savedPreviews[preview] = true;
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
