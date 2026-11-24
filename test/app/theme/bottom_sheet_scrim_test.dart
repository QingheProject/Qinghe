import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_theme.dart';

void main() {
  /// 遮罩必须始终是黑色：暗色主题的文字色接近白色，直接拿它当遮罩会让抽屉发亮。
  Color barrierOf(ThemeData theme) =>
      theme.bottomSheetTheme.modalBarrierColor ?? Colors.black54;

  test('亮色主题的抽屉遮罩是深色', () {
    final barrier = barrierOf(AppTheme.light);
    expect(barrier.a, greaterThan(0.2));
    expect(barrier.computeLuminance(), lessThan(0.05), reason: '遮罩颜色应当接近黑色');
  });

  test('暗色主题的抽屉遮罩同样是黑色，不会变白', () {
    final theme = AppTheme.dark;
    final barrier = barrierOf(theme);

    // 暗色主题里 ink 是近白色，用它做遮罩正是之前发亮的原因。
    expect(
      theme.extension<AppColors>()!.ink.computeLuminance(),
      greaterThan(0.5),
    );
    expect(barrier.computeLuminance(), lessThan(0.05));
    expect(barrier.a, greaterThan(0.5));
  });

  test('暗色主题的抽屉底色仍然是深色', () {
    final theme = AppTheme.dark;
    expect(
      theme.bottomSheetTheme.backgroundColor!.computeLuminance(),
      lessThan(0.1),
    );
  });
}
