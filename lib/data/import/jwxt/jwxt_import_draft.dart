import 'package:qinghe_app/data/import/timetable_import.dart';
import 'package:qinghe_app/data/models/timetable_exam.dart';

/// 一次教务导入的完整结果：上课安排与考试安排。
///
/// 考试与课表来自同一个学期，因此一起交给导入流程；考试读取失败时
/// [exams] 为空，[examIssue] 说明原因，不影响上课安排导入。
class JwxtImportDraft {
  const JwxtImportDraft({
    required this.table,
    this.exams = const [],
    this.examIssue = '',
    this.examSkipped = const [],
  });

  final TimetableImport table;
  final List<TimetableExam> exams;

  /// 考试读取失败的原因；为空表示读取成功或该校没有考试接口。
  final String examIssue;

  /// 被跳过的考试条目说明。
  final List<String> examSkipped;
}
