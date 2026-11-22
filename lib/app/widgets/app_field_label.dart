import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';

/// 字段名固定在输入区外，输入内容和错误提示不挤占标签的位置。
class AppFieldLabel extends StatelessWidget {
  const AppFieldLabel({required this.label, required this.child, super.key});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.only(
            left: AppSpace.xs,
            bottom: AppSpace.sm,
          ),
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
      ),
      Semantics(label: label, child: child),
    ],
  );
}
