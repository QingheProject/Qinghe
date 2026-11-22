import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/app.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/student_profile_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/data/import/timetable_import.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:qinghe_app/features/onboarding/controllers/onboarding_controller.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_lesson_card.dart';
import 'package:qinghe_app/features/shell/controllers/shell_controller.dart';
import 'package:qinghe_app/features/timetable_setup/views/timetable_import_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Finder _scrollableIn(String key) => find
    .descendant(
      of: find.byKey(ValueKey(key)),
      matching: find.byType(Scrollable),
    )
    .first;

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(Get.reset);

  test('主题配色共用完全中性的背景', () {
    final lightCanvases = {
      for (final tone in AppAccentTone.values) AppColors.lightFor(tone).canvas,
    };
    final darkCanvases = {
      for (final tone in AppAccentTone.values) AppColors.darkFor(tone).canvas,
    };

    expect(lightCanvases, hasLength(1));
    expect(darkCanvases, hasLength(1));
    expect(AppColors.light.canvas, const Color(0xFFF6F6F6));
    expect(AppColors.dark.canvas, const Color(0xFF111111));
  });

  testWidgets('启动页结束后进入引导，逐步前进并进入首页', (tester) async {
    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();

    expect(find.text('一眼看完\n整整一周'), findsOneWidget);

    await tester.tap(find.text('继续'));
    await tester.pumpAndSettle();
    expect(Get.find<OnboardingController>().step.value, 1);
    expect(find.text('单双周与调课\n都能说清'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('上一步'));
    await tester.pumpAndSettle();
    expect(Get.find<OnboardingController>().step.value, 0);

    for (var i = 0; i < OnboardingController.stepCount - 1; i++) {
      await tester.tap(find.text('继续'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('开始使用'));
    await tester.pumpAndSettle();
    expect(find.text('首次设置 · 1 / 2'), findsOneWidget);
    final school = find.byKey(const ValueKey('setup-school'));
    final schoolLabel = find.text('学校');
    final labelTop = tester.getTopLeft(schoolLabel).dy;
    await tester.enterText(school, '示例大学');
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(schoolLabel).dy, labelTop);
    final decorator = tester.widget<InputDecorator>(
      find.descendant(of: school, matching: find.byType(InputDecorator)),
    );
    final colors = tester.element(school).colors;
    expect(decorator.isFocused, isTrue);
    expect(decorator.decoration.fillColor, colors.surfaceMuted);
    expect(decorator.decoration.focusedBorder?.borderSide.color, colors.accent);
    expect(tester.getSize(school).height, greaterThanOrEqualTo(48));
    await tester.enterText(
      find.byKey(const ValueKey('setup-nickname')),
      '示例昵称',
    );
    await tester.tap(find.text('继续到课表导入'));
    await tester.pumpAndSettle();
    expect(find.text('首次设置 · 2 / 2'), findsOneWidget);
    expect(find.text('示例大学 · 暂未适配'), findsOneWidget);
    await tester.tap(find.text('稍后导入'));
    await tester.pumpAndSettle();
    final persistedProfile = StudentProfileController();
    await persistedProfile.load();
    expect(persistedProfile.nickname, '示例昵称');

    expect(find.text('今日课程'), findsNothing);
    expect(find.text('今天没有课'), findsNothing);
    expect(find.text('快捷入口'), findsNothing);
  });

  testWidgets('小屏手机尺寸下引导各步与首页没有布局溢出', (tester) async {
    tester.view
      ..physicalSize = const Size(360, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();

    for (var i = 0; i < OnboardingController.stepCount; i++) {
      expect(tester.takeException(), isNull);
      await tester.tap(
        find.text(i == OnboardingController.stepCount - 1 ? '开始使用' : '继续'),
      );
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('稍后填写'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('稍后导入'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('今日课程'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('nav-schedule')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('schedule-grid')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('跳过引导后可以在三个主要页面之间切换', (tester) async {
    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('跳过'));
    await tester.pumpAndSettle();

    final shell = Get.find<ShellController>();
    expect(shell.currentIndex.value, 0);

    await tester.tap(find.byKey(const ValueKey('nav-schedule')));
    await tester.pumpAndSettle();
    expect(shell.currentIndex.value, 1);
    expect(find.byKey(const ValueKey('schedule-grid')), findsOneWidget);
    expect(find.byTooltip('上一周'), findsNothing);
    expect(find.byTooltip('下一周'), findsNothing);
    expect(find.byKey(const ValueKey('schedule-today-header')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-profile')));
    await tester.pumpAndSettle();
    expect(shell.currentIndex.value, 2);
    final replay = find.text('重新查看引导');
    await tester.scrollUntilVisible(
      replay,
      220,
      scrollable: _scrollableIn('profile-scroll'),
    );
    expect(replay, findsOneWidget);
  });

  testWidgets('左右滑动切换主要页面并同步导航选中项', (tester) async {
    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('跳过'));
    await tester.pumpAndSettle();

    final shell = Get.find<ShellController>();
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1500);
    await tester.pumpAndSettle();
    expect(shell.currentIndex.value, 1);

    await tester.fling(find.byType(PageView), const Offset(400, 0), 1500);
    await tester.pumpAndSettle();
    expect(shell.currentIndex.value, 0);
    expect(find.text('今日课程'), findsNothing);
  });

  testWidgets('选择 CSV 后先预览，确认后课程显示在我的和实际课表', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('onboarding_completed', true);
    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();
    final repository = Get.find<LocalTimetableRepository>();

    Get.to<void>(
      () => TimetableImportPage(
        pickFile: (types) async {
          expect(types.single.extensions, ['csv']);
          return XFile.fromData(
            utf8.encode(
              TimetableImport.csvTemplate.replaceFirst('1-16', '1-18'),
            ),
            name: 'sample.csv',
          );
        },
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('CSV 模板'));
    await tester.pumpAndSettle();
    expect(find.text('CSV · 已读取 1 条安排'), findsOneWidget);
    final name = find.byKey(const ValueKey('semester-name'));
    await tester.scrollUntilVisible(
      name,
      220,
      scrollable: _scrollableIn('setup-scroll'),
    );
    await tester.enterText(name, '示例学期');
    await tester.enterText(
      find.byKey(const ValueKey('semester-monday')),
      '2026-09-07',
    );
    final check = find.text('检查并预览');
    expect(check.hitTestable(), findsOneWidget);
    await tester.tap(check);
    await tester.pumpAndSettle();
    expect(find.text('导入预览'), findsOneWidget);
    expect(repository.active, isNull);
    final commit = find.text('确认导入');
    expect(commit.hitTestable(), findsOneWidget);
    await tester.tap(commit);
    await tester.pumpAndSettle();
    expect(repository.active?.rules.single.name, '示例课程甲');

    await tester.tap(find.byKey(const ValueKey('nav-schedule')));
    await tester.pumpAndSettle();
    expect(find.text('示例课程甲'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('nav-profile')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('my-course-summary')), findsOneWidget);
    expect(find.text('示例学期'), findsOneWidget);
    final allCourses = find.text('查看全部课程');
    await tester.scrollUntilVisible(
      allCourses,
      160,
      scrollable: _scrollableIn('profile-scroll'),
    );
    await tester.pumpAndSettle();
    expect(allCourses.hitTestable(), findsOneWidget);
    await tester.tap(allCourses);
    await tester.pumpAndSettle();
    expect(find.byTooltip('关闭全部课程'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(BottomSheet),
        matching: find.text('示例课程甲'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('课表顶部不响应纵向滚动手势', (tester) async {
    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('跳过'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-schedule')));
    await tester.pumpAndSettle();

    final heading = find.byKey(const ValueKey('schedule-heading'));
    final initialTop = tester.getTopLeft(heading).dy;
    await tester.drag(heading, const Offset(0, -180));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(heading).dy, initialTop);

    final grid = find.byKey(const ValueKey('schedule-grid'));
    final initialGridTop = tester.getTopLeft(grid).dy;
    await tester.drag(grid, const Offset(0, -180));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(grid).dy, lessThan(initialGridTop));
  });

  testWidgets('窄屏导入选项换行，键盘打开后仍能滚动到保存', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('onboarding_completed', true);
    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();
    Get.to<void>(() => const TimetableImportPage());
    await tester.pumpAndSettle();

    final csv = find.text('CSV 模板');
    final json = find.text('JSON 文件');
    expect(tester.getTopLeft(json).dy, greaterThan(tester.getTopLeft(csv).dy));

    final field = find.byKey(const ValueKey('semester-name'));
    await tester.ensureVisible(field);
    await tester.enterText(field, '示例学期');
    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    await tester.pumpAndSettle();
    final save = find.text('保存学期配置');
    await tester.scrollUntilVisible(
      save,
      180,
      scrollable: _scrollableIn('setup-scroll'),
    );
    expect(save.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('外观设置可以切换主题、底栏形态和内容', (tester) async {
    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('跳过'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-profile')));
    await tester.pumpAndSettle();
    final appearanceEntry = find.text('外观与布局');
    await tester.scrollUntilVisible(
      appearanceEntry,
      220,
      scrollable: _scrollableIn('profile-scroll'),
    );
    await tester.tap(appearanceEntry);
    await tester.pumpAndSettle();

    final appearance = Get.find<AppearanceController>();
    await tester.tap(find.text('深色'));
    await tester.pumpAndSettle();
    expect(appearance.themeMode.value, AppearanceThemeMode.dark);

    await tester.tap(find.text('暮紫'));
    await tester.pumpAndSettle();
    expect(appearance.accentTone.value, AppAccentTone.violet);
    final themeContext = tester.element(find.text('主题配色'));
    final appliedColors = Theme.of(themeContext).extension<AppColors>()!;
    expect(
      appliedColors.accent,
      AppColors.darkFor(AppAccentTone.violet).accent,
    );
    expect(
      appliedColors.canvas,
      AppColors.darkFor(AppAccentTone.violet).canvas,
    );
    expect(appliedColors.canvas, AppColors.dark.canvas);

    await tester.tap(find.text('黑白'));
    await tester.pumpAndSettle();
    expect(appearance.accentTone.value, AppAccentTone.monochrome);
    final monochromeColors = Theme.of(
      tester.element(find.text('主题配色')),
    ).extension<AppColors>()!;
    expect(
      monochromeColors.accent,
      AppColors.darkFor(AppAccentTone.monochrome).accent,
    );
    expect(monochromeColors.canvas, AppColors.dark.canvas);

    final fixedBarOption = find.text('贴底');
    await tester.ensureVisible(fixedBarOption);
    await tester.pumpAndSettle();
    await tester.tap(fixedBarOption);
    await tester.pumpAndSettle();
    expect(appearance.bottomBarStyle.value, BottomBarStyle.fixed);

    final labelsOption = find.text('仅文字');
    await tester.ensureVisible(labelsOption);
    await tester.pumpAndSettle();
    await tester.tap(labelsOption);
    await tester.pumpAndSettle();
    expect(
      appearance.navigationContentStyle.value,
      NavigationContentStyle.labels,
    );
  });

  testWidgets('课表外观设置会实时更新模拟预览', (tester) async {
    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('跳过'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-profile')));
    await tester.pumpAndSettle();
    final scheduleAppearanceEntry = find.text('课表外观');
    await tester.scrollUntilVisible(
      scheduleAppearanceEntry,
      220,
      scrollable: _scrollableIn('profile-scroll'),
    );
    await tester.tap(scheduleAppearanceEntry);
    await tester.pumpAndSettle();

    final appearance = Get.find<AppearanceController>();
    final previewCard = find.byKey(
      const ValueKey('schedule-preview-course-card'),
    );
    final initialHeight = tester.getSize(previewCard).height;

    final paletteDrawer = find.byKey(const ValueKey('course-palette-drawer'));
    await tester.ensureVisible(paletteDrawer);
    await tester.tap(paletteDrawer);
    await tester.pumpAndSettle();
    expect(find.text('选择一套课程颜色'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('course-palette-monochrome')),
      findsNothing,
    );
    await tester.tap(find.byKey(const ValueKey('course-palette-ocean')));
    await tester.pumpAndSettle();
    expect(appearance.courseColorScheme.value, CourseColorScheme.ocean);

    final centeredTextLayout = find.byKey(
      const ValueKey('schedule-text-layout-center'),
    );
    await tester.ensureVisible(centeredTextLayout);
    await tester.pumpAndSettle();
    await tester.tap(centeredTextLayout);
    await tester.pumpAndSettle();
    expect(appearance.scheduleTextLayout.value, ScheduleTextLayout.center);

    final topTimeAlignment = find.byKey(
      const ValueKey('schedule-time-alignment-top'),
    );
    await tester.ensureVisible(topTimeAlignment);
    await tester.tap(topTimeAlignment);
    await tester.pumpAndSettle();
    expect(appearance.scheduleTimeAlignment.value, ScheduleTimeAlignment.top);

    final sideBySideRail = find.byKey(
      const ValueKey('schedule-rail-layout-sideBySide'),
    );
    await tester.ensureVisible(sideBySideRail);
    await tester.pumpAndSettle();
    await tester.tap(sideBySideRail);
    await tester.pumpAndSettle();
    expect(
      appearance.scheduleRailTextLayout.value,
      ScheduleRailTextLayout.sideBySide,
    );
    expect(tester.takeException(), isNull);

    final timeEditor = find.byKey(const ValueKey('schedule-time-editor'));
    await tester.ensureVisible(timeEditor);
    await tester.tap(timeEditor);
    await tester.pumpAndSettle();
    final durationSlider = find.byKey(
      const ValueKey('schedule-duration-slider'),
    );
    await tester.drag(durationSlider, const Offset(60, 0));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('schedule-time-0')),
      '08:15',
    );
    await tester.tap(find.byKey(const ValueKey('schedule-time-save')));
    await tester.pumpAndSettle();
    expect(appearance.scheduleStartTimes.first, '08:15');
    expect(appearance.schedulePeriodDuration.value, greaterThan(45));
    await tester.ensureVisible(
      find.byKey(const ValueKey('schedule-appearance-preview')),
    );
    await tester.pumpAndSettle();
    expect(find.text('08:15'), findsOneWidget);
    expect(
      find.text(
        calculateScheduleEndTime(
          '08:15',
          appearance.schedulePeriodDuration.value.round(),
        ),
      ),
      findsOneWidget,
    );

    final heightSlider = find.descendant(
      of: find.byKey(const ValueKey('schedule-height-slider')),
      matching: find.byType(Slider),
    );
    await tester.ensureVisible(heightSlider);
    await tester.pumpAndSettle();
    await tester.drag(heightSlider, const Offset(140, 0));
    await tester.pumpAndSettle();
    expect(appearance.scheduleRowHeight.value, greaterThan(52));
    expect(tester.getSize(previewCard).height, greaterThan(initialHeight));

    final widthSetting = find.byKey(const ValueKey('schedule-width-slider'));
    await tester.ensureVisible(widthSetting);
    await tester.pumpAndSettle();
    await tester.drag(
      find.descendant(of: widthSetting, matching: find.byType(Slider)),
      const Offset(-120, 0),
    );
    await tester.pumpAndSettle();
    expect(appearance.scheduleCardWidth.value, lessThan(1));

    final verticalInsetSetting = find.byKey(
      const ValueKey('schedule-vertical-inset-slider'),
    );
    await tester.ensureVisible(verticalInsetSetting);
    await tester.pumpAndSettle();
    await tester.drag(
      find.descendant(of: verticalInsetSetting, matching: find.byType(Slider)),
      const Offset(100, 0),
    );
    await tester.pumpAndSettle();
    expect(appearance.scheduleVerticalInset.value, greaterThan(2));

    final opacitySetting = find.byKey(
      const ValueKey('schedule-opacity-slider'),
    );
    await tester.ensureVisible(opacitySetting);
    await tester.pumpAndSettle();
    await tester.drag(
      find.descendant(of: opacitySetting, matching: find.byType(Slider)),
      const Offset(-120, 0),
    );
    await tester.pumpAndSettle();
    expect(appearance.scheduleCardOpacity.value, lessThan(1));

    final saturationSetting = find.byKey(
      const ValueKey('schedule-saturation-slider'),
    );
    await tester.ensureVisible(saturationSetting);
    await tester.pumpAndSettle();
    await tester.drag(
      find.descendant(of: saturationSetting, matching: find.byType(Slider)),
      const Offset(-120, 0),
    );
    await tester.pumpAndSettle();
    expect(appearance.scheduleCourseSaturation.value, lessThan(1));

    final radiusSetting = find.byKey(const ValueKey('schedule-radius-slider'));
    await tester.ensureVisible(radiusSetting);
    await tester.pumpAndSettle();
    final radiusSlider = find.descendant(
      of: radiusSetting,
      matching: find.byType(Slider),
    );
    await tester.drag(radiusSlider, const Offset(120, 0));
    await tester.pumpAndSettle();
    expect(appearance.scheduleCardRadius.value, greaterThan(10));
    expect(
      tester.widget<ScheduleLessonCard>(previewCard).cornerRadius,
      appearance.scheduleCardRadius.value,
    );

    final sliderBounds = tester.getRect(radiusSlider);
    expect(sliderBounds.height, greaterThanOrEqualTo(48));
    final sliderColors = tester.element(radiusSlider).colors;
    final rail = Rect.fromLTWH(
      8,
      (sliderBounds.height - 32) / 2,
      sliderBounds.width - 16,
      32,
    );
    for (final value in [0.0, 20.0]) {
      final thumbX = value == 0 ? 24.0 : sliderBounds.width - 24;
      await tester.tapAt(
        Offset(sliderBounds.left + thumbX, sliderBounds.center.dy),
      );
      await tester.pumpAndSettle();
      expect(appearance.scheduleCardRadius.value, value);
      final fill = Rect.fromLTRB(rail.left, rail.top, thumbX + 16, rail.bottom);
      final expectedPaint = paints
        ..rrect(rrect: RRect.fromRectAndRadius(rail, const Radius.circular(16)))
        ..rrect(
          rrect: RRect.fromRectAndRadius(fill, const Radius.circular(16)),
          color: sliderColors.accent,
        );
      for (var step = 0; step <= 10; step++) {
        expectedPaint.circle(
          x: 24 + (sliderBounds.width - 48) * step / 10,
          radius: 2.5,
        );
      }
      expect(
        radiusSlider,
        expectedPaint
          ..circle(x: thumbX, radius: 11, color: sliderColors.onAccent),
      );
    }

    final borderSwitch = find.byKey(const ValueKey('schedule-border-switch'));
    await tester.ensureVisible(borderSwitch);
    await tester.pumpAndSettle();
    await tester.tap(borderSwitch);
    await tester.pumpAndSettle();
    expect(appearance.scheduleShowBorder.value, isTrue);

    final borderWidthSetting = find.byKey(
      const ValueKey('schedule-border-width-slider'),
    );
    await tester.ensureVisible(borderWidthSetting);
    await tester.pumpAndSettle();
    await tester.drag(
      find.descendant(of: borderWidthSetting, matching: find.byType(Slider)),
      const Offset(120, 0),
    );
    await tester.pumpAndSettle();
    expect(appearance.scheduleBorderWidth.value, greaterThan(1));

    final topLineSwitch = find.byKey(
      const ValueKey('schedule-top-line-switch'),
    );
    await tester.ensureVisible(topLineSwitch);
    await tester.pumpAndSettle();
    await tester.tap(topLineSwitch);
    await tester.pumpAndSettle();
    expect(appearance.scheduleShowTopLine.value, isFalse);

    final gridLinesSwitch = find.byKey(
      const ValueKey('schedule-grid-lines-switch'),
    );
    await tester.ensureVisible(gridLinesSwitch);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('schedule-preview-grid-line-1')),
      findsOneWidget,
    );
    await tester.tap(gridLinesSwitch);
    await tester.pumpAndSettle();
    expect(appearance.scheduleShowGridLines.value, isFalse);
    expect(
      find.byKey(const ValueKey('schedule-preview-grid-line-1')),
      findsNothing,
    );

    final timeSwitch = find.byKey(const ValueKey('schedule-time-switch'));
    await tester.ensureVisible(timeSwitch);
    await tester.pumpAndSettle();
    expect(appearance.scheduleShowTime.value, isTrue);
    await tester.tap(timeSwitch);
    await tester.pumpAndSettle();
    expect(appearance.scheduleShowTime.value, isFalse);

    final currentTimeLineSwitch = find.byKey(
      const ValueKey('schedule-current-time-line-switch'),
    );
    await tester.ensureVisible(currentTimeLineSwitch);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('schedule-preview-current-time-line')),
      findsOneWidget,
    );
    await tester.tap(currentTimeLineSwitch);
    await tester.pumpAndSettle();
    expect(appearance.scheduleShowCurrentTimeLine.value, isFalse);
    expect(
      find.byKey(const ValueKey('schedule-preview-current-time-line')),
      findsNothing,
    );

    final weekendSwitch = find.byKey(const ValueKey('schedule-weekend-switch'));
    await tester.ensureVisible(weekendSwitch);
    await tester.pumpAndSettle();
    expect(find.text('周六'), findsOneWidget);
    await tester.tap(weekendSwitch);
    await tester.pumpAndSettle();
    expect(appearance.scheduleShowWeekend.value, isFalse);
    expect(find.text('周六'), findsNothing);

    expect(find.byKey(const ValueKey('schedule-appearance-preview')), findsOne);
    expect(tester.takeException(), isNull);
  });
}
