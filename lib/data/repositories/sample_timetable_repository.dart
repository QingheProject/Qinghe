import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/data/models/teaching_week.dart';
import 'package:qinghe_app/data/repositories/timetable_source.dart';

/// 虚构的示例课表，在本地数据库接入前供界面展示使用。
///
/// 所有课程、地点和教师均为占位内容，不代表真实信息。
class SampleTimetableRepository implements TimetableSource {
  SampleTimetableRepository({DateTime? week1Monday, this.weekCount = 18})
    : week1Monday = week1Monday ?? DateTime(2026, 9, 7);

  final DateTime week1Monday;
  final int weekCount;

  /// 节次时间表：每节的开始与结束分钟。
  static const periods = <(int, int)>[
    (480, 525),
    (535, 580),
    (600, 645),
    (655, 700),
    (840, 885),
    (895, 940),
    (960, 1005),
    (1015, 1060),
    (1140, 1185),
    (1195, 1240),
  ];

  static const _weekly = <int, List<_SampleRule>>{
    1: [
      _SampleRule('R01', '示例课程甲', 1, 2, '示例教室 A101', 0),
      _SampleRule('R02', '示例实验乙', 5, 6, '示例实验室 3', 1),
    ],
    2: [
      _SampleRule('R03', '示例课程丙', 3, 4, '示例教室 B204', 2),
      _SampleRule('R04', '示例课程丁', 7, 8, '示例教室 C110', 3),
    ],
    3: [
      _SampleRule('R05', '示例课程甲', 1, 2, '示例教室 A101', 0),
      _SampleRule('R06', '示例课程戊', 3, 4, '示例教室 B102', 4),
      _SampleRule('R07', '示例选修己', 9, 10, '示例报告厅', 5),
    ],
    4: [
      _SampleRule('R08', '示例课程丙', 1, 2, '示例教室 B204', 2),
      _SampleRule('R09', '示例实验乙', 5, 6, '示例实验室 3', 1),
      _SampleRule('R10', '示例课程丁', 7, 8, '示例教室 C110', 3),
    ],
    5: [
      _SampleRule('R11', '示例课程戊', 3, 4, '示例教室 B102', 4),
      _SampleRule('R12', '示例课程甲', 5, 6, '示例教室 A101', 0),
    ],
  };

  @override
  int? teachingWeekOn(DateTime date) =>
      teachingWeekOf(date, week1Monday, weekCount: weekCount);

  @override
  List<LessonOccurrence> lessonsOn(DateTime date) {
    if (teachingWeekOn(date) == null) return const [];
    final key =
        '${date.year}${date.month.toString().padLeft(2, '0')}'
        '${date.day.toString().padLeft(2, '0')}';
    return [
      for (final rule in _weekly[date.weekday] ?? const <_SampleRule>[])
        LessonOccurrence(
          id: '$key-${rule.id}',
          courseName: rule.name,
          startPeriod: rule.start,
          endPeriod: rule.end,
          startMinute: periods[rule.start - 1].$1,
          endMinute: periods[rule.end - 1].$2,
          location: rule.location,
          teacher: '示例教师',
          colorIndex: rule.color,
        ),
    ];
  }
}

class _SampleRule {
  const _SampleRule(
    this.id,
    this.name,
    this.start,
    this.end,
    this.location,
    this.color,
  );

  final String id;
  final String name;
  final int start;
  final int end;
  final String location;
  final int color;
}
