import 'package:qinghe_app/data/models/lesson_occurrence.dart';

abstract interface class TimetableSource {
  int? teachingWeekOn(DateTime date);

  List<LessonOccurrence> lessonsOn(DateTime date);
}
