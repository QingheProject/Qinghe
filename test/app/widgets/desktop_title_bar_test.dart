import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/app/theme/app_theme.dart';
import 'package:qinghe_app/app/widgets/desktop_title_bar.dart';

void main() {
  const minimizeKey = ValueKey('title-bar-minimize');
  const maximizeKey = ValueKey('title-bar-maximize');
  const closeKey = ValueKey('title-bar-close');

  Future<void> pumpBar(
    WidgetTester tester, {
    bool maximized = false,
    VoidCallback? onStartDrag,
    VoidCallback? onMinimize,
    VoidCallback? onToggleMaximize,
    VoidCallback? onClose,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: DesktopTitleBar(
            maximized: maximized,
            onStartDrag: onStartDrag ?? () {},
            onMinimize: onMinimize ?? () {},
            onToggleMaximize: onToggleMaximize ?? () {},
            onClose: onClose ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('标题栏显示品牌与三个窗口按钮', (tester) async {
    await pumpBar(tester);

    expect(find.byKey(const ValueKey('desktop-title-bar')), findsOneWidget);
    expect(find.text('青禾'), findsOneWidget);
    expect(find.byKey(minimizeKey), findsOneWidget);
    expect(find.byKey(maximizeKey), findsOneWidget);
    expect(find.byKey(closeKey), findsOneWidget);
    expect(find.bySemanticsLabel('最小化'), findsOneWidget);
    expect(find.bySemanticsLabel('最大化'), findsOneWidget);
    expect(find.bySemanticsLabel('关闭'), findsOneWidget);
  });

  testWidgets('点击三个按钮分别触发最小化、最大化与关闭', (tester) async {
    var minimized = 0;
    var toggled = 0;
    var closed = 0;
    await pumpBar(
      tester,
      onMinimize: () => minimized++,
      onToggleMaximize: () => toggled++,
      onClose: () => closed++,
    );

    await tester.tap(find.byKey(minimizeKey));
    await tester.tap(find.byKey(maximizeKey));
    await tester.tap(find.byKey(closeKey));
    await tester.pump();

    expect(minimized, 1);
    expect(toggled, 1);
    expect(closed, 1);
  });

  testWidgets('最大化后按钮语义变为还原', (tester) async {
    await pumpBar(tester, maximized: true);

    expect(find.bySemanticsLabel('还原'), findsOneWidget);
    expect(find.bySemanticsLabel('最大化'), findsNothing);
  });

  testWidgets('三个窗口按钮紧贴右侧且尺寸一致', (tester) async {
    await pumpBar(tester);

    final bar = tester.getRect(find.byKey(const ValueKey('desktop-title-bar')));
    final minimize = tester.getRect(find.byKey(minimizeKey));
    final maximize = tester.getRect(find.byKey(maximizeKey));
    final close = tester.getRect(find.byKey(closeKey));

    expect(minimize.width, 46);
    expect(minimize.height, bar.height);
    expect(close.right, closeTo(bar.right, 0.5));
    expect(minimize.right, closeTo(maximize.left, 0.5));
    expect(maximize.right, closeTo(close.left, 0.5));
    // 品牌区占据左侧剩余空间，窗口按钮不侵占。
    expect(minimize.left, greaterThan(bar.width / 2));
  });

  testWidgets('拖动标题栏空白区域开始拖动窗口', (tester) async {
    var drags = 0;
    await pumpBar(tester, onStartDrag: () => drags++);

    await tester.drag(find.text('青禾'), const Offset(80, 24));
    await tester.pumpAndSettle();

    expect(drags, 1);
  });

  testWidgets('双击标题栏切换最大化', (tester) async {
    var toggled = 0;
    await pumpBar(tester, onToggleMaximize: () => toggled++);

    await tester.tap(find.text('青禾'));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.tap(find.text('青禾'));
    await tester.pumpAndSettle();

    expect(toggled, 1);
  });
}
