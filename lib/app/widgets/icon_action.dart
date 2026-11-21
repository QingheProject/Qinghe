import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';

/// 方形图标按钮，必须提供语义标签。
class IconAction extends StatelessWidget {
  const IconAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Tooltip(
      message: label,
      excludeFromSemantics: true,
      child: Pressable(
        onTap: onTap,
        semanticLabel: label,
        color: filled ? colors.surfaceMuted : colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: SizedBox.square(
          dimension: 44,
          child: Icon(icon, size: 20, color: colors.ink),
        ),
      ),
    );
  }
}
