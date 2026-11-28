import 'dart:convert';

import 'package:get/get.dart';
import 'package:qinghe_app/data/import/jwxt/jwxt_grades.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef AcademicSnapshot = ({
  String school,
  String semester,
  JwxtGrades grades,
});

class LocalAcademicRepository {
  static const _key = 'local_academic_report_v1';
  final _latest = Rx<AcademicSnapshot?>(null);

  AcademicSnapshot? latestFor(String school) {
    final latest = _latest.value;
    return latest?.school == school.trim() ? latest : null;
  }

  Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(_key);
      if (stored == null) return;
      final data = jsonDecode(stored);
      if (data is! Map<String, dynamic> ||
          data['school'] is! String ||
          data['semester'] is! String) {
        return;
      }
      _latest.value = (
        school: data['school'] as String,
        semester: data['semester'] as String,
        grades: JwxtGrades.parse(
          data['grades'],
          semesterFallback: data['semester'] as String,
        ),
      );
    } on FormatException {
      _latest.value = null;
    } on TypeError {
      _latest.value = null;
    }
  }

  Future<void> save(AcademicSnapshot report) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(
      _key,
      jsonEncode({
        'school': report.school,
        'semester': report.semester,
        'grades': report.grades.toJson(),
      }),
    );
    if (!saved) throw const FormatException('成绩已读取，但本机保存失败。');
    _latest.value = report;
  }
}
