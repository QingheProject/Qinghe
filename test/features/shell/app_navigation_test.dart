import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/app/theme/app_theme.dart';
import 'package:qinghe_app/features/shell/widgets/app_navigation.dart';

void main() {
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
    expect(find.byIcon(Icons.calendar_view_week_rounded), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.byIcon(Icons.home_rounded), findsNothing);
  });

  testWidgets('点击未选中入口回调索引，点击当前入口不重复回调', (tester) async {
    final taps = <int>[];
    await pumpRail(tester, selectedIndex: 0, onSelected: taps.add);

    await tester.tap(find.byKey(const ValueKey('nav-profile')));
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
      find.byIcon(Icons.calendar_view_week_rounded),
      find.text('课表'),
    ]) {
      final content = tester.getRect(finder);
      expect(content.left, greaterThanOrEqualTo(tile.left));
      expect(content.right, lessThanOrEqualTo(tile.right));
      expect(content.top, greaterThanOrEqualTo(tile.top));
      expect(content.bottom, lessThanOrEqualTo(tile.bottom));
    }
  });
}
