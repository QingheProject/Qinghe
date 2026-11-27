import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/app/theme/app_theme.dart';
import 'package:qinghe_app/app/widgets/app_sheet.dart';

Widget _host(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('抽屉外壳统一显示拖拽条、标题、说明与内容', (tester) async {
    await tester.pumpWidget(
      _host(
        AppSheet(
          title: '示例抽屉',
          subtitle: '一句说明',
          note: '补充说明',
          children: [const Text('内容一'), const Text('内容二')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('示例抽屉'), findsOneWidget);
    expect(find.text('一句说明'), findsOneWidget);
    expect(find.text('补充说明'), findsOneWidget);
    expect(find.text('内容一'), findsOneWidget);
    expect(find.text('内容二'), findsOneWidget);
    // 标题与说明的字号按统一规范：标题 titleMedium，说明比标题小。
    final title = tester.widget<Text>(find.text('示例抽屉')).style!;
    final subtitle = tester.widget<Text>(find.text('一句说明')).style!;
    expect(title.fontSize, greaterThan(subtitle.fontSize!));
    // 拖拽条是一块 36×4 的圆角条。
    final handle = tester
        .widgetList<Container>(find.byType(Container))
        .firstWhere(
          (container) =>
              (container.constraints?.maxWidth ??
                  container.constraints?.minWidth) ==
              36,
          orElse: () => Container(),
        );
    expect(handle, isNot(Container()));
  });

  testWidgets('底部操作固定在内容下方，可关闭按钮可关掉抽屉', (tester) async {
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showModalBottomSheet<void>(
              context: context,
              builder: (_) => AppSheet(
                title: '示例抽屉',
                footer: const Text('主操作'),
                children: [const Text('内容一')],
              ),
            ),
            child: const Text('打开'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    final bodyBottom = tester.getRect(find.text('内容一')).bottom;
    final footerTop = tester.getRect(find.text('主操作')).top;
    expect(footerTop, greaterThan(bodyBottom));

    await tester.tap(find.byTooltip('关闭'));
    await tester.pumpAndSettle();
    expect(find.text('示例抽屉'), findsNothing);
  });

  testWidgets('showClose 为 false 时不显示关闭按钮', (tester) async {
    await tester.pumpWidget(
      _host(
        const AppSheet(
          title: '示例抽屉',
          showClose: false,
          children: [Text('内容一')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('关闭'), findsNothing);
  });

  testWidgets('标题右侧的文字操作与标题、关闭按钮同一水平线', (tester) async {
    await tester.pumpWidget(
      _host(
        AppSheet(
          title: '示例抽屉',
          actions: [AppSheetAction(label: '回到本周', onPressed: () {})],
          children: const [Text('内容一')],
        ),
      ),
    );
    await tester.pumpAndSettle();

    final titleRect = tester.getRect(find.text('示例抽屉'));
    final actionRect = tester.getRect(find.text('回到本周'));
    final closeRect = tester.getRect(find.byTooltip('关闭'));

    expect(actionRect.center.dy, closeTo(titleRect.center.dy, 8));
    expect(closeRect.center.dy, closeTo(titleRect.center.dy, 8));
    // 操作在标题右侧、关闭按钮左边。
    expect(actionRect.left, greaterThan(titleRect.right));
    expect(actionRect.right, lessThanOrEqualTo(closeRect.left));
    expect(
      tester.getSize(find.byType(AppSheetAction)).height,
      greaterThanOrEqualTo(44),
    );
    expect(
      tester.getSize(find.byTooltip('关闭')).height,
      greaterThanOrEqualTo(44),
    );
  });
}
