/// 一场考试安排。
///
/// 考试只有具体日期，不属于周课表，因此单独保存并按日期挂到课表上。
/// 时间可能缺失（部分学校只给出日期），缺失时只在当天标记，不占用节次位置。
class TimetableExam {
  TimetableExam({
    required this.id,
    required this.courseName,
    required this.date,
    this.startMinute,
    this.endMinute,
    this.location = '',
    this.seat = '',
    this.note = '',
    this.sourceNote = '',
  }) : assert(
         startMinute == null || (startMinute >= 0 && startMinute < 24 * 60),
         '考试开始时间应在一天之内。',
       );

  final String id;
  final String courseName;

  /// 考试当天（只保留年月日）。
  final DateTime date;

  /// 开考时间，从零点起的分钟数；未知时为空。
  final int? startMinute;

  /// 结束时间，未知时为空。
  final int? endMinute;

  final String location;

  /// 座位号，部分学校不提供。
  final String seat;

  /// 考试方式、形式等补充说明。
  final String note;

  final String sourceNote;

  bool get hasTime => startMinute != null;

  DateTime get day => DateTime(date.year, date.month, date.day);

  bool occursOn(DateTime other) =>
      day.year == other.year &&
      day.month == other.month &&
      day.day == other.day;

  /// 例如 `09:00–11:00`；没有时间时返回空串。
  String get timeLabel {
    final start = startMinute;
    if (start == null) return '';
    final end = endMinute;
    final begin = formatMinute(start);
    if (end == null || end <= start) return begin;
    return '$begin–${formatMinute(end)}';
  }

  /// 排课时使用的时长（分钟），未知时按一节略长的默认值处理。
  int get durationMinutes {
    final start = startMinute;
    final end = endMinute;
    if (start == null || end == null || end <= start) return 90;
    return end - start;
  }

  static String formatMinute(int minute) {
    final hour = (minute ~/ 60).toString().padLeft(2, '0');
    final rest = (minute % 60).toString().padLeft(2, '0');
    return '$hour:$rest';
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'courseName': courseName,
    'date': formatDay(date),
    'startMinute': startMinute,
    'endMinute': endMinute,
    'location': location,
    'seat': seat,
    'note': note,
    'sourceNote': sourceNote,
  };

  static TimetableExam fromJson(Map<String, dynamic> input) {
    final day = parseDay(input['date']);
    if (day == null) throw const FormatException('exam.date 应为 YYYY-MM-DD 日期。');
    final courseName = _text(input['courseName']);
    if (courseName.isEmpty || courseName.length > 80) {
      throw const FormatException('exam.courseName 应为 1–80 个字符。');
    }
    return TimetableExam(
      id: _text(input['id']),
      courseName: courseName,
      date: day,
      startMinute: _minute(input['startMinute']),
      endMinute: _minute(input['endMinute']),
      location: _text(input['location']),
      seat: _text(input['seat']),
      note: _text(input['note']),
      sourceNote: _text(input['sourceNote']),
    );
  }

  static String formatDay(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  static DateTime? parseDay(Object? value) {
    if (value is! String) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) return null;
    final year = int.parse(match[1]!);
    final month = int.parse(match[2]!);
    final day = int.parse(match[3]!);
    final date = DateTime(year, month, day);
    if (date.year != year || date.month != month || date.day != day) {
      return null;
    }
    return date;
  }

  static int? _minute(Object? value) {
    if (value == null) return null;
    if (value is int && value >= 0 && value < 24 * 60) return value;
    throw const FormatException('exam 的时间应为 0–1439 的分钟数。');
  }

  static String _text(Object? value) {
    if (value == null) return '';
    if (value is! String) throw const FormatException('exam 字段应为文本。');
    final trimmed = value.trim();
    if (trimmed.length > 200) throw const FormatException('exam 字段过长。');
    return trimmed;
  }
}
