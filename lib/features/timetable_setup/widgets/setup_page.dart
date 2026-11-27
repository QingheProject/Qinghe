import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/app_page.dart';
import 'package:qinghe_app/app/widgets/step_indicator.dart';

class SetupPage extends StatelessWidget {
  const SetupPage({
    required this.title,
    required this.description,
    required this.children,
    required this.footer,
    this.step,
    this.stepCount = 2,
    this.actions,
    super.key,
  });

  final String title;
  final String description;
  final List<Widget> children;
  final Widget footer;
  final int? step;

  /// 首次设置的总步数，用于步骤指示。
  final int stepCount;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppFormPage(
      title: title,
      actions: actions,
      footer: footer,
      scrollKey: const ValueKey('setup-scroll'),
      children: [
        if (step case final current?) ...[
          Row(
            children: [
              StepIndicator(count: stepCount, current: current),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  '首次设置 · ${current + 1} / $stepCount',
                  style: text.labelMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
        ],
        Text(description, style: text.bodySmall),
        const SizedBox(height: AppSpace.lg),
        ...children,
      ],
    );
  }
}
