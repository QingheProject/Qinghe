import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';

/// 沿用原生折叠控制器，让 Phosphor 箭头跟随展开状态旋转。
class AppExpansionIcon extends StatelessWidget {
  const AppExpansionIcon({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ExpansibleController.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) => AnimatedRotation(
        turns: controller.isExpanded ? -0.5 : 0,
        duration: AppMotion.of(context, AppMotion.medium),
        curve: Curves.easeIn,
        child: child,
      ),
      child: const Icon(AppIcons.chevronDown, size: 20),
    );
  }
}
