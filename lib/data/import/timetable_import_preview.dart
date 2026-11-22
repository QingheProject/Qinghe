import 'dart:convert';

import 'package:qinghe_app/data/import/timetable_import.dart';
import 'package:qinghe_app/data/models/semester_config.dart';
import 'package:qinghe_app/data/models/timetable.dart';
import 'package:qinghe_app/data/models/timetable_rule.dart';

class TimetableImportPreview {
  TimetableImportPreview({
    required this.base,
    required this.config,
    required List<TimetableRule> incoming,
  }) {
    config.validate();
    final existing = {
      for (final rule in base?.rules ?? <TimetableRule>[]) rule.id: rule,
    };
    final incomingById = {for (final rule in incoming) rule.id: rule};
    final incomingCourses = {for (final rule in incoming) rule.courseId: rule};
    final merged = <TimetableRule>[];
    for (final previous in existing.values) {
      final next = incomingById[previous.id];
      if (next != null && next.courseId != previous.courseId) {
        throw FormatException('安排编号 ${previous.id} 已属于另一门课，请核对编号后重新导入。');
      }
      final course = incomingCourses[previous.courseId];
      final current =
          next ?? (course == null ? previous : previous.withCourseFrom(course));
      if (!_sameRule(previous, current)) updated.add((previous, current));
      merged.add(current);
    }
    for (final rule in incoming) {
      if (!existing.containsKey(rule.id)) {
        added.add(rule);
        merged.add(rule);
      }
    }
    if (merged.length > TimetableImport.maxRules) {
      throw const FormatException('一个学期最多可保存 2000 条安排。');
    }
    for (final rule in merged) {
      rule.validateFor(config);
    }
    rules = List.unmodifiable(merged);
    final overlaps = _overlaps(merged, {
      ...added.map((rule) => rule.id),
      ...updated.map((pair) => pair.$2.id),
    });
    final examples = <(TimetableRule, TimetableRule)>[];
    var count = 0;
    for (final overlap in overlaps) {
      count++;
      if (examples.length < 10) examples.add(overlap);
    }
    conflictCount = count;
    conflicts = List.unmodifiable(examples);
  }

  final Timetable? base;
  final SemesterConfig config;
  final added = <TimetableRule>[];
  final updated = <(TimetableRule, TimetableRule)>[];
  late final List<TimetableRule> rules;
  late final List<(TimetableRule, TimetableRule)> conflicts;
  late final int conflictCount;

  static bool _sameRule(TimetableRule a, TimetableRule b) =>
      a.name == b.name &&
      a.type == b.type &&
      jsonEncode(a.toJson()) == jsonEncode(b.toJson());

  static Iterable<(TimetableRule, TimetableRule)> _overlaps(
    List<TimetableRule> rules,
    Set<String> changedIds,
  ) sync* {
    if (changedIds.isEmpty) return;
    for (final (index, rule) in rules.indexed) {
      for (
        var otherIndex = index + 1;
        otherIndex < rules.length;
        otherIndex++
      ) {
        final other = rules[otherIndex];
        if ((changedIds.contains(rule.id) || changedIds.contains(other.id)) &&
            rule.weekday == other.weekday &&
            rule.startPeriod <= other.endPeriod &&
            other.startPeriod <= rule.endPeriod &&
            rule.weeks.any(other.weeks.contains)) {
          yield (rule, other);
        }
      }
    }
  }
}
