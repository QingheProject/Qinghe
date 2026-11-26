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

  testWidgets('「课程提醒」行显示真实的提前时间，不出现模板字面量', (tester) async {
    await tester.pumpWidget(const QingheApp());
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('nav-profile')));
    await tester.pumpAndSettle();

    final row = find.byKey(const ValueKey('profile-reminder'));
    await tester.scrollUntilVisible(
      row,
      160,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('profile-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('课前 15 分钟提醒'), findsOneWidget);
    expect(find.textContaining(r'${'), findsNothing);
  });
}
