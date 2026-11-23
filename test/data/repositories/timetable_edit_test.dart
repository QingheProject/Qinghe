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
  test('编辑课程名称同步到全部安排，地点与教师只改当前一条', () async {
    final repository = await _repositoryWithSample();
    expect(repository.readFailed, isFalse);

    await repository.updateLesson(
      courseId: 'C1',
      ruleId: 'R2',
      name: '高等数学（上）',
      location: 'C303',
      teacher: '李老师',
    );

    final active = repository.active!;
    final course = active.rules.where((rule) => rule.courseId == 'C1');
    expect(course.every((rule) => rule.name == '高等数学（上）'), isTrue);
    expect(course.firstWhere((rule) => rule.id == 'R1').location, 'A101');
    expect(course.firstWhere((rule) => rule.id == 'R1').teacher, '张老师');
    expect(course.firstWhere((rule) => rule.id == 'R2').location, 'C303');
    expect(course.firstWhere((rule) => rule.id == 'R2').teacher, '李老师');
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

  test('课程名称为空或过长时拒绝保存', () async {
    final repository = await _repositoryWithSample();

    expect(
      () => repository.updateLesson(
        courseId: 'C1',
        ruleId: 'R1',
        name: '   ',
        location: '',
        teacher: '',
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => repository.updateLesson(
        courseId: 'C1',
        ruleId: 'R1',
        name: '课' * 41,
        location: '',
        teacher: '',
      ),
      throwsA(isA<FormatException>()),
    );
    expect(repository.active!.rules.first.name, '高等数学');
  });
}
