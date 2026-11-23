import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
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
    icon: AppIcons.home,
    activeIcon: AppIcons.homeFill,
    label: '首页',
    key: 'nav-home',
  ),
  (
    icon: AppIcons.calendar,
    activeIcon: AppIcons.calendarFill,
    label: '课表',
    key: 'nav-schedule',
  ),
  (
    icon: AppIcons.user,
    activeIcon: AppIcons.userFill,
    label: '我的',
    key: 'nav-profile',
  ),
];

const _barRadius = 34.0;
const _itemRadius = 26.0;

/// 窄屏底部悬浮导航：毛玻璃浮条，选中块以橡胶粘性的方式滑向目标。
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    required this.selectedIndex,
    required this.onSelected,
    super.key,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final count = _destinations.length;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final bar = SizedBox(
      height: 68,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Stack(
          children: [
            Positioned.fill(
              child: _RubberPill(
                index: selectedIndex,
                count: count,
                axis: Axis.horizontal,
                slotInset: 0.045,
                crossInset: 1.5,
                selectionKey: const ValueKey('bottom-bar-selection'),
                decoration: BoxDecoration(
                  color: colors.accentSoft.withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(_itemRadius),
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
                      onTap: () => onSelected(index),
                      suppressRipple: true,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 0, 16, math.max(bottomInset, 12) + 4),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: _GlassPanel(transparent: true, child: bar),
        ),
      ),
    );
  }
}

