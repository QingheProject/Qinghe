import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/app_field_label.dart';

class AppPeriodEditRow extends StatelessWidget {
  const AppPeriodEditRow({
    required this.period,
    required this.startField,
    required this.endTime,
    super.key,
  });

  final int period;
  final Widget startField;
  final String endTime;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final timeStyle = text.bodyMedium?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Semantics(
      container: true,
      label: '第 $period 节',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.xl + AppSpace.sm),
            child: ExcludeSemantics(
              child: Container(
                constraints: const BoxConstraints(minWidth: 36),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.accentSoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                padding: const EdgeInsets.all(AppSpace.sm),
                child: Text(
                  '$period',
                  style: text.labelLarge?.copyWith(color: colors.accent),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: AppFieldLabel(label: '上课', child: startField),
          ),
          const SizedBox(width: AppSpace.md),
          Flexible(
            child: AppFieldLabel(
              label: '下课',
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.xs,
                  vertical: AppSpace.md,
                ),
                child: Text(endTime, style: timeStyle),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
