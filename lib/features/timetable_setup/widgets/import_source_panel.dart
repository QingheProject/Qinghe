import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';
import 'package:qinghe_app/data/import/timetable_import.dart';

class ImportSourcePanel extends StatelessWidget {
  const ImportSourcePanel({
    required this.school,
    required this.fileType,
    required this.ruleCount,
    required this.onSelect,
    required this.onCopyTemplate,
    required this.onSchool,
    required this.onClear,
    this.issue,
    super.key,
  });

  final String school;
  final TimetableFileType? fileType;
  final int ruleCount;
  final ValueChanged<TimetableFileType>? onSelect;
  final VoidCallback? onCopyTemplate;
  final VoidCallback? onSchool;
  final VoidCallback? onClear;
  final Widget? issue;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final csv = _ImportChoice(
      icon: Icons.table_chart_outlined,
      title: 'CSV 模板',
      description: '表格课表',
      selected: fileType == TimetableFileType.csv,
      onTap: onSelect == null ? null : () => onSelect!(TimetableFileType.csv),
    );
    final json = _ImportChoice(
      icon: Icons.data_object_rounded,
      title: 'JSON 文件',
      description: '支持学期配置',
      selected: fileType == TimetableFileType.json,
      onTap: onSelect == null ? null : () => onSelect!(TimetableFileType.json),
    );

    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('导入来源', style: text.titleMedium),
          const SizedBox(height: AppSpace.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final stack =
                  constraints.maxWidth < 270 ||
                  MediaQuery.textScalerOf(context).scale(14) >= 20;
              if (stack) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    csv,
                    const SizedBox(height: AppSpace.sm),
                    json,
                  ],
                );
              }
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: csv),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(child: json),
                  ],
                ),
              );
            },
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onCopyTemplate,
              icon: const Icon(Icons.content_copy_rounded, size: 16),
              label: const Text('复制 CSV 模板'),
            ),
          ),
          const Divider(height: 1),
          AppListRow(
            icon: Icons.school_outlined,
            title: '教务系统',
            subtitle: school.isEmpty ? '请先选择学校' : '$school · 暂未适配',
            onTap: onSchool,
          ),
          if (fileType != null) ...[
            const SizedBox(height: AppSpace.xs),
            Semantics(
              liveRegion: true,
              child: Material(
                color: colors.accentSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: ListTile(
                  dense: true,
                  leading: Icon(
                    Icons.check_circle_outline,
                    color: colors.accent,
                  ),
                  title: Text(
                    '${fileType!.name.toUpperCase()} · 已读取 $ruleCount 条安排',
                    style: text.bodyMedium,
                  ),
                  trailing: IconButton(
                    onPressed: onClear,
                    tooltip: '移除待导入文件',
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
              ),
            ),
          ],
          if (issue case final message?) ...[
            const SizedBox(height: AppSpace.sm),
            message,
          ],
        ],
      ),
    );
  }
}

class _ImportChoice extends StatelessWidget {
  const _ImportChoice({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Pressable(
      borderRadius: BorderRadius.circular(AppRadius.md),
      color: selected ? colors.accentSoft : colors.surfaceMuted,
      selected: selected,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_rounded : icon,
              color: selected ? colors.accent : colors.inkMuted,
              size: 22,
            ),
            const SizedBox(height: AppSpace.sm),
            Text(title, style: text.titleMedium),
            const SizedBox(height: 2),
            Text(description, style: text.bodySmall),
          ],
        ),
      ),
    );
  }
}
