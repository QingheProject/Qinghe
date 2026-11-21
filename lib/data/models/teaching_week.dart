/// 计算 [date] 所在的教学周，超出 1 至 [weekCount] 时返回 null。
///
/// 按日历日期计算差值，忽略时刻部分，避免时区或夏令时造成偏差。
int? teachingWeekOf(
  DateTime date,
  DateTime week1Monday, {
  required int weekCount,
}) {
  final day = DateTime.utc(date.year, date.month, date.day);
  final start = DateTime.utc(
    week1Monday.year,
    week1Monday.month,
    week1Monday.day,
  );
  final days = day.difference(start).inDays;
  if (days < 0) return null;
  final week = days ~/ 7 + 1;
  return week > weekCount ? null : week;
}
