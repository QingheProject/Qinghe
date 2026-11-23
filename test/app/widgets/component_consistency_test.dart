import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/app/theme/app_theme.dart';
import 'package:qinghe_app/app/widgets/app_button.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_lesson_card.dart';

void main() {
  testWidgets('大字体下带图标的按钮允许文字换行并撑高', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: Center(
              child: SizedBox(
                width: 220,
                child: AppButton(
                  label: '检查并预览课表配置',
                  icon: AppIcons.upload,
                  trailingIcon: AppIcons.arrowForward,
                  expand: true,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(AppButton)).height, greaterThan(52));
    final ink = find.descendant(
      of: find.byType(AppButton),
      matching: find.byType(InkWell),
    );
    expect(
      Theme.of(tester.element(ink)).splashFactory,
      InkSparkle.splashFactory,
    );
    expect(tester.widget<InkWell>(ink).splashColor?.a, greaterThan(0));
  });

  testWidgets('课程卡片能通过辅助功能点击入口打开', (tester) async {
    final semantics = tester.ensureSemantics();
    try {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 140,
                height: 140,
                child: ScheduleLessonCard(
                  lesson: const LessonOccurrence(
                    id: 'sample',
                    courseName: '示例课程',
                    startPeriod: 1,
                    endPeriod: 2,
                    startMinute: 480,
                    endMinute: 580,
                  ),
                  date: DateTime(2026, 11, 23),
                  compact: false,
                  colorScheme: CourseColorScheme.qinghe,
                  saturation: 1,
                  backgroundOpacity: 1,
                  cornerRadius: 10,
                  showBorder: true,
                  borderWidth: 1,
                  showTopLine: true,
                  showLocation: true,
                  showTeacher: true,
                  textLayout: ScheduleTextLayout.center,
                  onTap: (_) => taps++,
                ),
              ),
            ),
          ),
        ),
      );
      final node = tester.getSemantics(find.byType(ScheduleLessonCard));
      expect(node.getSemanticsData().hasAction(ui.SemanticsAction.tap), isTrue);
      node.owner!.performAction(node.id, ui.SemanticsAction.tap);
      expect(taps, 1);
    } finally {
      semantics.dispose();
    }
  });
}
