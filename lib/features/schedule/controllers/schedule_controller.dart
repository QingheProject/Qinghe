import 'dart:async';

import 'package:get/get.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:qinghe_app/data/repositories/timetable_source.dart';
import 'package:qinghe_app/data/models/timetable.dart';

typedef ScheduleClock = DateTime Function();

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

  /// 最近一次切周的方向：1 表示向后，-1 表示向前，用于让过渡位移与手势一致。
  final weekDirection = 1.obs;

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

  int? get teachingWeek {
    return _repository.teachingWeekOn(displayedWeekStart);
  }

  bool get isCurrentWeek => weekStart.value == currentWeekStart;

  List<LessonOccurrence> lessonsOn(DateTime date) =>
      _repository.lessonsOn(date);

  void previousWeek() {
    weekDirection.value = -1;
    weekStart.value = weekStart.value.subtract(const Duration(days: 7));
  }

  void nextWeek() {
    weekDirection.value = 1;
    weekStart.value = weekStart.value.add(const Duration(days: 7));
  }

  void goToCurrentWeek() {
    weekDirection.value = currentWeekStart.isAfter(weekStart.value) ? 1 : -1;
    weekStart.value = currentWeekStart;
  }

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static DateTime _mondayOf(DateTime date) =>
      date.subtract(Duration(days: date.weekday - DateTime.monday));
}
