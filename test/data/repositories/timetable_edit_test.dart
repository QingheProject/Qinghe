import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/data/import/timetable_import.dart';
import 'package:qinghe_app/data/models/semester_config.dart';
import 'package:qinghe_app/data/models/timetable_rule.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

SemesterConfig _config() => SemesterConfig(
  name: '测试学期',
  week1Monday: DateTime(2026, 9, 7),
  weekCount: 18,
  periodStartTimes: const [
    '08:00',
    '08:55',
    '10:00',
    '10:55',
    '14:00',
    '14:55',
    '16:00',
    '16:55',
    '19:00',
    '19:55',
  ],
  periodDurationMinutes: 45,
);

List<TimetableRule> _rules() => [
  TimetableRule(
    id: 'R1',
    courseId: 'C1',
    name: '高等数学',
    weekday: 1,
    weeks: const [1, 2, 3],
    startPeriod: 1,
    endPeriod: 2,
    location: 'A101',
    teacher: '张老师',
  ),
  TimetableRule(
    id: 'R2',
    courseId: 'C1',
    name: '高等数学',
    weekday: 3,
    weeks: const [1, 2, 3],
    startPeriod: 3,
    endPeriod: 4,
    location: 'B202',
    teacher: '张老师',
  ),
  TimetableRule(
    id: 'R3',
    courseId: 'C2',
    name: '大学物理',
    weekday: 2,
    weeks: const [1],
    startPeriod: 5,
    endPeriod: 6,
  ),
];

Future<LocalTimetableRepository> _repositoryWithSample() async {
  final import = TimetableImport(_rules(), config: _config());
  SharedPreferences.setMockInitialValues({
    'local_timetables_v1': jsonEncode({
      'activeId': 't1',
      'tables': [
        {'id': 't1', ...import.toJson()},
      ],
    }),
  });
  final repository = LocalTimetableRepository();
  await repository.load();
  return repository;
}

void main() {
  test('编辑一条安排：名称同步到全部安排，其余字段只改这一条', () async {
    final repository = await _repositoryWithSample();
    expect(repository.readFailed, isFalse);

    await repository.updateRule(
      ruleId: 'R2',
      name: '高等数学（上）',
      weekday: 5,
      startPeriod: 5,
      endPeriod: 6,
      weeks: [1, 2],
      location: 'C303',
      teacher: '李老师',
    );

    final active = repository.active!;
    final course = active.rules.where((rule) => rule.courseId == 'C1');
    // 课程名同步到这门课的全部安排。
    expect(course.every((rule) => rule.name == '高等数学（上）'), isTrue);
    // 其它安排保持原样。
    final first = active.rules.firstWhere((rule) => rule.id == 'R1');
    expect(first.weekday, 1);
    expect(first.startPeriod, 1);
    expect(first.weeks, [1, 2, 3]);
    expect(first.location, 'A101');
    // 被编辑的那一条换成了新的星期、节次、周次、地点与教师。
    final edited = active.rules.firstWhere((rule) => rule.id == 'R2');
    expect(edited.weekday, 5);
    expect(edited.startPeriod, 5);
    expect(edited.endPeriod, 6);
    expect(edited.weeks, [1, 2]);
    expect(edited.location, 'C303');
    expect(edited.teacher, '李老师');
    // 其它课程不受影响。
    expect(active.rules.firstWhere((rule) => rule.id == 'R3').name, '大学物理');

    final reloaded = LocalTimetableRepository();
    await reloaded.load();
    expect(
      reloaded.active!.rules.firstWhere((rule) => rule.id == 'R2').location,
      'C303',
    );
    expect(
      reloaded.active!.rules.firstWhere((rule) => rule.id == 'R1').name,
      '高等数学（上）',
    );
  });

  test('课程名称为空、过长或周次超范围时拒绝保存', () async {
    final repository = await _repositoryWithSample();

    Future<void> update({
      String name = '高等数学',
      List<int> weeks = const [1, 2, 3],
    }) => repository.updateRule(
      ruleId: 'R1',
      name: name,
      weekday: 1,
      startPeriod: 1,
      endPeriod: 2,
      weeks: weeks,
      location: 'A101',
      teacher: '张老师',
    );

    expect(() => update(name: '   '), throwsA(isA<FormatException>()));
    expect(() => update(name: '课' * 41), throwsA(isA<FormatException>()));
    expect(() => update(weeks: const []), throwsA(isA<FormatException>()));
    expect(() => update(weeks: const [19]), throwsA(isA<FormatException>()));
    expect(repository.active!.rules.first.name, '高等数学');
  });

  test('删除课程会移除这门课的全部安排', () async {
    final repository = await _repositoryWithSample();

    await repository.removeCourse(courseId: 'C1');
    final remaining = repository.active!.rules;
    // C1 的两条安排一起删除，其它课程不受影响。
    expect(remaining.any((rule) => rule.courseId == 'C1'), isFalse);
    expect(remaining.map((rule) => rule.id), ['R3']);

    final reloaded = LocalTimetableRepository();
    await reloaded.load();
    expect(
      reloaded.active!.rules.any((rule) => rule.courseId == 'C1'),
      isFalse,
    );

    expect(
      () => repository.removeCourse(courseId: 'C1'),
      throwsA(isA<FormatException>()),
    );
  });
}
