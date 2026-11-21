import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/data/models/teaching_week.dart';

void main() {
  final week1Monday = DateTime(2026, 9, 7);

  int? weekOf(DateTime date) =>
      teachingWeekOf(date, week1Monday, weekCount: 18);

  test('第一教学周前一天不属于任何教学周', () {
    expect(weekOf(DateTime(2026, 9, 6, 23, 59)), isNull);
  });

  test('第一教学周的周一到周日都映射为第 1 周', () {
    expect(weekOf(DateTime(2026, 9, 7)), 1);
    expect(weekOf(DateTime(2026, 9, 13, 23, 59)), 1);
  });

  test('跨过周日进入下一教学周', () {
    expect(weekOf(DateTime(2026, 9, 14)), 2);
    expect(weekOf(DateTime(2026, 11, 20)), 11);
  });

  test('超出学期教学周数时返回 null', () {
    expect(weekOf(DateTime(2027, 1, 10)), 18);
    expect(weekOf(DateTime(2027, 1, 11)), isNull);
  });
}
