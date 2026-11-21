import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/widgets/brand_mark.dart';

typedef _Destination = ({
  IconData icon,
  IconData activeIcon,
  String label,
  String key,
});

/// 导航顺序固定为首页、课表、我的，课表居中。
const _destinations = <_Destination>[
  (
    icon: Icons.home_outlined,
    activeIcon: Icons.home_rounded,
    label: '首页',
    key: 'nav-home',
  ),
  (
    icon: Icons.calendar_view_week_outlined,
    activeIcon: Icons.calendar_view_week_rounded,
    label: '课表',
    key: 'nav-schedule',
  ),
  (
    icon: Icons.person_outline_rounded,
    activeIcon: Icons.person_rounded,
    label: '我的',
    key: 'nav-profile',
  ),
];

const _barRadius = 34.0;
const _itemRadius = 26.0;

/// 窄屏底部悬浮导航：毛玻璃浮条，选中项的底色块随切换滑动。
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    required this.selectedIndex,
    required this.onSelected,
    required this.floating,
    required this.contentStyle,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final bool floating;
  final NavigationContentStyle contentStyle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final count = _destinations.length;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final height = contentStyle == NavigationContentStyle.iconsAndLabels
        ? 68.0
        : 58.0;

    final bar = SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.all(floating ? 6 : 4),
        child: Stack(
          children: [
            AnimatedAlign(
              alignment: Alignment(-1 + 2 * selectedIndex / (count - 1), 0),
              duration: AppMotion.of(context, AppMotion.medium),
              curve: AppMotion.emphasized,
              child: FractionallySizedBox(
                widthFactor: 1 / count,
                heightFactor: 1,
                child: floating
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          color: colors.accentSoft.withValues(alpha: 0.86),
                          borderRadius: BorderRadius.circular(_itemRadius),
                        ),
                      )
                    : Align(
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: 24,
                          height: 3,
                          decoration: BoxDecoration(
                            color: colors.accent,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
              ),
            ),
            Row(
              children: [
                for (var index = 0; index < count; index++)
                  Expanded(
                    child: _NavItem(
                      destination: _destinations[index],
                      selected: index == selectedIndex,
                      contentStyle: contentStyle,
                      onTap: () => onSelected(index),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    if (!floating) {
      return DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.line)),
        ),
        child: SafeArea(top: false, child: bar),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, math.max(bottomInset, 12) + 4),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: _GlassPanel(child: bar),
        ),
      ),
    );
  }
}

/// 宽窗口侧栏：与底栏使用同一套毛玻璃表面。
class AppSideRail extends StatelessWidget {
  const AppSideRail({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _itemHeight = 64.0;
  static const _width = 76.0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      right: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _GlassPanel(
          child: SizedBox(
            width: _width,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Column(
                children: [
                  const SizedBox(height: 14),
                  const BrandMark(size: 34),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: _itemHeight * _destinations.length,
                    child: Stack(
                      children: [
                        AnimatedPositioned(
                          duration: AppMotion.of(context, AppMotion.medium),
                          curve: AppMotion.emphasized,
                          left: 0,
                          right: 0,
                          top: selectedIndex * _itemHeight,
                          height: _itemHeight,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: colors.accentSoft.withValues(alpha: 0.86),
                              borderRadius: BorderRadius.circular(_itemRadius),
                            ),
                          ),
                        ),
                        Column(
                          children: [
                            for (
                              var index = 0;
                              index < _destinations.length;
                              index++
                            )
                              SizedBox(
                                height: _itemHeight,
                                child: _NavItem(
                                  destination: _destinations[index],
                                  selected: index == selectedIndex,
                                  contentStyle:
                                      NavigationContentStyle.iconsAndLabels,
                                  onTap: () => onSelected(index),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(_barRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: dark ? 0.72 : 0.82),
            borderRadius: BorderRadius.circular(_barRadius),
            border: Border.all(
              color: colors.line.withValues(alpha: dark ? 0.72 : 0.9),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.contentStyle,
    required this.onTap,
  });

  final _Destination destination;
  final bool selected;
  final NavigationContentStyle contentStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.accent : colors.inkFaint;
    final duration = AppMotion.of(context, AppMotion.fast);
    final showIcon = contentStyle != NavigationContentStyle.labels;
    final showLabel = contentStyle != NavigationContentStyle.icons;

    return Semantics(
      button: true,
      selected: selected,
      enabled: !selected,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: ValueKey(destination.key),
          onTap: selected ? null : onTap,
          borderRadius: BorderRadius.circular(_itemRadius),
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll(Colors.transparent),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showIcon)
                AnimatedSwitcher(
                  duration: duration,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: ScaleTransition(
                      scale: animation.drive(Tween(begin: 0.7, end: 1)),
                      child: child,
                    ),
                  ),
                  child: Icon(
                    selected ? destination.activeIcon : destination.icon,
                    key: ValueKey(selected),
                    size: 22,
                    color: color,
                  ),
                ),
              if (showIcon && showLabel) const SizedBox(height: 2),
              if (showLabel)
                AnimatedDefaultTextStyle(
                  duration: duration,
                  style: Theme.of(context).textTheme.labelSmall!.copyWith(
                    color: color,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  child: Text(destination.label),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
