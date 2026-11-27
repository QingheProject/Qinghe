import 'package:get/get.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/data/repositories/timetable_source.dart';

/// 首页的今日概览状态。时钟可注入，便于测试固定时刻。
class HomeController extends GetxController {
  HomeController(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    now = _clock().obs;
  }

  final TimetableSource _repository;
  final DateTime Function() _clock;

  late final Rx<DateTime> now;
  List<LessonOccurrence> get lessons => _repository.lessonsOn(now.value);

  int get minuteOfDay => now.value.hour * 60 + now.value.minute;

  int? get teachingWeek => _repository.teachingWeekOn(now.value);

  List<({DateTime date, int count})> get weekActivity {
    final today = now.value;
    final monday = today.day - (today.weekday - DateTime.monday);
    return List.generate(DateTime.daysPerWeek, (index) {
      final date = DateTime(today.year, today.month, monday + index);
      return (date: date, count: _repository.lessonsOn(date).length);
    });
  }

  LessonOccurrence? get focusLesson => pickFocusLesson(lessons, minuteOfDay);

  int get remainingCount => lessons
      .where((lesson) => lesson.statusAt(minuteOfDay) != LessonStatus.finished)
      .length;

  String get greeting {
    final hour = now.value.hour;
    if (hour < 5) return '夜深了';
    if (hour < 11) return '早上好';
    if (hour < 13) return '中午好';
    if (hour < 18) return '下午好';
    return '晚上好';
  }

  /// 更新当前时刻；跨天时重新读取当天课程。
  void refreshClock() => now.value = _clock();
}
