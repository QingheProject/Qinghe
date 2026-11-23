import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';

/// 周次切换器：上一周、当前教学周、下一周。
class ScheduleWeekSwitcher extends StatelessWidget {
  const ScheduleWeekSwitcher({
    required this.teachingWeek,
    required this.direction,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final int? teachingWeek;

  /// 最近一次切换的方向：1 表示下一周，-1 表示上一周。
  final int direction;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final label = teachingWeek == null ? '学期外' : '第 $teachingWeek 周';

    return Semantics(
      container: true,
      label: '周次切换',
      child: Material(
        key: const ValueKey('schedule-week-switcher'),
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ArrowButton(
              key: const ValueKey('schedule-week-previous'),
              icon: AppIcons.arrowBack,
              tooltip: '上一周',
              onTap: onPrevious,
            ),
            SizedBox(
              width: 66,
              child: AnimatedSwitcher(
                duration: AppMotion.of(context, AppMotion.fast),
                switchInCurve: AppMotion.emphasized,
                switchOutCurve: AppMotion.emphasized,
                transitionBuilder: (child, animation) {
                  final entering = animation.status != AnimationStatus.reverse;
                  final begin = Offset(
                    (entering ? direction : -direction) * 0.4,
                    0,
                  );
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: animation.drive(
                        Tween(
                          begin: begin,
                          end: Offset.zero,
                        ).chain(CurveTween(curve: AppMotion.emphasized)),
                      ),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  label,
                  key: ValueKey(label),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  style: text.labelMedium?.copyWith(
                    color: colors.ink,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            _ArrowButton(
              key: const ValueKey('schedule-week-next'),
              icon: AppIcons.arrowForward,
              tooltip: '下一周',
              onTap: onNext,
            ),
          ],
        ),
      ),
    );
  }
}

/// 非本周时出现的返回按钮；本周内收缩为零高度。
class ScheduleTodayButton extends StatelessWidget {
  const ScheduleTodayButton({
    required this.visible,
    required this.onTap,
    super.key,
  });

  final bool visible;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    return AnimatedSize(
      duration: AppMotion.of(context, AppMotion.medium),
      curve: AppMotion.emphasized,
      alignment: Alignment.centerRight,
      child: AnimatedOpacity(
        duration: AppMotion.of(context, AppMotion.fast),
        opacity: visible ? 1 : 0,
        child: visible
            ? Pressable(
                key: const ValueKey('schedule-week-today'),
                onTap: onTap,
                color: colors.accentSoft,
                borderRadius: BorderRadius.circular(AppRadius.xs),
                semanticLabel: '回到本周',
                splashColor: colors.accent.withValues(alpha: 0.16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  child: Text(
                    '回到本周',
                    style: text.labelSmall?.copyWith(
                      color: colors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Pressable(
        onTap: onTap,
        splashColor: context.colors.ink.withValues(alpha: 0.08),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Icon(icon, size: 17, color: context.colors.inkMuted),
        ),
      ),
    );
  }
}
