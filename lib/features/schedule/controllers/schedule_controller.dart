import 'dart:async';

import 'package:get/get.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:qinghe_app/data/repositories/timetable_source.dart';
import 'package:qinghe_app/data/models/timetable.dart';
import 'package:qinghe_app/data/models/timetable_exam.dart';

typedef ScheduleClock = DateTime Function();

/// 课表的显示粒度。
enum ScheduleViewMode { day, week, month }

class ScheduleController extends GetxController {
  ScheduleController(this._repository, {ScheduleClock clock = DateTime.now})
    : _clock = clock {
    final now = _clock();
    currentTime = now.obs;
    final today = _dateOnly(now);
    currentWeekStart = _mondayOf(today);
    weekStart = currentWeekStart.obs;
  }

  final TimetableSource _repository;
  final ScheduleClock _clock;
  Timer? _clockTimer;
  late final DateTime currentWeekStart;
  late final Rx<DateTime> weekStart;
  late final Rx<DateTime> currentTime;

  /// 当前的显示粒度，切换视图共用同一份周次状态。
  final viewMode = ScheduleViewMode.week.obs;

  /// 日视图选中的那一天。
  final selectedDate = Rxn<DateTime>();

  /// 月视图锚定的月份（该月的任意一天）。
  final monthAnchor = Rxn<DateTime>();

  /// 最近一次切周的方向：1 表示向后，-1 表示向前，用于让过渡位移与手势一致。
  final weekDirection = 1.obs;

  /// 空白格里点出来的「加号占位」：点在哪一天、哪一节。
  final ghostSlot = Rxn<({int dayIndex, int period})>();

  /// 切换显示粒度；月视图第一次进入时锚定到当前周。
  void switchView(ScheduleViewMode mode) {
    if (viewMode.value == mode) return;
    clearGhost();
    if (mode == ScheduleViewMode.month && monthAnchor.value == null) {
      monthAnchor.value = DateTime(
        currentWeekStart.year,
        currentWeekStart.month,
        1,
      );
    }
    if (mode == ScheduleViewMode.day && selectedDate.value == null) {
      selectedDate.value = today;
    }
    viewMode.value = mode;
  }

  /// 在月视图里点某一天：记为日视图的选择，并跳到日视图。
  void selectDay(DateTime date) {
    clearGhost();
    final day = _dateOnly(date);
    selectedDate.value = day;
    // 同步周次状态，让返回周视图时落在同一周。
    final targetWeek = _mondayOf(day);
    if (targetWeek != weekStart.value) {
      weekDirection.value = targetWeek.isAfter(weekStart.value) ? 1 : -1;
      weekStart.value = targetWeek;
    }
    viewMode.value = ScheduleViewMode.day;
  }

  /// 在空白格上点一下，先放一个占位格。
  void selectGhost(int dayIndex, int period) {
    ghostSlot.value = (dayIndex: dayIndex, period: period);
  }

  void clearGhost() => ghostSlot.value = null;

  DateTime get today => _dateOnly(currentTime.value);

  int get currentMinute =>
      currentTime.value.hour * 60 + currentTime.value.minute;

