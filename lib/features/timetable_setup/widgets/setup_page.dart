import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/step_indicator.dart';

class SetupPage extends StatelessWidget {
  const SetupPage({
    required this.title,
    required this.description,
    required this.children,
    required this.footer,
    this.step,
    this.actions,
    super.key,
  });

  final String title;
  final String description;
  final List<Widget> children;
  final Widget footer;
  final int? step;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(title: Text(title), centerTitle: true, actions: actions),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: SingleChildScrollView(
              key: const ValueKey('setup-scroll'),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (step case final current?) ...[
                    Row(
                      children: [
                        StepIndicator(count: 2, current: current),
                        const SizedBox(width: AppSpace.sm),
                        Expanded(
                          child: Text(
                            '首次设置 · ${current + 1} / 2',
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
                  if (keyboardOpen) ...[
                    const SizedBox(height: AppSpace.lg),
                    footer,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: keyboardOpen
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.line)),
              ),
              child: SafeArea(
                top: false,
                child: Center(
                  heightFactor: 1,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.xl,
                        vertical: AppSpace.md,
                      ),
                      child: footer,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
