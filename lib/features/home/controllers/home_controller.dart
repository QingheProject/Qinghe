import 'package:get/get.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/data/repositories/sample_timetable_repository.dart';

/// 首页的今日概览状态。时钟可注入，便于测试固定时刻。
class HomeController extends GetxController {
  HomeController(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now {
    final current = _clock();
    now = current.obs;
    lessons.assignAll(_repository.lessonsOn(current));
  }

  final SampleTimetableRepository _repository;
  final DateTime Function() _clock;

  late final Rx<DateTime> now;
  final lessons = <LessonOccurrence>[].obs;

  /// 示例课表仍在使用时为 true，界面据此标注“示例数据”。
  bool get usesSampleData => true;

  int get minuteOfDay => now.value.hour * 60 + now.value.minute;

  int? get teachingWeek => _repository.teachingWeekOn(now.value);

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
  void refreshClock() {
    final previous = now.value;
    final current = _clock();
    final dayChanged =
        previous.year != current.year ||
        previous.month != current.month ||
        previous.day != current.day;
    now.value = current;
    if (dayChanged) lessons.assignAll(_repository.lessonsOn(current));
  }
}