  @override
  void onInit() {
    super.onInit();
    _clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      currentTime.value = _clock();
    });
  }

  @override
  void onClose() {
    _clockTimer?.cancel();
    super.onClose();
  }

  Timetable? get activeTimetable => switch (_repository) {
    final LocalTimetableRepository repository => repository.active,
    _ => null,
  };

  DateTime get displayedWeekStart {
    final selected = weekStart.value;
    final timetable = activeTimetable;
    if (timetable == null ||
        selected != currentWeekStart ||
        timetable.teachingWeekOn(selected) != null) {
      return selected;
    }
    return timetable.config.week1Monday;
  }

  List<DateTime> get days => [
    for (var offset = 0; offset < DateTime.daysPerWeek; offset++)
      DateTime(
        displayedWeekStart.year,
        displayedWeekStart.month,
        displayedWeekStart.day + offset,
      ),
  ];

  /// 日视图当前显示的那一天（默认今天，并夹在可选范围内）。
  DateTime get displayedDate {
    final selected = selectedDate.value ?? today;
    if (selected.isBefore(dayRangeStart)) return dayRangeStart;
    if (selected.isAfter(dayRangeEnd)) return dayRangeEnd;
    return selected;
  }

  bool get isCurrentDate => displayedDate == today;

  /// 日视图可左右滑动的范围：整个学期；没有课表时以今天为中心前后各一年。
  DateTime get dayRangeStart {
    final config = activeTimetable?.config;
    if (config != null) return _dateOnly(config.week1Monday);
    return today.subtract(const Duration(days: 365));
  }

  DateTime get dayRangeEnd {
    final config = activeTimetable?.config;
    if (config != null) {
      return _dateOnly(
        config.week1Monday,
      ).add(Duration(days: config.weekCount * 7 - 1));
    }
    return today.add(const Duration(days: 365));
  }

  /// 日视图一共有多少页（一天一页）。
  int get dayPageCount => dayRangeEnd.difference(dayRangeStart).inDays + 1;

  /// 当前选中日期对应的页码。
  int get displayedDatePage {
    final index = displayedDate.difference(dayRangeStart).inDays;
    return index.clamp(0, dayPageCount - 1);
  }

  /// 某一页对应的日期。
  DateTime dateForPage(int page) =>
      dayRangeStart.add(Duration(days: page.clamp(0, dayPageCount - 1)));

  /// 只改选中日期（滑页 / 点日期轴），不切换视图。
  void selectDateOnly(DateTime date) {
    clearGhost();
    final day = _dateOnly(date);
    if (day.isBefore(dayRangeStart)) return;
    if (day.isAfter(dayRangeEnd)) return;
    selectedDate.value = day;
    final targetWeek = _mondayOf(day);
    if (targetWeek != weekStart.value) {
      weekDirection.value = targetWeek.isAfter(weekStart.value) ? 1 : -1;
      weekStart.value = targetWeek;
    }
  }

  void previousDate() =>
      selectDateOnly(displayedDate.subtract(const Duration(days: 1)));

  void nextDate() => selectDateOnly(displayedDate.add(const Duration(days: 1)));

  void goToDate(DateTime date) => selectDateOnly(date);

  void goToToday() {
    clearGhost();
    selectedDate.value = today;
    weekStart.value = currentWeekStart;
  }

  /// 月视图锚定的月份（未设置时用当前周所在月）。
  DateTime get displayedMonth {
    final anchor = monthAnchor.value;
    if (anchor != null) return DateTime(anchor.year, anchor.month, 1);
    return DateTime(currentWeekStart.year, currentWeekStart.month, 1);
  }

  void previousMonth() {
    clearGhost();
    final month = displayedMonth;
    monthAnchor.value = DateTime(month.year, month.month - 1, 1);
  }

  void nextMonth() {
    clearGhost();
    final month = displayedMonth;
    monthAnchor.value = DateTime(month.year, month.month + 1, 1);
  }

  /// 月视图的格子：从该月首周周一到覆盖月末那一周的周日，始终是整周的倍数。
  List<DateTime> get monthCells {
    final month = displayedMonth;
    final firstMonday = _mondayOf(month);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final lastDay = DateTime(month.year, month.month, daysInMonth);
    final lastSunday = _mondayOf(lastDay).add(const Duration(days: 6));
    return [
      for (
        var date = firstMonday;
        !date.isAfter(lastSunday);
        date = date.add(const Duration(days: 1))
      )
        date,
    ];
  }

  bool get isCurrentMonth {
    final now = _clock();
    return displayedMonth == DateTime(now.year, now.month, 1);
  }

  void goToCurrentMonth() {
    final now = _clock();
    monthAnchor.value = DateTime(now.year, now.month, 1);
  }

  int? get teachingWeek {
    return _repository.teachingWeekOn(displayedWeekStart);
  }

  bool get isCurrentWeek => weekStart.value == currentWeekStart;

  /// 当前视图是否已经停在「现在」：日视图看今天、周视图看本周、月视图看本月。
  bool get isCurrentView => switch (viewMode.value) {
    ScheduleViewMode.day => isCurrentDate,
    ScheduleViewMode.week => isCurrentWeek,
    ScheduleViewMode.month => isCurrentMonth,
  };

  /// 顶栏「回到…」按钮的文案。
  String get currentViewLabel => switch (viewMode.value) {
    ScheduleViewMode.day => '回到今天',
    ScheduleViewMode.week => '回到本周',
    ScheduleViewMode.month => '回到本月',
  };

  List<LessonOccurrence> lessonsOn(DateTime date) =>
      _repository.lessonsOn(date);

  /// 当前学期的考试安排，供课表标记与考试列表使用。
  List<TimetableExam> get exams => activeTimetable?.exams ?? const [];

  List<TimetableExam> examsOn(DateTime date) =>
      activeTimetable?.examsOn(date) ?? const [];

  /// 课表名称，用于顶部标题。
  String? get timetableName => activeTimetable?.config.name;

  /// 当前显示的这一周对应的教学周（学期外为空）。
  int? get displayedTeachingWeek =>
      _repository.teachingWeekOn(displayedWeekStart);

  /// 真实本周对应的教学周。
  int? get currentTeachingWeek => _repository.teachingWeekOn(currentWeekStart);

  /// 学期内的所有周次，附带本周标记与那一周的课程，供周次抽屉画缩略课表。
  List<
    ({
      int week,
      DateTime monday,
      DateTime sunday,
      bool isCurrent,
      List<List<LessonOccurrence>> days,
    })
  >?
  get weekSlots {
    final config = activeTimetable?.config;
    if (config == null) return null;
    final thisWeek = currentTeachingWeek;
    return [
      for (var week = 1; week <= config.weekCount; week++)
        (
          week: week,
          monday: config.week1Monday.add(Duration(days: 7 * (week - 1))),
          sunday: config.week1Monday.add(Duration(days: 7 * (week - 1) + 6)),
          isCurrent: week == thisWeek,
          days: [
            for (var offset = 0; offset < DateTime.daysPerWeek; offset++)
              _repository.lessonsOn(
                config.week1Monday.add(Duration(days: 7 * (week - 1) + offset)),
              ),
          ],
        ),
    ];
  }

  /// 跳到第 [week] 教学周。
  void goToTeachingWeek(int week) {
    final config = activeTimetable?.config;
    if (config == null) return;
    if (week < 1 || week > config.weekCount) return;
    final target = config.week1Monday.add(Duration(days: 7 * (week - 1)));
    if (target == weekStart.value) return;
    clearGhost();
    weekDirection.value = target.isAfter(weekStart.value) ? 1 : -1;
    weekStart.value = target;
    // 日视图跟随到该周的周一。
    if (viewMode.value == ScheduleViewMode.day) {
      selectedDate.value = target;
    }
  }

  void previousWeek() {
    clearGhost();
    weekDirection.value = -1;
    weekStart.value = weekStart.value.subtract(const Duration(days: 7));
  }

  void nextWeek() {
    clearGhost();
    weekDirection.value = 1;
    weekStart.value = weekStart.value.add(const Duration(days: 7));
  }

  void goToCurrentWeek() {
    clearGhost();
    weekDirection.value = currentWeekStart.isAfter(weekStart.value) ? 1 : -1;
    weekStart.value = currentWeekStart;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime _mondayOf(DateTime date) =>
      date.subtract(Duration(days: date.weekday - DateTime.monday));
}
