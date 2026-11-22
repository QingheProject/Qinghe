import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/utils/formatters.dart';
import 'package:qinghe_app/app/widgets/app_field_label.dart';
import 'package:qinghe_app/app/widgets/app_expansion_icon.dart';
import 'package:qinghe_app/app/widgets/app_period_edit_row.dart';
import 'package:qinghe_app/data/models/semester_config.dart';

class SemesterFields extends StatefulWidget {
  const SemesterFields({
    required this.initial,
    required this.onChanged,
    super.key,
  });

  final SemesterConfig? initial;
  final ValueChanged<SemesterConfig?> onChanged;

  @override
  State<SemesterFields> createState() => _SemesterFieldsState();
}

class _SemesterFieldsState extends State<SemesterFields> {
  late final _name = TextEditingController(text: widget.initial?.name ?? '');
  late final _monday = TextEditingController(
    text: widget.initial?.firstDay ?? '',
  );
  late final _weeks = TextEditingController(
    text: (widget.initial?.weekCount ?? 18).toString(),
  );
  late final _duration = TextEditingController(
    text: (widget.initial?.periodDurationMinutes ?? 45).toString(),
  );
  late final _starts = [
    for (final time
        in widget.initial?.periodStartTimes ??
            AppearanceController.defaultScheduleStartTimes)
      TextEditingController(text: time),
  ];

  @override
  void dispose() {
    for (final field in [_name, _monday, _weeks, _duration, ..._starts]) {
      field.dispose();
    }
    super.dispose();
  }

  void _changed() {
    final monday = SemesterConfig.parseDay(_monday.text.trim());
    final weeks = int.tryParse(_weeks.text.trim());
    final duration = int.tryParse(_duration.text.trim());
    final config = monday == null || weeks == null || duration == null
        ? null
        : SemesterConfig(
            name: _name.text.trim(),
            week1Monday: monday,
            weekCount: weeks,
            periodStartTimes: _starts
                .map((field) => field.text.trim())
                .toList(),
            periodDurationMinutes: duration,
          );
    setState(() {});
    widget.onChanged(config);
  }

  Future<void> _pickDate() async {
    final selected = SemesterConfig.parseDay(_monday.text.trim());
    final now = DateTime.now();
    final thisMonday = DateTime(
      now.year,
      now.month,
      now.day - now.weekday + DateTime.monday,
    );
    final first = DateTime(1900);
    final last = DateTime(2200, 12, 31);
    final day = await showDatePicker(
      context: context,
      switchToInputEntryModeIcon: const Icon(AppIcons.edit),
      switchToCalendarEntryModeIcon: const Icon(AppIcons.calendar),
      initialDate:
          selected != null &&
              selected.weekday == DateTime.monday &&
              !selected.isBefore(first) &&
              !selected.isAfter(last)
          ? selected
          : thisMonday,
      firstDate: first,
      lastDate: last,
      helpText: '选择第一教学周的周一',
      selectableDayPredicate: (date) => date.weekday == DateTime.monday,
      currentDate: now,
    );
    if (day == null || !mounted) return;
    _monday.text = day.toIso8601String().split('T').first;
    _changed();
  }

  String _endOf(String time) {
    final start = SemesterConfig.parseMinute(time.trim());
    final duration = int.tryParse(_duration.text.trim());
    if (start == null ||
        duration == null ||
        duration < 20 ||
        duration > 120 ||
        start + duration >= 1440) {
      return '—';
    }
    return formatClock(start + duration);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final monday = SemesterConfig.parseDay(_monday.text.trim());
    final sunday = monday == null
        ? null
        : DateTime(monday.year, monday.month, monday.day + 6);
    final firstMonday = AppFieldLabel(
      label: '第一教学周的周一',
      child: TextField(
        key: const ValueKey('semester-monday'),
        controller: _monday,
        keyboardType: TextInputType.datetime,
        textInputAction: TextInputAction.next,
        style: text.bodyMedium,
        onChanged: (_) => _changed(),
        decoration: InputDecoration(
          hintText: 'YYYY-MM-DD',
          suffixIcon: IconButton(
            onPressed: _pickDate,
            tooltip: '选择日期',
            icon: const Icon(AppIcons.calendar),
          ),
          helperText: monday != null && monday.weekday == DateTime.monday
              ? '第 1 周：${monday.month}月${monday.day}日 – ${sunday!.month}月${sunday.day}日'
              : null,
        ),
      ),
    );
    final weekCount = _field(_weeks, '总教学周数', numeric: true);
    const sectionShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _field(
          _name,
          '学期名称',
          hint: '例如：秋季学期',
          key: const ValueKey('semester-name'),
        ),
        const SizedBox(height: AppSpace.lg),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 440 &&
                MediaQuery.textScalerOf(context).scale(14) < 20) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: firstMonday),
                  const SizedBox(width: AppSpace.md),
                  Expanded(flex: 2, child: weekCount),
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                firstMonday,
                const SizedBox(height: AppSpace.lg),
                weekCount,
              ],
            );
          },
        ),
        const SizedBox(height: AppSpace.lg),
        ExpansionTile(
          trailing: const AppExpansionIcon(),
          backgroundColor: colors.surface,
          collapsedBackgroundColor: colors.surfaceMuted,
          shape: sectionShape,
          collapsedShape: sectionShape,
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
          leading: Icon(AppIcons.clock, color: colors.accent),
          title: Text('节次时间', style: text.bodyMedium),
          subtitle: Text(
            '${_starts.length} 节 · 每节 ${_duration.text} 分钟',
            style: text.bodySmall,
          ),
          childrenPadding: const EdgeInsets.only(top: AppSpace.sm),
          children: [
            _field(_duration, '每节时长（分钟）', numeric: true),
            for (final (index, controller) in _starts.indexed)
              Padding(
                padding: const EdgeInsets.only(top: AppSpace.md),
                child: AppPeriodEditRow(
                  period: index + 1,
                  endTime: _endOf(controller.text),
                  startField: TextField(
                    key: ValueKey('semester-period-$index'),
                    controller: controller,
                    keyboardType: TextInputType.datetime,
                    textInputAction: TextInputAction.next,
                    style: text.bodyMedium,
                    onChanged: (_) => _changed(),
                    decoration: const InputDecoration(hintText: 'HH:mm'),
                  ),
                ),
              ),
            const SizedBox(height: AppSpace.sm),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppSpace.sm,
              children: [
                TextButton(
                  onPressed: _starts.length <= 1
                      ? null
                      : () {
                          final removed = _starts.removeLast();
                          _changed();
                          WidgetsBinding.instance.addPostFrameCallback(
                            (_) => removed.dispose(),
                          );
                        },
                  child: const Text('移除最后一节'),
                ),
                TextButton.icon(
                  onPressed: _starts.length == SemesterConfig.maxPeriods
                      ? null
                      : () {
                          _starts.add(TextEditingController());
                          _changed();
                        },
                  icon: const Icon(AppIcons.add),
                  label: const Text('添加节次'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    bool numeric = false,
    Key? key,
  }) => AppFieldLabel(
    label: label,
    child: TextField(
      key: key,
      controller: controller,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      textInputAction: TextInputAction.next,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(hintText: hint),
      onChanged: (_) => _changed(),
    ),
  );
}
