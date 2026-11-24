import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_theme.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/data/models/timetable_exam.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_exam_card.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_lesson_card.dart';

const _radius = 12.0;
const _opacity = 0.9;
const _borderWidth = 1.5;

final _lesson = LessonOccurrence(
  id: 'L1',
  courseName: '示例课程',
  startPeriod: 1,
  endPeriod: 2,
  startMinute: 8 * 60,
  endMinute: 9 * 60 + 40,
  location: '示例楼 A201',
  teacher: '示例老师',
  colorIndex: 7,
);

final _exam = TimetableExam(
  id: 'E1',
  courseName: '示例课程',
  date: DateTime(2027, 1, 12),
  startMinute: 9 * 60,
  endMinute: 11 * 60,
  location: '示例楼 A201',
);

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.lightFor(AppAccentTone.qinghe),
  home: Scaffold(
    body: SizedBox(width: 360, height: 600, child: Center(child: child)),
  ),
);

Widget _lessonCard() => SizedBox(
  width: 90,
  height: 200,
  child: ScheduleLessonCard(
    lesson: _lesson,
    date: DateTime(2026, 11, 25),
    compact: false,
    colorScheme: CourseColorScheme.qinghe,
    saturation: 1,
    backgroundOpacity: _opacity,
    cornerRadius: _radius,
    showBorder: true,
    borderWidth: _borderWidth,
    showTopLine: true,
    showLocation: true,
    showTeacher: true,
    textLayout: ScheduleTextLayout.top,
    onTap: (_) {},
  ),
);

Widget _examCard() => SizedBox(
  width: 90,
  height: 200,
  child: ScheduleExamCard(
    exam: _exam,
    compact: false,
    // 与课程卡用同一个配色下标时，两张卡应当完全同色。
    colorIndex: _lesson.colorIndex,
    colorScheme: CourseColorScheme.qinghe,
    saturation: 1,
    backgroundOpacity: _opacity,
    cornerRadius: _radius,
    showBorder: true,
    borderWidth: _borderWidth,
    showTopLine: true,
    showLocation: true,
    textLayout: ScheduleTextLayout.top,
    onTap: (_) {},
  ),
);

/// 取卡片最外层那块背景装饰：它是唯一带描边的 DecoratedBox。
BoxDecoration _decorationOf(WidgetTester tester) {
  for (final box in tester.widgetList<DecoratedBox>(
    find.byType(DecoratedBox),
  )) {
    final decoration = box.decoration;
    if (decoration is BoxDecoration && decoration.border != null) {
      return decoration;
    }
  }
  fail('没有找到带描边的卡片装饰');
}

void main() {
  testWidgets('考试卡与课程卡使用同一套底色、圆角与描边', (tester) async {
    await tester.pumpWidget(_host(_lessonCard()));
    final lesson = _decorationOf(tester);

    await tester.pumpWidget(_host(_examCard()));
    final exam = _decorationOf(tester);

    expect(exam.borderRadius, lesson.borderRadius);
    expect(exam.borderRadius, BorderRadius.circular(_radius));
    expect((exam.border as Border).top.width, _borderWidth);
    expect(
      (exam.border as Border).top.width,
      (lesson.border as Border).top.width,
    );
    // 同一门课：底色与描边色完全一致，透明度按卡片透明度设置。
    expect(exam.color, lesson.color);
    expect(exam.color?.a, closeTo(_opacity, 0.001));
  });

  testWidgets('考试卡标题与信息使用与课程卡相同的字号', (tester) async {
    await tester.pumpWidget(_host(_lessonCard()));
    final lessonTitle = tester.widget<Text>(find.text('示例课程')).style!;

    await tester.pumpWidget(_host(_examCard()));
    final examTitle = tester.widget<Text>(find.text('示例课程')).style!;

    expect(examTitle.fontSize, lessonTitle.fontSize);
    expect(examTitle.fontWeight, lessonTitle.fontWeight);
    expect(examTitle.color, lessonTitle.color);
  });

  testWidgets('考试卡把时间与考场写在课程卡的「地点／教师」位置', (tester) async {
    await tester.pumpWidget(_host(_examCard()));

    expect(find.text('考试 09:00–11:00\n示例楼 A201'), findsOneWidget);
  });

  testWidgets('卡片太矮时与课程卡一样只留标题', (tester) async {
    await tester.pumpWidget(
      _host(
        SizedBox(
          width: 90,
          height: 48,
          child: ScheduleExamCard(
            exam: _exam,
            compact: true,
            colorIndex: _lesson.colorIndex,
            colorScheme: CourseColorScheme.qinghe,
            saturation: 1,
            backgroundOpacity: _opacity,
            cornerRadius: _radius,
            showBorder: true,
            borderWidth: _borderWidth,
            showTopLine: false,
            showLocation: true,
            textLayout: ScheduleTextLayout.top,
            onTap: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('示例课程'), findsOneWidget);
    expect(find.textContaining('考试 09:00'), findsNothing);
  });
}
