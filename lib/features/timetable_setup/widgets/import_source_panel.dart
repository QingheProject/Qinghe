import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';

/// 导入方式：教务系统或粘贴 JSON，两者各是一个按钮。
class ImportSourcePanel extends StatelessWidget {
  const ImportSourcePanel({
    required this.schoolSubtitle,
    required this.hasSchool,
    required this.jsonSelected,
    required this.ruleCount,
    required this.onJson,
    required this.onSchool,
    required this.onPickSchool,
    required this.onClear,
    this.draftLabel,
    this.issue,
    super.key,
  });

  final String schoolSubtitle;
  final bool hasSchool;

  /// 当前待导入数据是否来自粘贴的 JSON。
  final bool jsonSelected;
  final int ruleCount;

  /// 已读取数据的来源名称。
  final String? draftLabel;

  /// 打开粘贴 JSON 页面。
  final VoidCallback? onJson;

  /// 使用教务系统导入。
  final VoidCallback? onSchool;

  /// 打开学校列表更换学校。
  final VoidCallback? onPickSchool;
  final VoidCallback? onClear;
  final Widget? issue;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final loaded = draftLabel != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpace.sm),
          child: Text('选择导入方式', style: text.labelMedium),
        ),
        _SourceButton(
          key: const ValueKey('import-jwxt'),
          icon: AppIcons.school,
          title: '教务系统',
          subtitle: schoolSubtitle,
          trailing: IconButton(
            key: const ValueKey('import-pick-school'),
            tooltip: hasSchool ? '更换学校' : '选择学校',
            onPressed: onPickSchool,
            icon: const Icon(AppIcons.swap, size: 18),
            color: colors.inkMuted,
            visualDensity: VisualDensity.compact,
          ),
          onTap: onSchool,
        ),
        const SizedBox(height: AppSpace.sm),
        _SourceButton(
          key: const ValueKey('import-json'),
          icon: AppIcons.code,
          title: '粘贴 JSON',
          subtitle: '直接输入课表 JSON，可插入模板',
          selected: jsonSelected,
          onTap: onJson,
        ),
        if (loaded) ...[
          const SizedBox(height: AppSpace.sm),
          _LoadedStrip(
            label: draftLabel ?? '',
            count: ruleCount,
            onClear: onClear,
          ),
        ],
        if (issue case final message?) ...[
          const SizedBox(height: AppSpace.sm),
          message,
        ],
      ],
    );
  }
}

/// 一个导入方式：独立的圆角按钮，彼此之间留出间隔。
class _SourceButton extends StatelessWidget {
  const _SourceButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.selected = false,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool selected;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      selected: selected,
      label: '$title，$subtitle',
      child: Pressable(
        color: selected ? colors.accentSoft : colors.surface,
        selected: selected,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.md,
            AppSpace.sm,
            AppSpace.md,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: selected
                  ? colors.accent.withValues(alpha: 0.45)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? colors.accent : colors.inkMuted,
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: text.titleMedium?.copyWith(color: colors.ink),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: colors.inkMuted),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else ...[
                if (selected)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpace.sm),
                    child: Icon(AppIcons.check, size: 17, color: colors.accent),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpace.sm),
                    child: Icon(
                      AppIcons.chevronRight,
                      size: 16,
                      color: colors.inkFaint,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LoadedStrip extends StatelessWidget {
  const _LoadedStrip({
    required this.label,
    required this.count,
    required this.onClear,
  });

  final String label;
  final int count;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, 4, 4, 4),
        decoration: BoxDecoration(
          color: colors.accentSoft,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          children: [
            Icon(AppIcons.checkCircle, size: 17, color: colors.accent),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: Text(
                '$label · 已读取 $count 条安排',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodyMedium,
              ),
            ),
            IconButton(
              onPressed: onClear,
              tooltip: '移除已读取的数据',
              icon: const Icon(AppIcons.close, size: 18),
              color: colors.inkMuted,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
