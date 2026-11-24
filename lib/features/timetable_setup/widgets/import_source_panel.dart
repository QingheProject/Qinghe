import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';
import 'package:qinghe_app/data/import/timetable_import.dart';

/// 导入方式：教务系统、CSV、JSON 三选一，选中后立即读取数据。
class ImportSourcePanel extends StatelessWidget {
  const ImportSourcePanel({
    required this.schoolSubtitle,
    required this.hasSchool,
    required this.fileType,
    required this.ruleCount,
    required this.onSelect,
    required this.onCopyTemplate,
    required this.onSchool,
    required this.onPickSchool,
    required this.onClear,
    this.draftLabel,
    this.issue,
    super.key,
  });

  final String schoolSubtitle;
  final bool hasSchool;
  final TimetableFileType? fileType;
  final int ruleCount;

  /// 教务系统等非文件来源的名称，用于替换文件类型标签。
  final String? draftLabel;
  final ValueChanged<TimetableFileType>? onSelect;
  final VoidCallback? onCopyTemplate;

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
    final loaded = fileType != null || draftLabel != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: AppSpace.sm),
          child: Text('选择导入方式', style: text.labelMedium),
        ),
        _SourceButton(
          key: const ValueKey('import-jwxt'),
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
          key: const ValueKey('import-csv'),
          title: 'CSV 文件',
          subtitle: '按青禾模板填写的表格',
          selected: fileType == TimetableFileType.csv,
          onTap: onSelect == null
              ? null
              : () => onSelect!(TimetableFileType.csv),
        ),
        const SizedBox(height: AppSpace.sm),
        _SourceButton(
          key: const ValueKey('import-json'),
          title: 'JSON 文件',
          subtitle: '可同时带上学期配置',
          selected: fileType == TimetableFileType.json,
          onTap: onSelect == null
              ? null
              : () => onSelect!(TimetableFileType.json),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onCopyTemplate,
            icon: const Icon(AppIcons.copy, size: 15),
            label: const Text('复制 CSV 模板'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
              foregroundColor: colors.inkMuted,
              textStyle: text.bodySmall,
            ),
          ),
        ),
        if (loaded) ...[
          const SizedBox(height: AppSpace.xs),
          _LoadedStrip(
            label: fileType?.name.toUpperCase() ?? draftLabel ?? '',
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
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.selected = false,
    this.trailing,
    super.key,
  });

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
