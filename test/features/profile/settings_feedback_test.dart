import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/app.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/features/profile/views/schedule_appearance_page.dart';
import 'package:qinghe_app/features/shell/controllers/shell_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<Color> pixelAt(
  WidgetTester tester,
  GlobalKey boundaryKey,
  Offset point,
) async {
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage();
    final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    final offset = (point.dy.floor() * image.width + point.dx.floor()) * 4;
    final color = Color.fromARGB(
      bytes.getUint8(offset + 3),
      bytes.getUint8(offset),
      bytes.getUint8(offset + 1),
      bytes.getUint8(offset + 2),
    );
    image.dispose();
    return color;
  }))!;
}

void main() {
  setUp(
    () =>
        SharedPreferences.setMockInitialValues({'onboarding_completed': true}),
  );
  tearDown(Get.reset);

  for (final dark in [false, true]) {
    testWidgets('${dark ? '深色' : '浅色'}设置行点击反馈位于卡片内部且不会溢出', (tester) async {
      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(key: boundary, child: const QingheApp()),
      );
      await tester.pumpAndSettle();
      if (dark) {
        await Get.find<AppearanceController>().setThemeMode(
          AppearanceThemeMode.dark,
        );
        await tester.pumpAndSettle();
      }
      Get.to<void>(() => const ScheduleAppearancePage());
      await tester.pumpAndSettle();
      final setting = find.byKey(const ValueKey('schedule-time-switch'));
      await tester.ensureVisible(setting);
      await tester.pumpAndSettle();
      final rect = tester.getRect(setting);
      final point = Offset(rect.left + 8, rect.center.dy);
      final idle = await pixelAt(tester, boundary, point);
      final outside = Offset(rect.left - 4, rect.center.dy);
      final outsideIdle = await pixelAt(tester, boundary, outside);
      final gesture = await tester.startGesture(
        rect.center - const Offset(80, 0),
      );
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pump(const Duration(milliseconds: 180));
      final pressed = await pixelAt(tester, boundary, point);
      expect(await pixelAt(tester, boundary, outside), outsideIdle);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(pressed, isNot(idle), reason: '卡片内空白处应能看到按住反馈，不能被分组底色遮住');
    });
  }

  testWidgets('小屏课程配色抽屉可以滚动选择最后一项', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 480)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();
    Get.to<void>(() => const ScheduleAppearancePage());
    await tester.pumpAndSettle();
    final entry = find.byKey(const ValueKey('course-palette-drawer'));
    await tester.ensureVisible(entry);
    await tester.tap(entry);
    await tester.pumpAndSettle();
    final choice = find.byKey(const ValueKey('course-palette-candy'));
    await tester.ensureVisible(choice);
    await tester.tap(choice);
    await tester.pumpAndSettle();
    expect(
      Get.find<AppearanceController>().courseColorScheme.value,
      CourseColorScheme.candy,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('系统减少动画时导航直接切换到目标页', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-profile')));
    await tester.pump();
    expect(Get.find<ShellController>().pageController.page, 2);
    await tester.pumpAndSettle();
  });

  testWidgets('大字体设置卡片的标题说明能够完整布局', (tester) async {
    tester.view
      ..physicalSize = const Size(320, 740)
      ..devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();
    Get.to<void>(() => const ScheduleAppearancePage());
    await tester.pumpAndSettle();
    for (final key in ['course-palette-drawer', 'schedule-time-editor']) {
      await tester.ensureVisible(find.byKey(ValueKey(key)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
