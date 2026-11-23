import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/utils/formatters.dart';
import 'package:qinghe_app/app/widgets/app_button.dart';
import 'package:qinghe_app/app/widgets/app_field_label.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/app/widgets/morph_dialog.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';

/// 课程详情对话框：点击课程后由卡片本身放大成对话框，可查看时间地点并就地编辑。
///
/// [origin] 是卡片在屏幕上的矩形；[originColor] 与 [originRadius] 让它一开始
/// 就与卡片完全重合，再从课程配色过渡到对话框底色。
Future<void> showLessonDialog(
  BuildContext context,
  LessonOccurrence lesson, {
  DateTime? date,
  Rect? origin,
  Color? originColor,
  double? originRadius,
}) {
  final appearance = Get.isRegistered<AppearanceController>()
      ? Get.find<AppearanceController>()
      : null;
  final tone = CoursePalette.of(
    context,
    lesson.colorIndex,
    appearance?.courseColorScheme.value ?? CourseColorScheme.qinghe,
    appearance?.scheduleCourseSaturation.value ?? 1,
  );

  final startColor = originColor ?? tone.background;

  return showMorphDialog(
    context: context,
    origin: origin,
    originColor: startColor,
    originRadius: originRadius ?? AppRadius.md,
    barrierLabel: '关闭课程详情',
    builder: (context, close) =>
        _LessonDialog(lesson: lesson, date: date, onClose: close),
  );
}

class _LessonDialog extends StatefulWidget {
  const _LessonDialog({required this.lesson, required this.onClose, this.date});

  final LessonOccurrence lesson;
  final VoidCallback onClose;
  final DateTime? date;

  @override
  State<_LessonDialog> createState() => _LessonDialogState();
}

class _LessonDialogState extends State<_LessonDialog> {
  late final _name = TextEditingController(text: widget.lesson.courseName);
  late final _location = TextEditingController(text: widget.lesson.location);
  late final _teacher = TextEditingController(text: widget.lesson.teacher);
  bool _editing = false;
  bool _saving = false;

  LessonOccurrence get _lesson => widget.lesson;

  String get _displayName {
    final value = _name.text.trim();
    return value.isEmpty ? _lesson.courseName : value;
  }

  String get _displayLocation {
    final value = _location.text.trim();
    return value.isEmpty ? _lesson.location : value;
  }

  String get _displayTeacher {
    final value = _teacher.text.trim();
    return value.isEmpty ? _lesson.teacher : value;
  }

