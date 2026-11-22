import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/utils/formatters.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/data/import/timetable_import_preview.dart';
import 'package:qinghe_app/data/models/timetable_rule.dart';

class ImportPreviewPanel extends StatelessWidget {
  const ImportPreviewPanel({
    required this.preview,
    required this.acceptOverlap,
    required this.onAcceptOverlap,
    super.key,
  });

  final TimetableImportPreview preview;
  final bool acceptOverlap;
  final ValueChanged<bool?>? onAcceptOverlap;

  String _summary(TimetableRule rule) => [
    weekdayLabel(rule.weekday),
    formatPeriods(rule.startPeriod, rule.endPeriod),
    '第 ${rule.weeks.join('、')} 周',
    if (rule.location.isNotEmpty) rule.location,
    if (rule.teacher.isNotEmpty) rule.teacher,
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return AppPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('导入预览', style: text.titleMedium),
          const SizedBox(height: AppSpace.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: AppMetric(label: '新增安排', value: preview.added.length),
              ),
              Expanded(
                child: AppMetric(label: '更新安排', value: preview.updated.length),
              ),
              Expanded(
                child: AppMetric(label: '时间重叠', value: preview.conflictCount),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          if (preview.added.isEmpty && preview.updated.isEmpty)
            Text('课程安排与当前课表一致。', style: text.bodySmall),
          if (preview.added.isNotEmpty)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              shape: const Border(),
              title: const Text('查看新增安排'),
              children: [
                for (final rule in preview.added)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(rule.name),
                    subtitle: Text(_summary(rule)),
                  ),
              ],
            ),
          if (preview.updated.isNotEmpty)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              shape: const Border(),
              title: const Text('查看更新前后'),
              children: [
                for (final (before, after) in preview.updated)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(after.name),
                    subtitle: Text(
                      '原安排：${before.name} · ${_summary(before)}\n新安排：${after.name} · ${_summary(after)}',
                    ),
                  ),
              ],
            ),
          if (preview.conflictCount > 0) ...[
            const Divider(),
            const SizedBox(height: AppSpace.sm),
            Text('请核对重叠课程', style: text.titleMedium),
            const SizedBox(height: AppSpace.xs),
            for (final (left, right) in preview.conflicts)
              Text(
                '${weekdayLabel(left.weekday)} · ${left.name} 与 ${right.name}',
                style: text.bodySmall,
              ),
            if (preview.conflictCount > preview.conflicts.length)
              Text(
                '另有 ${preview.conflictCount - preview.conflicts.length} 处重叠。',
                style: text.bodySmall,
              ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('保留这些安排'),
              value: acceptOverlap,
              onChanged: onAcceptOverlap,
            ),
          ],
        ],
      ),
    );
  }
}
