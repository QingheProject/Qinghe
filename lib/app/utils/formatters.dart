const _weekdays = ['一', '二', '三', '四', '五', '六', '日'];

/// 1 至 7 对应“星期一”至“星期日”。
String weekdayLabel(int weekday) => '星期${_weekdays[weekday - 1]}';

/// 把当天的分钟数格式化为 HH:mm。
String formatClock(int minuteOfDay) {
  final hour = (minuteOfDay ~/ 60).toString().padLeft(2, '0');
  final minute = (minuteOfDay % 60).toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatDuration(int minutes) {
  if (minutes < 60) return '$minutes 分钟';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '$hours 小时' : '$hours 小时 $rest 分钟';
}

String formatPeriods(int start, int end) =>
    start == end ? '第 $start 节' : '第 $start–$end 节';