  bool get _canEdit {
    if (_lesson.courseId.isEmpty || _lesson.ruleId.isEmpty) return false;
    if (!Get.isRegistered<LocalTimetableRepository>()) return false;
    return Get.find<LocalTimetableRepository>().active != null;
  }

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _teacher.dispose();
    super.dispose();
  }

  void _notify(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _notify('课程名称不能为空');
      return;
    }
    setState(() => _saving = true);
    try {
      await Get.find<LocalTimetableRepository>().updateLesson(
        courseId: _lesson.courseId,
        ruleId: _lesson.ruleId,
        name: name,
        location: _location.text.trim(),
        teacher: _teacher.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _editing = false;
      });
      _notify('课程信息已更新');
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      _notify(error is FormatException ? error.message : '保存失败，请重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final appearance = Get.isRegistered<AppearanceController>()
        ? Get.find<AppearanceController>()
        : null;
    final tone = CoursePalette.of(
      context,
      _lesson.colorIndex,
      appearance?.courseColorScheme.value ?? CourseColorScheme.qinghe,
      appearance?.scheduleCourseSaturation.value ?? 1,
    );

    return Semantics(
      container: true,
      label: '课程详情',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Material(
          type: MaterialType.transparency,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: AppMotion.of(context, AppMotion.medium),
                    curve: AppMotion.emphasized,
                    width: 4,
                    height: 26,
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: tone.foreground,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSwitcher(
                          duration: AppMotion.of(context, AppMotion.fast),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: animation.drive(
                                    Tween(
                                      begin: const Offset(0, 0.2),
                                      end: Offset.zero,
                                    ),
                                  ),
                                  child: child,
                                ),
                              ),
                          child: Text(
                            _editing ? '编辑课程' : _displayName,
                            key: ValueKey('${_editing}_$_displayName'),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.headlineSmall,
                          ),
                        ),
                        if (widget.date case final date?)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${date.month}月${date.day}日 · '
                              '${weekdayLabel(date.weekday)}',
                              style: text.bodySmall,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    tooltip: '关闭',
                    icon: const Icon(AppIcons.close),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              AnimatedSwitcher(
                duration: AppMotion.of(
                  context,
                  const Duration(milliseconds: 260),
                ),
                switchInCurve: AppMotion.emphasized,
                switchOutCurve: AppMotion.emphasized,
                // 两段内容尺寸不同，按顶部对齐，避免交叉淡入时上下跳动。
                layoutBuilder: (current, previous) => Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    for (final child in previous) child,
                    if (current != null) current,
                  ],
                ),
                transitionBuilder: (child, animation) {
                  final curved = CurvedAnimation(
                    parent: animation,
                    curve: AppMotion.emphasized,
                    reverseCurve: AppMotion.emphasized,
                  );
                  final entering = animation.status != AnimationStatus.reverse;
                  return FadeTransition(
                    opacity: curved,
                    child: ScaleTransition(
                      alignment: Alignment.topCenter,
                      // 新内容从略小放大进来，旧内容略微缩小退出。
                      scale: Tween<double>(
                        begin: entering ? 0.94 : 1.0,
                        end: entering ? 1.0 : 0.96,
                      ).animate(curved),
                      child: child,
                    ),
                  );
                },
                child: _editing
                    ? _editContent(context)
                    : _detailContent(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailContent(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      key: const ValueKey('lesson-detail'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppPanel(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpace.lg,
            vertical: AppSpace.sm,
          ),
          child: Column(
            children: [
              _DetailRow(
                icon: AppIcons.clock,
                label: '时间',
                value:
                    '${formatClock(_lesson.startMinute)} – '
                    '${formatClock(_lesson.endMinute)}',
              ),
              _DetailRow(
                icon: AppIcons.rows,
                label: '节次',
                value: formatPeriods(_lesson.startPeriod, _lesson.endPeriod),
              ),
              if (_displayLocation.isNotEmpty)
                _DetailRow(
                  icon: AppIcons.location,
                  label: '地点',
                  value: _displayLocation,
                ),
              if (_displayTeacher.isNotEmpty)
                _DetailRow(
                  icon: AppIcons.user,
                  label: '教师',
                  value: _displayTeacher,
                ),
            ],
          ),
        ),
        if (_canEdit) ...[
          const SizedBox(height: AppSpace.xl),
          AppButton(
            key: const ValueKey('lesson-sheet-edit'),
            icon: AppIcons.edit,
            label: '编辑课程',
            expand: true,
            onPressed: () => setState(() => _editing = true),
          ),
        ] else ...[
          const SizedBox(height: AppSpace.xl),
          Text(
            '在课表中导入或新建课程后可编辑信息。',
            textAlign: TextAlign.center,
            style: text.bodySmall,
          ),
        ],
        const SizedBox(height: AppSpace.sm),
        AppButton(
          label: '关闭',
          tone: AppButtonTone.secondary,
          expand: true,
          onPressed: widget.onClose,
        ),
      ],
    );
  }

  Widget _editContent(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      key: const ValueKey('lesson-edit'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFieldLabel(
          label: '课程名称',
          child: TextField(
            key: const ValueKey('lesson-name-field'),
            controller: _name,
            maxLength: 40,
            textInputAction: TextInputAction.next,
            style: text.bodyMedium,
            decoration: const InputDecoration(counterText: ''),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        AppFieldLabel(
          label: '地点',
          child: TextField(
            key: const ValueKey('lesson-location-field'),
            controller: _location,
            maxLength: 40,
            textInputAction: TextInputAction.next,
            style: text.bodyMedium,
            decoration: const InputDecoration(
              hintText: '例如 A101',
              counterText: '',
            ),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        AppFieldLabel(
          label: '教师',
          child: TextField(
            key: const ValueKey('lesson-teacher-field'),
            controller: _teacher,
            maxLength: 40,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _saving ? null : _save(),
            style: text.bodyMedium,
            decoration: const InputDecoration(
              hintText: '例如 张老师',
              counterText: '',
            ),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Row(
          children: [
            Icon(AppIcons.info, size: 14, color: context.colors.inkFaint),
            const SizedBox(width: 6),
            Expanded(
              child: Text('名称会同步到这门课的其他安排；地点和教师只改当前一次。', style: text.bodySmall),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.xl),
        Row(
          children: [
            Expanded(
              child: AppButton(
                label: '取消',
                tone: AppButtonTone.secondary,
                expand: true,
                onPressed: _saving
                    ? null
                    : () => setState(() => _editing = false),
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: AppButton(
                key: const ValueKey('lesson-sheet-save'),
                label: _saving ? '保存中' : '保存',
                expand: true,
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.inkFaint),
          const SizedBox(width: AppSpace.md),
          SizedBox(width: 44, child: Text(label, style: text.labelMedium)),
          Expanded(child: Text(value, style: text.bodyMedium)),
        ],
      ),
    );
  }
}
