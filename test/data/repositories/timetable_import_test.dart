import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/data/import/timetable_import.dart';
import 'package:qinghe_app/data/import/timetable_import_preview.dart';
import 'package:qinghe_app/data/models/semester_config.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _json = '''
{
  "version": 1,
  "semester": {
    "name": "示例学期",
    "week1Monday": "2026-09-07",
    "weekCount": 18,
    "periodDurationMinutes": 45,
    "periodStartTimes": ["08:00", "08:55"]
  },
  "courses": [
    {"id": "C1", "name": "示例课程",
     "rules": [{"id": "R1", "weekday": 1, "weeks": [1, 3], "startPeriod": 1, "endPeriod": 2}]}
  ]
}
''';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('未知 JSON 版本、非法日期和重叠节次会报错', () {
    expect(
      () => TimetableImport.parseJson('{"version":2}'),
      throwsFormatException,
    );
    expect(SemesterConfig.parseDay('2026-02-31'), isNull);
    expect(
      () => TimetableImport.parseJson(_json.replaceFirst('08:55', '08:30')),
      throwsFormatException,
    );
  });

  test('预览不写入，重复确认或重导入不复制课程，重新加载保留课表', () async {
    final draft = TimetableImport.parseJson(_json);
    final repository = LocalTimetableRepository();
    final preview = TimetableImportPreview(
      base: null,
      config: draft.config!,
      incoming: draft.rules,
    );
    expect(repository.active, isNull);
    expect(preview.added, hasLength(1));
    await repository.save(preview);
    await repository.save(preview);
    expect(repository.timetables, hasLength(1));

    final restored = LocalTimetableRepository();
    await restored.load();
    expect(restored.lessonsOn(DateTime(2026, 9, 7)).single.endMinute, 580);
    expect(restored.lessonsOn(DateTime(2026, 9, 14)), isEmpty);
    final repeat = TimetableImportPreview(
      base: restored.active,
      config: draft.config!,
      incoming: draft.rules,
    );
    expect(repeat.added, isEmpty);
    expect(repeat.updated, isEmpty);
    await restored.save(repeat);
    expect(restored.active?.rules, hasLength(1));
  });

  test('显示同周重叠，拒绝把已存在的安排编号换到另一门课程', () async {
    final draft = TimetableImport.parseJson(_json);
    final repository = LocalTimetableRepository();
    await repository.save(
      TimetableImportPreview(
        base: null,
        config: draft.config!,
        incoming: draft.rules,
      ),
    );

    final overlap = TimetableImport.parseJson(
      _json.replaceFirst('C1', 'C2').replaceFirst('R1', 'R2'),
    );
    final preview = TimetableImportPreview(
      base: repository.active,
      config: draft.config!,
      incoming: overlap.rules,
    );
    expect(preview.conflictCount, 1);
    expect(preview.rules, hasLength(2));
    final moved = TimetableImport.parseJson(_json.replaceFirst('C1', 'C2'));
    expect(
      () => TimetableImportPreview(
        base: repository.active,
        config: draft.config!,
        incoming: moved.rules,
      ),
      throwsFormatException,
    );
  });
}
