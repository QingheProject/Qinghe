import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';
import 'package:qinghe_app/data/import/jwxt/jwxt_grades.dart';

class AppAcademicSummary extends StatelessWidget {
  const AppAcademicSummary({
    required this.grades,
    required this.gpaMaximum,
    this.onOpen,
    super.key,
  });

  final JwxtGrades? grades;
  final double? gpaMaximum;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final gpa = grades?.estimatedGpa;
    final maximum = gpaMaximum;
    final credits = grades?.totalCredits;
    final gpaText = gpa?.toStringAsFixed(2) ?? '—';
    final maxText = maximum?.toStringAsFixed(0);
    final creditsText =
        credits?.toString().replaceFirst(RegExp(r'\.0$'), '') ?? '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _MetricTile(
                  label: '绩点',
                  semanticLabel:
                      '估算绩点，$gpaText${maxText == null ? '' : '，满分 $maxText'}',
                  onTap: onOpen,
                  child: Center(
                    child: SizedBox.square(
                      dimension: 88,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (maximum != null)
                            TweenAnimationBuilder<double>(
                              tween: Tween<double>(
                                end: ((gpa ?? 0) / maximum)
                                    .clamp(0, 1)
                                    .toDouble(),
                              ),
                              duration: AppMotion.of(context, AppMotion.medium),
                              curve: AppMotion.emphasized,
                              builder: (_, value, _) =>
                                  CircularProgressIndicator(
                                    value: value,
                                    strokeWidth: 7,
                                    strokeCap: StrokeCap.round,
                                    color: colors.accent,
                                    backgroundColor: colors.surfaceMuted,
                                  ),
                            ),
                          Padding(
                            padding: const EdgeInsets.all(AppSpace.md),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(gpaText, style: text.headlineSmall),
                                  if (maxText != null)
                                    Text('/ $maxText', style: text.labelSmall),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: _MetricTile(
                  label: '学分',
                  semanticLabel: '课程学分合计，${credits ?? '暂无'}',
                  onTap: onOpen,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            creditsText,
                            style: text.displaySmall?.copyWith(
                              color: colors.accent,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpace.xs),
                          Text('课程学分合计', style: text.labelSmall),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        if (grades == null) ...[
          const SizedBox(height: AppSpace.sm),
          Text(
            '未获取到成绩与绩点',
            style: text.labelSmall,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.semanticLabel,
    required this.child,
    this.onTap,
  });

  final String label;
  final String semanticLabel;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final content = ExcludeSemantics(
      child: Column(
        children: [
          Text(label, style: text.labelLarge),
          const SizedBox(height: AppSpace.md),
          SizedBox(height: 88, child: child),
        ],
      ),
    );
    if (onTap == null) {
      return Semantics(
        label: semanticLabel,
        child: AppPanel(
          padding: const EdgeInsets.all(AppSpace.md),
          child: content,
        ),
      );
    }
    return Pressable(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      semanticLabel: semanticLabel,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: content,
      ),
    );
  }
}
