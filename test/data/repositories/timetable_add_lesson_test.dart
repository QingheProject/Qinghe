import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/data/import/timetable_import_preview.dart';
import 'package:qinghe_app/data/models/semester_config.dart';
import 'package:qinghe_app/data/models/timetable_rule.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

SemesterConfig _config() => SemesterConfig(
  name: '示例学期',
  week1Monday: DateTime(2026, 9, 7),
  weekCount: 18,
  periodStartTimes: const ['08:00', '08:55', '10:00', '10:55', '14:00'],
  periodDurationMinutes: 45,
);

List<TimetableRule> _rules() => [
  TimetableRule(
    id: 'R1',
    courseId: 'C1',
    name: '示例课程甲',
    weekday: 1,
    weeks: const [1, 2, 3],
    startPeriod: 1,
    endPeriod: 2,
  ),
];

Future<LocalTimetableRepository> _repository() async {
  SharedPreferences.setMockInitialValues({});
  final repository = LocalTimetableRepository();
  await repository.load();
  await repository.save(
    TimetableImportPreview(base: null, config: _config(), incoming: _rules()),
  );
  return repository;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('新增课程会写入仓库并默认覆盖整个学期', () async {
    final repository = await _repository();

    final rule = await repository.addLesson(
      name: '  新增示例课  ',
      weekday: 3,
      startPeriod: 3,
      endPeriod: 4,
      location: '  示例教室 ',
      teacher: ' 示例教师 ',
    );

    expect(rule.name, '新增示例课');
    expect(rule.location, '示例教室');
    expect(rule.teacher, '示例教师');
    expect(rule.weeks, hasLength(18));
    expect(rule.sourceNote, '手动添加');

    final active = repository.active!;
    expect(active.rules, hasLength(2));
    expect(active.rules.last.id, rule.id);
    // 原有的安排不受影响。
    expect(active.rules.first.name, '示例课程甲');
  });

  test('新增课程会落盘，重新加载后仍在', () async {
    final repository = await _repository();
    await repository.addLesson(
      name: '新增示例课',
      weekday: 2,
      startPeriod: 1,
      endPeriod: 2,
    );

    final reloaded = LocalTimetableRepository();
    await reloaded.load();
    expect(reloaded.active!.rules, hasLength(2));
    expect(reloaded.active!.rules.last.name, '新增示例课');
  });

  test('课程名为空时报错', () async {
    final repository = await _repository();
    expect(
      () => repository.addLesson(
        name: '   ',
        weekday: 1,
        startPeriod: 1,
        endPeriod: 1,
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('节次与周次超出设置时报错', () async {
    final repository = await _repository();

    expect(
      () => repository.addLesson(
        name: '示例课程乙',
        weekday: 1,
        startPeriod: 1,
        endPeriod: 9,
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => repository.addLesson(
        name: '示例课程乙',
        weekday: 8,
        startPeriod: 1,
        endPeriod: 1,
      ),
      throwsA(isA<FormatException>()),
    );
    expect(
      () => repository.addLesson(
        name: '示例课程乙',
        weekday: 1,
        startPeriod: 1,
        endPeriod: 1,
        weeks: const [1, 30],
      ),
      throwsA(isA<FormatException>()),
    );
  });
}
