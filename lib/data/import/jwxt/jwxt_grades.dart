typedef JwxtGrade = ({
  String course,
  String courseCode,
  String score,
  double? credit,
  double? point,
  String courseType,
  String examType,
  String year,
  String term,
});

extension JwxtGradeExam on JwxtGrade {
  bool get isMakeup => examType.contains('补考');
}

class JwxtGrades {
  JwxtGrades._(List<JwxtGrade> grades) : grades = List.unmodifiable(grades);

  final List<JwxtGrade> grades;
  late final List<List<JwxtGrade>> courseAttempts = _groupCourseAttempts();
  late final _countedGrades = _selectCountedGrades();

  List<String> get years => ({
    for (final grade in grades)
      if (grade.year.isNotEmpty) grade.year,
  }.toList()..sort((left, right) => right.compareTo(left)));

  List<String> termsFor(String year) {
    final terms = {
      for (final grade in grades)
        if (grade.year == year && grade.term.isNotEmpty) grade.term,
    };
    return [
      for (final term in _termNames.values)
        if (terms.remove(term)) term,
      ...terms,
    ];
  }

  JwxtGrades filtered({required String year, required String term}) =>
      JwxtGrades._([
        for (final grade in grades)
          if ((year.isEmpty || grade.year == year) &&
              (term.isEmpty || grade.term == term))
            grade,
      ]);

  double? get totalCredits {
    var total = 0.0;
    var hasCredits = false;
    for (final grade in _countedGrades) {
      final credit = grade.credit;
      if (credit == null) continue;
      total += credit;
      hasCredits = true;
    }
    return hasCredits ? total : null;
  }

  List<Map<String, Object?>> toJson() => [
    for (final grade in grades)
      {
        'course': grade.course,
        if (grade.courseCode.isNotEmpty) 'courseCode': grade.courseCode,
        'score': grade.score,
        'credit': grade.credit,
        'point': grade.point,
        'courseType': grade.courseType,
        'examType': grade.examType,
        'year': grade.year,
        'term': grade.term,
      },
  ];

  double? get estimatedGpa {
    var credits = 0.0;
    var points = 0.0;
    for (final grade in _countedGrades) {
      final credit = grade.credit;
      final point = grade.attempt.point;
      if (credit == null || credit == 0 || point == null) continue;
      credits += credit;
      points += credit * point;
    }
    return credits == 0 ? null : points / credits;
  }

  /// 同一学期按课程编号归组，旧缓存可按课程名称匹配。
  List<List<JwxtGrade>> _groupCourseAttempts() {
    final codesByName = <(String, String, String), Set<String>>{};
    for (final grade in grades) {
      if (grade.courseCode.isNotEmpty) {
        (codesByName[(grade.year, grade.term, grade.course)] ??= {}).add(
          grade.courseCode,
        );
      }
    }

    final byCourse = <(String, String, String), List<JwxtGrade>>{};
    for (final grade in grades) {
      final codes = codesByName[(grade.year, grade.term, grade.course)];
      final code = grade.courseCode.isEmpty && codes?.length == 1
          ? codes!.single
          : grade.courseCode;
      final identity = code.isEmpty ? 'name:${grade.course}' : 'code:$code';
      (byCourse[(grade.year, grade.term, identity)] ??= []).add(grade);
    }
    return List.unmodifiable([
      for (final attempts in byCourse.values)
        List<JwxtGrade>.unmodifiable(attempts),
    ]);
  }

  /// 每门课计一次，已公布的补考成绩优先。
  List<({JwxtGrade attempt, double? credit})> _selectCountedGrades() {
    return courseAttempts
        .map((attempts) {
          var attempt = attempts.first;
          var credit = attempt.credit;
          for (final grade in attempts.skip(1)) {
            if (_attemptPriority(grade) >= _attemptPriority(attempt)) {
              attempt = grade;
            }
            credit = attempt.credit ?? grade.credit ?? credit;
          }
          return (attempt: attempt, credit: credit);
        })
        .toList(growable: false);
  }

  static int _attemptPriority(JwxtGrade grade) {
    if (grade.point == null && _unpublishedScores.contains(grade.score)) {
      return 0;
    }
    return grade.isMakeup ? 2 : 1;
  }

  static const _termNames = {'3': '第一学期', '12': '第二学期', '16': '第三学期'};
  static const _unpublishedScores = {'', '-', '--', '—', '未公布', '待公布'};

  static JwxtGrades parse(Object? rows, {String? semesterFallback}) {
    if (rows is! List) throw const FormatException('成绩列表无法识别。');
    final legacyYear =
        RegExp(
          r'\d{4}(?:[-–]\d{4})?',
        ).firstMatch(semesterFallback ?? '')?.group(0) ??
        '';
    final legacyTerm =
        RegExp(r'第[一二三]学期').firstMatch(semesterFallback ?? '')?.group(0) ?? '';
    final grades = <JwxtGrade>{};
    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final course = _text(row['course']);
      if (course.isEmpty) continue;
      grades.add((
        course: course,
        courseCode: _text(row['courseCode']),
        score: _text(row['score']),
        credit: _number(row['credit']),
        point: _number(row['point']),
        courseType: _text(row['courseType']),
        examType: _text(row['examType']),
        year: _year(_text(row['year']), legacyYear),
        term: _term(_text(row['term']), _text(row['termCode']), legacyTerm),
      ));
    }
    if (rows.isNotEmpty && grades.isEmpty) {
      throw const FormatException('成绩列表中的课程字段无法识别。');
    }
    return JwxtGrades._(grades.toList());
  }

  static String _text(Object? value) => switch (value) {
    String text => text.trim(),
    num number => number.toString(),
    _ => '',
  };

  static String _year(String label, String fallback) {
    final raw = label.isEmpty ? fallback : label;
    final match = RegExp(
      r'^(\d{4})(?:\s*[-–－]\s*(\d{4}))?(?:\s*学年)?$',
    ).firstMatch(raw);
    if (match == null) return raw;
    final start = int.parse(match.group(1)!);
    return '$start-${match.group(2) ?? start + 1}';
  }

  static String _term(String label, String code, String fallback) =>
      switch (label) {
        '' => _termNames[code] ?? (code.isEmpty ? fallback : code),
        '1' || '上学期' => '第一学期',
        '2' || '下学期' => '第二学期',
        '3' => '第三学期',
        _ => label,
      };

  static double? _number(Object? value) {
    final number = double.tryParse(_text(value));
    return number != null && number.isFinite && number >= 0 ? number : null;
  }
}
