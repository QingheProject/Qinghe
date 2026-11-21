import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';

/// 扁平线段式步骤指示：当前步拉长并加深，其余保持短线。
class StepIndicator extends StatelessWidget {
  const StepIndicator({required this.count, required this.current, super.key});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final duration = AppMotion.of(context, AppMotion.medium);

    return Semantics(
      label: '第 ${current + 1} 步，共 $count 步',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var index = 0; index < count; index++)
              AnimatedContainer(
                duration: duration,
                curve: AppMotion.emphasized,
                margin: const EdgeInsets.only(right: 6),
                width: index == current ? 24 : 8,
                height: 4,
                decoration: BoxDecoration(
                  color: index == current
                      ? colors.ink
                      : index < current
                      ? colors.inkFaint
                      : colors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
