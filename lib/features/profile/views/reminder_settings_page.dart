import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/reminder_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/app_field_label.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:qinghe_app/services/notifications/course_notifications.dart';

/// 课程提醒：上课提醒与考试提醒，各自开关 + 自定义提前时间。
class ReminderSettingsPage extends StatelessWidget {
  const ReminderSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<ReminderController>();
    final repository = Get.find<LocalTimetableRepository>();

    return Scaffold(
      backgroundColor: context.colors.canvas,
      appBar: AppBar(title: const Text('课程提醒'), centerTitle: true),
      body: SafeArea(
        top: false,
        child: Obx(() {
          final timetable = repository.active;
          final exams =
              timetable?.exams.where((exam) => exam.hasTime) ?? const [];
          final upcoming = exams.isEmpty
              ? null
              : exams.reduce((a, b) => a.date.isBefore(b.date) ? a : b);

          return ListView(
            key: const ValueKey('reminder-settings-scroll'),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              _ReminderCard(
                key: const ValueKey('reminder-class-card'),
                title: '上课提醒',
                hint: '每节课开始前提醒你，内容含课程名、时间与地点。',
                enabled: settings.classEnabled,
                minutes: settings.classLeadMinutes.value,
                onToggle: (value) =>
                    _apply(context, () => settings.setClassEnabled(value)),
                onMinutes: (minutes) => _apply(
                  context,
                  () => settings.setClassLeadMinutes(minutes),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              _ReminderCard(
                key: const ValueKey('reminder-exam-card'),
                title: '考试提醒',
                hint: upcoming == null
                    ? '还没有读到考试安排，导入考试信息后生效。'
                    : '最近一场：${upcoming.courseName} · '
                          '${upcoming.date.month}月${upcoming.date.day}日 '
                          '${upcoming.timeLabel}',
                enabled: settings.examEnabled,
                minutes: settings.examLeadMinutes.value,
                onToggle: (value) =>
                    _apply(context, () => settings.setExamEnabled(value)),
                onMinutes: (minutes) =>
                    _apply(context, () => settings.setExamLeadMinutes(minutes)),
              ),
              const SizedBox(height: AppSpace.md),
              AppListGroup(
                children: [
                  AppListRow(
                    key: const ValueKey('reminder-preview-live'),
                    icon: AppIcons.lightning,
                    title: '预览上课中通知',
                    subtitle: '发一条示例实时通知，20 秒后自动收回',
                    onTap: () async {
                      if (!Get.isRegistered<CourseNotifications>()) return;
                      await Get.find<CourseNotifications>().previewLive();
                      if (context.mounted) {
                        showAppToast(context, '已发送，可下拉通知栏查看');
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '修改后会自动重排通知；提醒时间最长为 2 天。',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: context.colors.inkMuted,
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Future<void> _apply(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    await action();
    if (Get.isRegistered<CourseNotifications>()) {
      await Get.find<CourseNotifications>().sync();
    }
  }
}

/// 一条提醒设置：标题 + 开关 + 提前时间（自己填数字，选分钟或小时）。
class _ReminderCard extends StatefulWidget {
  const _ReminderCard({
    required this.title,
    required this.hint,
    required this.enabled,
    required this.minutes,
    required this.onToggle,
    required this.onMinutes,
    super.key,
  });

  final String title;
  final String hint;
  final bool enabled;
  final int minutes;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onMinutes;

  @override
  State<_ReminderCard> createState() => _ReminderCardState();
}

class _ReminderCardState extends State<_ReminderCard> {
  late final TextEditingController _field = TextEditingController(
    text: _displayValue(widget.minutes),
  );
  late bool _hours = _useHours(widget.minutes);

  @override
  void didUpdateWidget(_ReminderCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.minutes != widget.minutes &&
        _unitMinutes(_field.text) != widget.minutes) {
      _hours = _useHours(widget.minutes);
      _field.text = _displayValue(widget.minutes);
    }
  }

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  int get _unitFactor => _hours ? 60 : 1;

  int _unitMinutes(String raw) {
    final value = int.tryParse(raw.trim());
    if (value == null || value <= 0) return 0;
    return value * _unitFactor;
  }

  bool _useHours(int minutes) => minutes >= 60 && minutes % 60 == 0;

  String _displayValue(int minutes) {
    if (minutes <= 0) return '$_defaultValue';
    return _useHours(minutes) ? '${minutes ~/ 60}' : '$minutes';
  }

  int get _defaultValue => _hours ? 1 : 15;

  void _commit() {
    final minutes = _unitMinutes(_field.text);
    if (minutes == 0) {
      // 填了非法值就退回原值。
      _field.text = _displayValue(widget.minutes);
      return;
    }
    widget.onMinutes(minutes);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final enabled = widget.enabled;

    return AnimatedOpacity(
      duration: AppMotion.of(context, AppMotion.fast),
      opacity: enabled ? 1 : 0.62,
      child: AppPanel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: text.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        widget.hint,
                        style: text.bodySmall?.copyWith(color: colors.inkMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                Switch(
                  key: ValueKey('${widget.title}-switch'),
                  value: enabled,
                  onChanged: widget.onToggle,
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                SizedBox(
                  width: 92,
                  child: AppFieldLabel(
                    label: '提前',
                    child: TextField(
                      key: ValueKey('${widget.title}-minutes'),
                      controller: _field,
                      enabled: enabled,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      style: text.titleMedium,
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: '15',
                      ),
                      onSubmitted: (_) => _commit(),
                      onEditingComplete: _commit,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpace.sm),
                _UnitChip(
                  label: '分钟',
                  selected: !_hours,
                  enabled: enabled,
                  onTap: () {
                    if (_hours) {
                      setState(() => _hours = false);
                      _field.text = _displayValue(widget.minutes);
                    }
                  },
                ),
                const SizedBox(width: AppSpace.xs),
                _UnitChip(
                  label: '小时',
                  selected: _hours,
                  enabled: enabled,
                  onTap: () {
                    if (!_hours) {
                      setState(() => _hours = true);
                      _field.text = _displayValue(widget.minutes);
                    }
                  },
                ),
                const Spacer(),
                if (enabled)
                  TextButton(
                    key: ValueKey('${widget.title}-save'),
                    onPressed: _commit,
                    child: const Text('保存'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UnitChip extends StatelessWidget {
  const _UnitChip({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Pressable(
      onTap: enabled && !selected ? onTap : null,
      color: selected ? colors.accentSoft : colors.surfaceMuted,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      semanticLabel: label,
      selected: selected,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          label,
          style: text.labelMedium?.copyWith(
            color: selected ? colors.accent : colors.inkMuted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
