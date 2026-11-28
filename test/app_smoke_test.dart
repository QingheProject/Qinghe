import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/app.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/student_profile_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:qinghe_app/features/onboarding/controllers/onboarding_controller.dart';
import 'package:qinghe_app/features/profile/views/appearance_page.dart';
import 'package:qinghe_app/features/schedule/widgets/schedule_lesson_card.dart';
import 'package:qinghe_app/features/shell/controllers/shell_controller.dart';
import 'package:qinghe_app/features/shell/widgets/app_navigation.dart';
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
    expect(find.text('首次设置 · 1 / 3'), findsOneWidget);
    final school = find.byKey(const ValueKey('setup-school'));
    expect(tester.getSize(school).height, greaterThanOrEqualTo(48));
    expect(find.text('选择学校'), findsOneWidget);

    // 学校改为从列表页选择；列表之外的学校可以手动填写。
    await tester.tap(school);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('school-list')), findsOneWidget);
    expect(find.byKey(const ValueKey('school-西南科技大学')), findsOneWidget);
    await tester.tap(find.text('找不到学校？手动填写'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('school-other-field')),
      '示例大学',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('使用该学校'));
    await tester.pumpAndSettle();
    expect(find.text('示例大学'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('setup-nickname')),
      '示例昵称',
    );
    await tester.tap(find.text('继续导入数据'));
    await tester.pumpAndSettle();
    expect(find.text('首次设置 · 2 / 3'), findsOneWidget);
    expect(find.text('示例大学 · 需粘贴 JSON 导入'), findsOneWidget);
    await tester.tap(find.text('稍后导入'));
    await tester.pumpAndSettle();
    final persistedProfile = StudentProfileController();
    await persistedProfile.load();
    expect(persistedProfile.nickname, '示例昵称');

    expect(find.text('课表今天请假啦，去做点喜欢的事吧。'), findsOneWidget);
    expect(find.text('今日课程'), findsNothing);
    expect(find.text('课程活跃'), findsNothing);
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
    expect(find.text('课表今天请假啦，去做点喜欢的事吧。'), findsOneWidget);

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

    // 左上角显示周次，右侧是周次切换与设置按钮，课表名称在右下角。
    expect(find.byKey(const ValueKey('schedule-heading')), findsOneWidget);
    expect(find.byKey(const ValueKey('schedule-week-label')), findsOneWidget);
    expect(find.byKey(const ValueKey('schedule-week-button')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('schedule-settings-button')),
      findsOneWidget,
    );
    // 标题不再写「课表」，没有导入时退回「我的课表」。
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('schedule-heading'))).data,
      isNot('课表'),
    );

    // 设置抽屉里放课表相关设置与考试信息。
    await tester.tap(find.byKey(const ValueKey('schedule-settings-button')));
    await tester.pumpAndSettle();
    expect(find.text('课表设置'), findsOneWidget);
    expect(find.text('课表外观'), findsOneWidget);
    expect(find.text('导入数据'), findsOneWidget);
    expect(find.text('学期与节次'), findsOneWidget);
    expect(find.text('考试信息'), findsOneWidget);
    await tester.tap(find.text('导入数据'));
    await tester.pumpAndSettle();
    expect(find.text('粘贴 JSON'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('课表设置'), findsNothing);

    final todayHeader = tester.getSize(
      find.byKey(const ValueKey('schedule-today-header')),
    );
    expect(todayHeader.width, todayHeader.height);

    await tester.tap(find.byKey(const ValueKey('nav-profile')));
    await tester.pumpAndSettle();
    expect(shell.currentIndex.value, 2);
    await tester.tap(find.text('导入数据'));
    await tester.pumpAndSettle();
    expect(find.text('粘贴 JSON'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    final replay = find.text('关于青禾');
    await tester.scrollUntilVisible(
      replay,
      220,
      scrollable: _scrollableIn('profile-scroll'),
    );
    expect(replay, findsOneWidget);
  });

  testWidgets('左右滑动不再切换主要页面，只响应导航点击', (tester) async {
    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('跳过'));
    await tester.pumpAndSettle();

    final shell = Get.find<ShellController>();
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1500);
    await tester.pumpAndSettle();
    expect(shell.currentIndex.value, 0);

    await tester.fling(find.byType(PageView), const Offset(400, 0), 1500);
    await tester.pumpAndSettle();
    expect(shell.currentIndex.value, 0);

    await tester.tap(find.byKey(const ValueKey('nav-schedule')));
    await tester.pumpAndSettle();
    expect(shell.currentIndex.value, 1);
  });

  testWidgets('旧版底栏设置不生效，连续点击以最后一次选择为准', (tester) async {
    SharedPreferences.setMockInitialValues({
      'onboarding_completed': true,
      'bottom_bar_style': 'fixed',
      'navigation_content_style': 'labels',
    });
    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();

    final bar = find.byType(AppTabBar);
    final scaffold = find.ancestor(of: bar, matching: find.byType(Scaffold));
    expect(tester.widget<Scaffold>(scaffold.first).extendBody, isTrue);
    expect(
      find.descendant(of: bar, matching: find.byType(BackdropFilter)),
      findsOneWidget,
    );
    expect(find.descendant(of: bar, matching: find.text('首页')), findsOneWidget);
    expect(
      find.descendant(of: bar, matching: find.byType(Icon)),
      findsNWidgets(3),
    );

    await tester.tap(find.byKey(const ValueKey('nav-profile')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 80));
    await tester.tap(find.byKey(const ValueKey('nav-schedule')));
    await tester.pumpAndSettle();

    final shell = Get.find<ShellController>();
    expect(shell.currentIndex.value, 1);
    expect(shell.pageController.page, 1);
    expect(find.byKey(const ValueKey('schedule-grid')), findsOneWidget);
  });

  testWidgets('我的页面滚动区域延伸到底栏下方，末项仍可滚出底栏', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();
    final navItem = find.byKey(const ValueKey('nav-profile'));
    await tester.tap(navItem);
    await tester.pumpAndSettle();

    final scrollable = _scrollableIn('profile-scroll');
    final itemBounds = tester.getRect(navItem);
    expect(
      tester.getBottomRight(scrollable).dy,
      greaterThan(itemBounds.bottom),
    );
    final position = tester.state<ScrollableState>(scrollable).position;
    position.jumpTo(position.maxScrollExtent);
    await tester.pumpAndSettle();
    final last = find.text('关于青禾');
    expect(last.hitTestable(), findsOneWidget);
    expect(tester.getBottomRight(last).dy, lessThan(itemBounds.top));
  });

  testWidgets('粘贴 JSON 后先预览，确认后课程显示在我的和实际课表', (tester) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool('onboarding_completed', true);
    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();
    final repository = Get.find<LocalTimetableRepository>();

    Get.to<void>(() => const TimetableImportPage());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('import-json')));
    await tester.pumpAndSettle();

    // JSON 导入页提供模板，插入后直接导入。
    expect(find.text('粘贴 JSON'), findsWidgets);
    await tester.tap(find.byKey(const ValueKey('json-insert-template')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('导入这份课表'));
    await tester.pumpAndSettle();
    expect(find.text('JSON · 已读取 1 条安排'), findsOneWidget);

    // 数据导入与学期节次已分页：先进入下一步再填写学期。
    await tester.tap(find.text('下一步：学期与节次'));
    await tester.pumpAndSettle();
    expect(find.text('待导入数据'), findsOneWidget);
    expect(find.text('JSON · 1 条安排'), findsOneWidget);
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
    final dial = find.byKey(const ValueKey('profile-semester-dial'));
    expect(dial, findsOneWidget);
    expect(find.text('示例学期'), findsOneWidget);
    // 进度环里的当前周数字与课程统计同时存在。
    expect(find.textContaining('门课程'), findsOneWidget);
    await tester.tap(dial);
    await tester.pumpAndSettle();
    expect(find.text('示例课程甲'), findsOneWidget);
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

    // 窄屏下两个导入方式纵向排列，各自带间隔。
    final jwxt = find.byKey(const ValueKey('import-jwxt'));
    final json = find.byKey(const ValueKey('import-json'));
    final jwxtRect = tester.getRect(jwxt);
    final jsonRect = tester.getRect(json);
    expect(jsonRect.top, greaterThan(jwxtRect.bottom));
    expect(jsonRect.left, jwxtRect.left);
    expect(jsonRect.width, jwxtRect.width);

    // 学期与节次已独立成页，配置与保存都在该页完成。
    await tester.tap(find.text('下一步：学期与节次'));
    await tester.pumpAndSettle();
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

  testWidgets('外观设置可以切换主题与配色，底栏不再提供形态设置', (tester) async {
    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('跳过'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-profile')));
    await tester.pumpAndSettle();
    final appearanceEntry = find.text('外观');
    await tester.scrollUntilVisible(
      appearanceEntry.hitTestable(),
      220,
      scrollable: _scrollableIn('profile-scroll'),
    );
    await tester.tap(appearanceEntry);
    await tester.pumpAndSettle();

    final appearance = Get.find<AppearanceController>();
    final darkOption = find.ancestor(
      of: find.text('深色'),
      matching: find.byType(Pressable),
    );
    final initialBounds = tester.getRect(darkOption);
    await tester.tap(darkOption);
    await tester.pumpAndSettle();
    expect(appearance.themeMode.value, AppearanceThemeMode.dark);
    expect(tester.getRect(darkOption), initialBounds);

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
    final violet = AppColors.darkFor(AppAccentTone.violet);
    final violetOption = find.ancestor(
      of: find.text('暮紫'),
      matching: find.byType(Pressable),
    );
    Finder swatchOf(Finder option, Color color) => find.descendant(
      of: option,
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration! as BoxDecoration).color == color,
      ),
    );
    expect(swatchOf(violetOption, violet.accent), findsOneWidget);
    expect(swatchOf(darkOption, violet.accentSoft), findsOneWidget);

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
    expect(find.text('贴底'), findsNothing);
    expect(find.text('仅文字'), findsNothing);
  });

  testWidgets('窄屏大字号下日期保持方形，主题选项可以重新排布', (tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_completed': true});
    tester.view
      ..physicalSize = const Size(320, 740)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-schedule')));
    await tester.pumpAndSettle();
    final today = tester.getSize(
      find.byKey(const ValueKey('schedule-today-header')),
    );
    expect(today.width, today.height);
    expect(tester.takeException(), isNull);

    Get.to<void>(() => const AppearancePage());
    await tester.pumpAndSettle();
    final system = find.text('跟随系统');
    final dark = find.text('深色');
    expect(
      tester.getTopLeft(dark).dy,
      greaterThan(tester.getTopLeft(system).dy),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('课表外观设置会实时更新模拟预览', (tester) async {
    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('跳过'));
    await tester.pumpAndSettle();

    // 课表设置挪到了课表页顶部。
    await tester.tap(find.byKey(const ValueKey('nav-schedule')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('schedule-settings-button')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('schedule-settings-appearance')),
    );
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
