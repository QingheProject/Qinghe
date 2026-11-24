import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_theme.dart';
import 'package:qinghe_app/app/widgets/app_button.dart';
import 'package:qinghe_app/data/import/timetable_import.dart';
import 'package:qinghe_app/features/timetable_setup/views/json_import_page.dart';

Widget _host(Widget child) =>
    GetMaterialApp(theme: AppTheme.lightFor(AppAccentTone.qinghe), home: child);

void main() {
  tearDown(Get.reset);

  testWidgets('插入模板后可以直接导入', (tester) async {
    await tester.pumpWidget(_host(const JsonImportPage()));

    // 没有内容时导入按钮不可用。
    expect(tester.widget<AppButton>(find.byType(AppButton)).onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('json-insert-template')));
    await tester.pumpAndSettle();

    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('json-input')),
    );
    expect(field.controller!.text, contains('"version": 1'));
    expect(
      tester.widget<AppButton>(find.byType(AppButton)).onPressed,
      isNotNull,
    );
    expect(find.text('导入这份课表'), findsOneWidget);
  });

  testWidgets('粘贴合法 JSON 后回传解析结果', (tester) async {
    Object? returned;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () async {
                returned = await Get.to<Object?>(() => const JsonImportPage());
              },
              child: const Text('打开'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('打开'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('json-input')),
      TimetableImport.jsonTemplate,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('导入这份课表'));
    await tester.pumpAndSettle();

    expect(returned, isA<TimetableImport>());
    expect((returned! as TimetableImport).rules, hasLength(1));
  });

  testWidgets('粘贴内容有误时在页面内提示，不退出', (tester) async {
    await tester.pumpWidget(_host(const JsonImportPage()));

    await tester.enterText(
      find.byKey(const ValueKey('json-input')),
      '{"version": 9}',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('导入这份课表'));
    await tester.pumpAndSettle();

    expect(find.textContaining('仅支持青禾 JSON 版本 1'), findsOneWidget);
    expect(find.byKey(const ValueKey('json-input')), findsOneWidget);
  });
}
