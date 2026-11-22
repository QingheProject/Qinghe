class SemesterConfig {
  SemesterConfig({
    required this.name,
    required this.week1Monday,
    required this.weekCount,
    required List<String> periodStartTimes,
    required this.periodDurationMinutes,
  }) : periodStartTimes = List.unmodifiable(periodStartTimes);

  final String name;
  final DateTime week1Monday;
  final int weekCount;
  final List<String> periodStartTimes;
  final int periodDurationMinutes;

  static const maxPeriods = 16;

  String get firstDay =>
      '${week1Monday.year.toString().padLeft(4, '0')}-'
      '${week1Monday.month.toString().padLeft(2, '0')}-'
      '${week1Monday.day.toString().padLeft(2, '0')}';

  static DateTime? parseDay(String text) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text)) return null;
    final date = DateTime.tryParse(text);
    if (date == null || !date.toIso8601String().startsWith(text)) return null;
    return date;
  }

  static int? parseMinute(String text) {
    final match = RegExp(r'^([01]\d|2[0-3]):([0-5]\d)$').firstMatch(text);
    if (match == null) return null;
    return int.parse(match[1]!) * 60 + int.parse(match[2]!);
  }

  void validate() {
    if (name.trim().isEmpty || name.length > 80) {
      throw const FormatException('请输入 1–80 个字符的学期名称。');
    }
    if (week1Monday.weekday != DateTime.monday) {
      throw const FormatException('第一教学周请选择周一。');
    }
    if (weekCount < 1 || weekCount > 60) {
      throw const FormatException('教学周数应为 1–60。');
    }
    if (periodDurationMinutes < 20 || periodDurationMinutes > 120) {
      throw const FormatException('每节时长应为 20–120 分钟。');
    }
    if (periodStartTimes.isEmpty || periodStartTimes.length > maxPeriods) {
      throw const FormatException('请设置 1–16 个节次。');
    }
    var previousEnd = 0;
    for (final (index, time) in periodStartTimes.indexed) {
      final start = parseMinute(time);
      if (start == null) {
        throw FormatException('第 ${index + 1} 节开始时间应为 HH:mm。');
      }
      final end = start + periodDurationMinutes;
      if (start < previousEnd || end >= 24 * 60) {
        throw FormatException('第 ${index + 1} 节与前一节重叠或跨日。');
      }
      previousEnd = end;
    }
  }

  int startMinute(int period) => parseMinute(periodStartTimes[period - 1])!;

  Map<String, Object> toJson() => {
    'name': name,
    'week1Monday': firstDay,
    'weekCount': weekCount,
    'periodStartTimes': periodStartTimes,
    'periodDurationMinutes': periodDurationMinutes,
  };
}
