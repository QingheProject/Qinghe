import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/data/import/jwxt/jwxt_grades.dart';

Map<String, Object?> _grade({
  String courseCode = 'C001',
  String examType = '正常考试',
  String termCode = '3',
  Object? score,
  double? credit,
  double? point,
}) => {
  'course': '示例课程',
  'courseCode': courseCode,
  'year': 2026,
  'termCode': termCode,
  'examType': examType,
  'score': score,
  'credit': credit,
  'point': point,
};

void main() {
  test('相同记录去重，补考优先，同名不同编号或学期各自计入', () {
    final regular = _grade(score: 42, credit: 3, point: 0);
    final makeup = _grade(examType: '期末补考', score: 72, point: 2);
    final grades = JwxtGrades.parse([
      makeup,
      regular,
      regular,
      makeup,
      _grade(courseCode: 'C002', credit: 1, point: 5),
      _grade(termCode: '12', credit: 2, point: 3),
    ]);

    expect(grades.grades, hasLength(4));
    expect(grades.courseAttempts.map((attempts) => attempts.length), [2, 1, 1]);
    expect(grades.grades.take(2).map((grade) => grade.examType), [
      '期末补考',
      '正常考试',
    ]);
    expect(grades.totalCredits, 6);
    expect(grades.estimatedGpa, closeTo(17 / 6, 0.00001));

    final firstTerm = grades.filtered(year: '2026-2027', term: '第一学期');
    expect(firstTerm.totalCredits, 4);
    expect(firstTerm.estimatedGpa, 2.75);
    expect(JwxtGrades.parse(grades.toJson()).estimatedGpa, grades.estimatedGpa);
  });

  test('补考还未公布时沿用原成绩，公布后的零绩点也优先计入', () {
    final regular = _grade(score: 87, credit: 2, point: 3.5);
    final pending = _grade(examType: '补考', score: '未公布');
    final beforePublication = JwxtGrades.parse([regular, pending]);
    expect(beforePublication.totalCredits, 2);
    expect(beforePublication.estimatedGpa, 3.5);

    final makeup = _grade(courseCode: '', examType: '补考', score: 50, point: 0);
    final updated = JwxtGrades.parse([pending, regular, makeup]);
    expect(updated.totalCredits, 2);
    expect(updated.estimatedGpa, 0);
  });
}
