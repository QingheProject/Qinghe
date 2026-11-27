import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';

/// Centers ordinary page content while leaving specialized layouts independent.
class AppPageContent extends StatelessWidget {
  const AppPageContent({required this.child, super.key});

  static const padding = EdgeInsets.fromLTRB(
    AppSpace.xl,
    AppSpace.lg,
    AppSpace.xl,
    32,
  );

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: AppSpace.pageMaxWidth),
        child: child,
      ),
    );
  }
}

class AppPageFooter extends StatelessWidget {
  const AppPageFooter({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: SafeArea(
        top: false,
        child: AppPageContent(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpace.xl,
              vertical: AppSpace.md,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class AppFormPage extends StatelessWidget {
  const AppFormPage({
    required this.title,
    required this.children,
    required this.footer,
    this.actions,
    this.scrollKey,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final Widget footer;
  final List<Widget>? actions;
  final Key? scrollKey;

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(
        child: AppPageContent(
          child: SingleChildScrollView(
            key: scrollKey,
            padding: AppPageContent.padding,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
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
      bottomNavigationBar: keyboardOpen ? null : AppPageFooter(child: footer),
    );
  }
}
