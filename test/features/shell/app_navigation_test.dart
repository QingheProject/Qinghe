import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_theme.dart';
import 'package:qinghe_app/features/shell/widgets/app_navigation.dart';

void main() {
  testWidgets('底栏毛玻璃透出页面颜色', (tester) async {
    final boundary = GlobalKey();
    const backdrop = Color(0xFF3268A8);
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            extendBody: true,
            body: const SizedBox.expand(child: ColoredBox(color: backdrop)),
            bottomNavigationBar: AppTabBar(
              selectedIndex: 0,
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final item = tester.getRect(find.byKey(const ValueKey('nav-profile')));
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final point = render.globalToLocal(item.centerRight - const Offset(20, 0));
    final color = await tester.runAsync(() async {
      final image = await render.toImage();
      try {
        final pixels = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final offset = (point.dy.floor() * image.width + point.dx.floor()) * 4;
        return Color.fromARGB(
          pixels.getUint8(offset + 3),
          pixels.getUint8(offset),
          pixels.getUint8(offset + 1),
          pixels.getUint8(offset + 2),
        );
      } finally {
        image.dispose();
      }
    });
    expect(color, backdrop);
  });

  Future<void> pumpBar(WidgetTester tester, int selectedIndex) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          bottomNavigationBar: AppTabBar(
            selectedIndex: selectedIndex,
            onSelected: (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('底栏选中块前缘先移动，反向时接续当前形状', (tester) async {
    await pumpBar(tester, 0);
    final pill = find.byKey(const ValueKey('bottom-bar-selection'));
    final initial = tester.getRect(pill);

    await pumpBar(tester, 2);
    await tester.pump(const Duration(milliseconds: 70));
    final stretched = tester.getRect(pill);
    expect(stretched.left, closeTo(initial.left, 0.01));
    expect(stretched.right, greaterThan(initial.right));
    expect(stretched.height, lessThan(initial.height));

    await pumpBar(tester, 0);
    expect(tester.getRect(pill), stretched);
    await tester.pumpAndSettle();
    expect(tester.getRect(pill), initial);
  });

  testWidgets('底栏禁止波纹和按压高亮，减少动画时直接落位', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpBar(tester, 0);
    final schedule = find.byKey(const ValueKey('nav-schedule'));
    final item = tester.widget<InkWell>(schedule);
    expect(item.splashFactory, NoSplash.splashFactory);
    expect(item.highlightColor, Colors.transparent);
    expect(
      item.overlayColor!.resolve({WidgetState.pressed, WidgetState.focused}),
      Colors.transparent,
    );

    await pumpBar(tester, 1);
    final pill = find.byKey(const ValueKey('bottom-bar-selection'));
    expect(
      tester.getCenter(pill).dx,
      closeTo(tester.getCenter(schedule).dx, 0.01),
    );
  });

  Future<void> pumpRail(
    WidgetTester tester, {
    required int selectedIndex,
    required ValueChanged<int> onSelected,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: 960,
            height: 720,
            child: Row(
              children: [
                AppSideRail(
                  selectedIndex: selectedIndex,
                  onSelected: onSelected,
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('侧栏按顺序展示三个入口并标记选中项', (tester) async {
    await pumpRail(tester, selectedIndex: 1, onSelected: (_) {});

    expect(find.byKey(const ValueKey('nav-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-schedule')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-profile')), findsOneWidget);

    // 选中项使用实心图标，未选中项保持线性图标。
    expect(find.byIcon(AppIcons.calendarFill), findsOneWidget);
    expect(find.byIcon(AppIcons.home), findsOneWidget);
    expect(find.byIcon(AppIcons.homeFill), findsNothing);
  });

  testWidgets('点击未选中入口回调索引，点击当前入口不重复回调', (tester) async {
    final taps = <int>[];
    await pumpRail(tester, selectedIndex: 0, onSelected: taps.add);

    final item = find.byKey(const ValueKey('nav-profile'));
    expect(tester.widget<InkWell>(item).splashFactory, isNull);
    expect(
      Theme.of(tester.element(item)).splashFactory,
      InkSparkle.splashFactory,
    );
    await tester.tap(item);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-home')));
    await tester.pumpAndSettle();

    expect(taps, [2]);
  });

  testWidgets('侧栏面板是圆角矩形，不是胶囊', (tester) async {
    await pumpRail(tester, selectedIndex: 1, onSelected: (_) {});

    final panel = tester.widget<ClipRRect>(
      find.descendant(
        of: find.byKey(const ValueKey('side-rail-panel')),
        matching: find.byType(ClipRRect),
      ),
    );
    final panelRect = tester.getRect(
      find.byKey(const ValueKey('side-rail-panel')),
    );
    final radius = (panel.borderRadius as BorderRadius).topLeft.x;

    // 胶囊的半径等于短边的一半；圆角矩形必须明显小于它。
    expect(radius, lessThan(panelRect.width / 2 - 4));
  });

  testWidgets('选中底色是圆角矩形，并完整覆盖图标与文字', (tester) async {
    await pumpRail(tester, selectedIndex: 1, onSelected: (_) {});

    final tileFinder = find.byKey(const ValueKey('side-rail-selection'));
    final tile = tester.getRect(tileFinder);
    final decoration =
        tester.widget<DecoratedBox>(tileFinder).decoration as BoxDecoration;
    final radius = (decoration.borderRadius! as BorderRadius).topLeft.x;

    // 圆角矩形：圆角明显小于方块短边的一半，不能是胶囊。
    expect(radius, lessThan(tile.shortestSide / 2 - 4));
    expect(radius, greaterThan(0));

    // 选中块内缩在格子内部，不互相粘连。
    expect(tile.left, greaterThan(0));
    expect(tile.height, lessThan(64));

    // 图标与文字都落在选中块内部。
    for (final finder in [
      find.byIcon(AppIcons.calendarFill),
      find.text('课表'),
    ]) {
      final content = tester.getRect(finder);
      expect(content.left, greaterThanOrEqualTo(tile.left));
      expect(content.right, lessThanOrEqualTo(tile.right));
      expect(content.top, greaterThanOrEqualTo(tile.top));
      expect(content.bottom, lessThanOrEqualTo(tile.bottom));
    }
  });

  testWidgets('切换时选中块橡胶拉伸，落位后恢复静止尺寸', (tester) async {
    await pumpRail(tester, selectedIndex: 0, onSelected: (_) {});
    final selection = find.byKey(const ValueKey('side-rail-selection'));
    final rest = tester.getRect(selection);

    await pumpRail(tester, selectedIndex: 2, onSelected: (_) {});
    await tester.pump(const Duration(milliseconds: 220));
    final stretched = tester.getRect(selection);

    // 后缘粘性延迟：中途仍落后于目标槽位。
    expect(stretched.top, greaterThan(rest.top));
    expect(stretched.bottom, lessThan(rest.top + 64 * 3));
    // 拉伸时沿交叉轴压扁。
    expect(stretched.width, lessThan(rest.width));

    await tester.pumpAndSettle();
    final settled = tester.getRect(selection);
    expect(settled.width, closeTo(rest.width, 0.01));
    expect(settled.top, greaterThan(stretched.top));
  });
}