/// 宽窗口侧栏：与底栏使用同一套毛玻璃表面与橡胶选中块。
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
  static const _tileInset = 4.0;

  /// 面板与选中块都用圆角矩形，整条不再是胶囊形状。
  static const _panelRadius = AppRadius.xl;
  static const _tileRadius = AppRadius.md;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SafeArea(
      right: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: _GlassPanel(
          key: const ValueKey('side-rail-panel'),
          radius: _panelRadius,
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
                    width: double.infinity,
                    child: Stack(
                      fit: StackFit.passthrough,
                      children: [
                        Positioned.fill(
                          child: _RubberPill(
                            index: selectedIndex,
                            count: _destinations.length,
                            axis: Axis.vertical,
                            slotInset: _tileInset / _itemHeight,
                            crossInset: _tileInset,
                            selectionKey: const ValueKey('side-rail-selection'),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colors.accentSoft,
                                  Color.alphaBlend(
                                    colors.accent.withValues(alpha: 0.12),
                                    colors.accentSoft,
                                  ),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(_tileRadius),
                              boxShadow: [
                                BoxShadow(
                                  color: colors.accent.withValues(alpha: 0.18),
                                  blurRadius: 16,
                                  spreadRadius: -2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
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
                                  borderRadius: BorderRadius.circular(
                                    _tileRadius,
                                  ),
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

/// 橡胶分段指示器：朝移动方向的前缘先出发，后缘粘性延迟跟随并轻微回弹，
/// 拉伸过程中沿交叉轴压扁，模拟橡胶被拽动再回弹的手感。
class _RubberPill extends StatefulWidget {
  const _RubberPill({
    required this.index,
    required this.count,
    required this.axis,
    required this.slotInset,
    required this.decoration,
    this.crossInset = 0,
    this.selectionKey,
  });

  final int index;
  final int count;
  final Axis axis;

  /// 行程轴上每侧的内缩，单位为单个槽位的比例。
  final double slotInset;

  /// 交叉轴上每侧的内缩，逻辑像素。
  final double crossInset;
  final Decoration decoration;
  final Key? selectionKey;

  @override
  State<_RubberPill> createState() => _RubberPillState();
}

class _RubberPillState extends State<_RubberPill>
    with SingleTickerProviderStateMixin {
  static const _leadCurve = Interval(0, 0.68, curve: Cubic(0.2, 0.67, 0.35, 1));
  static const _trailCurve = Interval(
    0.18,
    1,
    curve: Cubic(0.36, 0.84, 0.54, 1.12),
  );

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 480),
    value: 1,
  );

  late RangeValues _target;
  late RangeValues _from;
  bool _forward = true;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _from = _target = _slotEdges(widget);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = AppMotion.reduced(context);
    if (_reduceMotion) _controller.value = 1;
  }

  @override
  void didUpdateWidget(_RubberPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    final target = _slotEdges(widget);
    if (target == _target) return;

    // 改点或反向时，从当前两条边的位置接续，保留尚未收回的形变。
    _from = _currentEdges;
    _target = target;
    _forward = _target.start + _target.end > _from.start + _from.end;
    if (_reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  static RangeValues _slotEdges(_RubberPill pill) =>
      RangeValues(pill.index + pill.slotInset, pill.index + 1 - pill.slotInset);

  RangeValues get _currentEdges {
    final progress = _controller.value;
    final lead = _leadCurve.transform(progress);
    final trail = _trailCurve.transform(progress);
    final limit = widget.count.toDouble();
    final start = lerpDouble(
      _from.start,
      _target.start,
      _forward ? trail : lead,
    )!.clamp(0.0, limit).toDouble();
    final end = lerpDouble(
      _from.end,
      _target.end,
      _forward ? lead : trail,
    )!.clamp(start, limit).toDouble();
    return RangeValues(start, end);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontal = widget.axis == Axis.horizontal;
        final mainSize = horizontal
            ? constraints.maxWidth
            : constraints.maxHeight;
        final crossExtent = horizontal
            ? constraints.maxHeight
            : constraints.maxWidth;
        final restCrossSize = math.max(
          0.0,
          crossExtent - widget.crossInset * 2,
        );
        final slotSize = mainSize / widget.count;
        return AnimatedBuilder(
          animation: _controller,
          child: DecoratedBox(
            key: widget.selectionKey,
            decoration: widget.decoration,
          ),
          builder: (context, pill) {
            final edges = _currentEdges;
            final length = edges.end - edges.start;
            final restLength = _target.end - _target.start;
            final stretch = length / restLength - 1;
            // 拉长时变薄，后缘赶上并短暂压缩时略微鼓起。
            final crossSize = math.min(
              crossExtent,
              restCrossSize * (1 - 0.18 * stretch.clamp(-0.35, 1.0)),
            );
            final crossOffset = (crossExtent - crossSize) / 2;
            return Stack(
              children: [
                horizontal
                    ? PositionedDirectional(
                        start: edges.start * slotSize,
                        width: length * slotSize,
                        top: crossOffset,
                        height: crossSize,
                        child: pill!,
                      )
                    : Positioned(
                        top: edges.start * slotSize,
                        height: length * slotSize,
                        left: crossOffset,
                        width: crossSize,
                        child: pill!,
                      ),
              ],
            );
          },
        );
      },
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.radius = _barRadius,
    this.transparent = false,
    super.key,
  });

  final Widget child;
  final double radius;
  final bool transparent;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final blur = transparent ? 10.0 : 18.0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: transparent
                ? null
                : colors.surface.withValues(alpha: dark ? 0.72 : 0.82),
            borderRadius: BorderRadius.circular(radius),
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
    required this.onTap,
    this.suppressRipple = false,
    this.borderRadius = const BorderRadius.all(Radius.circular(_itemRadius)),
  });

  final _Destination destination;
  final bool selected;
  final VoidCallback onTap;
  final bool suppressRipple;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.accent : colors.inkMuted;
    final duration = AppMotion.of(context, AppMotion.fast);

    return Semantics(
      button: true,
      selected: selected,
      enabled: !selected,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: ValueKey(destination.key),
          onTap: selected ? null : onTap,
          borderRadius: borderRadius,
          splashFactory: suppressRipple ? NoSplash.splashFactory : null,
          highlightColor: suppressRipple ? Colors.transparent : null,
          overlayColor: suppressRipple
              ? WidgetStateProperty.resolveWith((states) {
                  if (selected || states.contains(WidgetState.pressed)) {
                    return Colors.transparent;
                  }
                  final active =
                      states.contains(WidgetState.hovered) ||
                      states.contains(WidgetState.focused);
                  return active ? colors.ink.withValues(alpha: 0.06) : null;
                })
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
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
              const SizedBox(height: 2),
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
