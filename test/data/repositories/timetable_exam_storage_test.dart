import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/data/import/timetable_import.dart';
import 'package:qinghe_app/data/models/semester_config.dart';
import 'package:qinghe_app/data/models/timetable_exam.dart';
import 'package:qinghe_app/data/models/timetable_rule.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

SemesterConfig _config() => SemesterConfig(
  name: '测试学期',
  week1Monday: DateTime(2026, 9, 7),
  weekCount: 18,
  periodStartTimes: const ['08:00', '08:55', '10:00', '10:55'],
  periodDurationMinutes: 45,
);

TimetableRule _rule() => TimetableRule(
  id: 'R1',
  courseId: 'C1',
  name: '示例课程',
  weekday: 1,
  weeks: const [1, 2, 3],
  startPeriod: 1,
  endPeriod: 2,
  location: '示例教室',
);

TimetableExam _exam({String id = 'E1', DateTime? date}) => TimetableExam(
  id: id,
  courseName: '示例课程',
  date: date ?? DateTime(2027, 1, 12),
  startMinute: 9 * 60,
  endMinute: 11 * 60,
  location: '示例考场',
  seat: '12',
  note: '闭卷',
  sourceNote: '教务系统 · 测试学期',
);

String _stored({List<Map<String, Object?>>? exams}) {
  final import = TimetableImport([_rule()], config: _config());
  return jsonEncode({
    'activeId': 't1',
    'tables': [
      {'id': 't1', ...import.toJson(), if (exams != null) 'exams': exams},
    ],
  });
}

void main() {
  test('考试随课表一起保存并能重新读取', () async {
    SharedPreferences.setMockInitialValues({
      'local_timetables_v1': _stored(exams: [_exam().toJson()]),
    });
    final repository = LocalTimetableRepository();
    await repository.load();

    final exam = repository.active!.exams.single;
    expect(exam.id, 'E1');
    expect(exam.courseName, '示例课程');
    expect(exam.date, DateTime(2027, 1, 12));
    expect(exam.timeLabel, '09:00–11:00');
    expect(exam.location, '示例考场');
    expect(exam.seat, '12');
    expect(exam.note, '闭卷');
  });

  test('旧版本保存的课表没有考试字段时按空列表处理', () async {
    SharedPreferences.setMockInitialValues({'local_timetables_v1': _stored()});
    final repository = LocalTimetableRepository();
    await repository.load();

    expect(repository.readFailed, isFalse);
    expect(repository.active!.exams, isEmpty);
    expect(repository.active!.rules, hasLength(1));
  });

  test('只更新考试安排时不影响上课安排', () async {
    SharedPreferences.setMockInitialValues({'local_timetables_v1': _stored()});
    final repository = LocalTimetableRepository();
    await repository.load();

    await repository.replaceExams([_exam(id: 'E9')]);

    expect(repository.active!.exams.single.id, 'E9');
    expect(repository.active!.rules.single.name, '示例课程');

    // 重新读取后仍然保留刚写入的考试。
    final reloaded = LocalTimetableRepository();
    await reloaded.load();
    expect(reloaded.active!.exams.single.id, 'E9');
  });

  test('导入结果里带了考试时，保存后会替换原有考试', () async {
    SharedPreferences.setMockInitialValues({
      'local_timetables_v1': _stored(exams: [_exam().toJson()]),
    });
    final repository = LocalTimetableRepository();
    await repository.load();

    await repository.replaceExams([_exam(id: 'E2')]);

    final reloaded = LocalTimetableRepository();
    await reloaded.load();
    expect(reloaded.active!.exams.map((exam) => exam.id), ['E2']);
  });
}
