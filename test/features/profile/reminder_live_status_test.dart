import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/app.dart';
import 'package:qinghe_app/app/routes/app_routes.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(
    () =>
        SharedPreferences.setMockInitialValues({'onboarding_completed': true}),
  );
  tearDown(Get.reset);

  testWidgets('提醒设置页说明实时通知的展示方式与焦点通知状态', (tester) async {
    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();
    Get.toNamed<void>(AppRoutes.reminders);
    await tester.pumpAndSettle();

    final card = find.byKey(const ValueKey('reminder-live-status'));
    await tester.scrollUntilVisible(
      card,
      160,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('reminder-settings-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(card, findsOneWidget);
    expect(
      find.descendant(of: card, matching: find.text('上课中的实时通知')),
      findsOneWidget,
    );
    // 测试环境没有原生通道，按「不支持实时通知」展示。
    expect(
      find.descendant(of: card, matching: find.text('不支持实时通知')),
      findsOneWidget,
    );
  });
}
