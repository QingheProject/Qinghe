import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';

enum AppTagTone { accent, neutral, faint }

/// 小号方角标签，用于周次、状态等短信息。
class AppTag extends StatelessWidget {
  const AppTag({
    required this.label,
    this.tone = AppTagTone.neutral,
    this.icon,
    super.key,
  });

  final String label;
  final AppTagTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final (background, foreground) = switch (tone) {
      AppTagTone.accent => (colors.accentSoft, colors.accent),
      AppTagTone.neutral => (colors.surfaceMuted, colors.inkMuted),
      AppTagTone.faint => (
        colors.surfaceMuted.withValues(alpha: 0.6),
        colors.inkFaint,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: AppSpace.xs),
          ],
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
