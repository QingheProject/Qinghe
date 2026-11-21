import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/app.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/features/onboarding/controllers/onboarding_controller.dart';
import 'package:qinghe_app/features/shell/controllers/shell_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  tearDown(Get.reset);

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
    expect(tester.takeException(), isNull);
    expect(find.text('今日课程'), findsNothing);
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
    expect(find.text('周课表正在制作'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-profile')));
    await tester.pumpAndSettle();
    expect(shell.currentIndex.value, 2);
    expect(find.text('重新查看引导'), findsOneWidget);
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

  testWidgets('外观设置可以切换主题、底栏形态和内容', (tester) async {
    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();
    await tester.tap(find.text('跳过'));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('nav-profile')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('外观与布局'));
    await tester.pumpAndSettle();

    final appearance = Get.find<AppearanceController>();
    await tester.tap(find.text('深色'));
    await tester.pumpAndSettle();
    expect(appearance.themeMode.value, AppearanceThemeMode.dark);

    await tester.tap(find.text('贴底'));
    await tester.pumpAndSettle();
    expect(appearance.bottomBarStyle.value, BottomBarStyle.fixed);

    await tester.tap(find.text('仅文字'));
    await tester.pumpAndSettle();
    expect(
      appearance.navigationContentStyle.value,
      NavigationContentStyle.labels,
    );
  });
}
