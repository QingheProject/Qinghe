import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_theme.dart';
import 'package:qinghe_app/app/widgets/morph_dialog.dart';

Widget _app(Widget child) => GetMaterialApp(
  theme: AppTheme.lightFor(AppAccentTone.qinghe),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('遮罩随展开渐入，内容在容器接近到位后才显现', (tester) async {
    await tester.pumpWidget(
      _app(
        Center(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => showMorphDialog(
                context: context,
                builder: (context, close) => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('对话框内容'),
                ),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pump();

    // 逐帧采样：遮罩应当是渐进的（出现中间态），而不是一次到位。
    double? scrimAlpha() {
      final alphas = tester
          .widgetList<ColoredBox>(find.byType(ColoredBox))
          .map((box) => box.color.a)
          .toList();
      if (alphas.isEmpty) return null;
      alphas.sort();
      return alphas.last;
    }

    final samples = <double>[];
    for (var index = 0; index < 6; index++) {
      await tester.pump(const Duration(milliseconds: 40));
      final alpha = scrimAlpha();
      if (alpha != null) samples.add(alpha);
    }
    expect(samples, isNotEmpty);
    expect(samples.any((alpha) => alpha > 0.02 && alpha < 0.41), isTrue);
    for (var index = 1; index < samples.length; index++) {
      expect(samples[index], greaterThanOrEqualTo(samples[index - 1] - 1e-6));
    }

    final contentOpacityFinder = find
        .ancestor(of: find.text('对话框内容'), matching: find.byType(Opacity))
        .first;
    expect(tester.widget<Opacity>(contentOpacityFinder).opacity, lessThan(1));

    // 结束后：遮罩到达目标透明度，内容完全显示。
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(contentOpacityFinder).opacity, 1.0);
    expect(scrimAlpha(), closeTo(0.42, 0.01));
  });

  testWidgets('对话框从卡片矩形展开，内容在展开后出现，收起后退出路由', (tester) async {
    final cardKey = GlobalKey();
    Rect? origin;

    await tester.pumpWidget(
      _app(
        Center(
          child: Builder(
            builder: (context) => GestureDetector(
              key: cardKey,
              onTap: () {
                final render = cardKey.currentContext!.findRenderObject()!;
                origin =
                    (render as RenderBox).localToGlobal(Offset.zero) &
                    render.size;
                showMorphDialog(
                  context: context,
                  origin: origin,
                  originColor: const Color(0xFF2A9D8F),
                  originRadius: 10,
                  builder: (context, close) => Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('课程详情内容'),
                        TextButton(onPressed: close, child: const Text('收起')),
                      ],
                    ),
                  ),
                );
              },
              child: Container(
                key: const ValueKey('card'),
                width: 120,
                height: 60,
                color: const Color(0xFF2A9D8F),
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('课程详情内容'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('card')));
    await tester.pump();

    // 第一帧只测量内容，展开动画尚未开始。
    expect(origin, isNotNull);
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pump(const Duration(milliseconds: 200));

    // 动画结束后内容可见且为完全不透明。
    await tester.pumpAndSettle();
    expect(find.text('课程详情内容'), findsOneWidget);
    final opacity = tester.widget<Opacity>(
      find
          .ancestor(of: find.text('课程详情内容'), matching: find.byType(Opacity))
          .first,
    );
    expect(opacity.opacity, greaterThan(0.99));

    await tester.tap(find.text('收起'));
    await tester.pumpAndSettle();

    expect(find.text('课程详情内容'), findsNothing);
  });

  testWidgets('点击遮罩同样收起动画后退出', (tester) async {
    await tester.pumpWidget(
      _app(
        Center(
          child: Builder(
            builder: (context) => TextButton(
              onPressed: () => showMorphDialog(
                context: context,
                builder: (context, close) => const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text('内容'),
                ),
              ),
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();
    expect(find.text('内容'), findsOneWidget);

    // 左上角属于遮罩区域。
    await tester.tapAt(const Offset(4, 4));
    await tester.pumpAndSettle();
    expect(find.text('内容'), findsNothing);
  });
}
