import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/app_button.dart';
import 'package:qinghe_app/app/widgets/app_field_label.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/data/models/timetable_rule.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:qinghe_app/services/notifications/course_notifications.dart';
import 'package:qinghe_app/features/timetable_setup/widgets/setup_page.dart';

/// 打开课程编辑页时传入的参数：新增时是点的那一格，编辑时带上原安排。
class AddLessonArgs {
  const AddLessonArgs({required this.weekday, required this.period, this.rule});

  final int weekday;
  final int period;

  /// 编辑已有安排时传入；为空表示新增。
  final TimetableRule? rule;
}

const _weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

/// 课程编辑页：新增与编辑共用。新增时星期与节次由点击的那一格预填，
/// 编辑时用原安排回填全部字段。
class AddLessonPage extends StatefulWidget {
  const AddLessonPage({
    required this.weekday,
    required this.period,
    this.rule,
    super.key,
  });

  final int weekday;
  final int period;
  final TimetableRule? rule;

  @override
  State<AddLessonPage> createState() => _AddLessonPageState();
}

class _AddLessonPageState extends State<AddLessonPage> {
  final _repository = Get.find<LocalTimetableRepository>();
  late final _name = TextEditingController(text: widget.rule?.name ?? '');
  late final _location = TextEditingController(
    text: widget.rule?.location ?? '',
  );
  late final _teacher = TextEditingController(text: widget.rule?.teacher ?? '');
  late int _weekday = widget.rule?.weekday ?? widget.weekday;
  late int _start = widget.rule?.startPeriod ?? widget.period;
  late int _end = widget.rule?.endPeriod ?? widget.period;
  late int _firstWeek = widget.rule?.weeks.first ?? 1;
  late int _lastWeek =
      widget.rule?.weeks.last ?? (_repository.active?.config.weekCount ?? 18);

  bool get _editing => widget.rule != null;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final field in [_name, _location, _teacher]) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final weeks = [
        for (var week = _firstWeek; week <= _lastWeek; week++) week,
      ];
      final rule = widget.rule;
      if (rule != null) {
        await _repository.updateRule(
          ruleId: rule.id,
          name: _name.text,
          weekday: _weekday,
          startPeriod: _start,
          endPeriod: _end < _start ? _start : _end,
          weeks: weeks,
          location: _location.text,
          teacher: _teacher.text,
        );
      } else {
        await _repository.addLesson(
          name: _name.text,
          weekday: _weekday,
          startPeriod: _start,
          endPeriod: _end < _start ? _start : _end,
          weeks: weeks,
          location: _location.text,
          teacher: _teacher.text,
        );
      }
      if (!mounted) return;
      // 课表变了，重排上课提醒。
      if (Get.isRegistered<CourseNotifications>()) {
        await Get.find<CourseNotifications>().sync();
      }
      if (!mounted) return;
      showAppToast(context, _editing ? '已更新课程' : '已添加到课表');
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (mounted) Get.back<Object?>(result: true);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Exception {
      if (mounted) setState(() => _error = '保存失败，请重试。');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// 编辑已有安排时可以删除整门课程。
  bool get _canDelete => widget.rule != null;

  Future<void> _delete() async {
    final rule = widget.rule;
    if (rule == null) return;
    final count =
        _repository.active?.rules
            .where((item) => item.courseId == rule.courseId)
            .length ??
        0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除这门课程？'),
        content: Text('「${rule.name}」在课表里的 $count 条安排会一起删除，删除后不能恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            key: const ValueKey('edit-lesson-delete-confirm'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _repository.removeCourse(courseId: rule.courseId);
      if (Get.isRegistered<CourseNotifications>()) {
        await Get.find<CourseNotifications>().sync();
      }
      if (!mounted) return;
      showAppToast(context, '已删除课程');
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (mounted) Get.back<Object?>(result: true);
    } on FormatException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } on Exception {
      if (mounted) setState(() => _error = '删除失败，请重试。');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final config = _repository.active?.config;
    final periodCount = config?.periodStartTimes.length ?? 12;
    final weekCount = config?.weekCount ?? 18;

    return SetupPage(
      title: _editing ? '编辑课程' : '添加课程',
      description: _editing
          ? '修改课程名称、星期、节次或周次；名称会同步到这门课的全部安排。'
          : '从空白格新增课程，之后可以在课程详情里继续修改。',
      footer: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppButton(
            label: _saving ? '保存中…' : (_editing ? '保存修改' : '保存到课表'),
            expand: true,
            onPressed: _saving ? null : _save,
          ),
          if (_canDelete) ...[
            const SizedBox(height: AppSpace.sm),
            AppButton(
              key: const ValueKey('edit-lesson-delete'),
              icon: AppIcons.delete,
              label: '删除课程',
              tone: AppButtonTone.secondary,
              expand: true,
              onPressed: _saving ? null : _delete,
            ),
          ],
        ],
      ),
      children: [
        AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppFieldLabel(
                label: '课程名称',
                child: TextField(
                  key: const ValueKey('add-lesson-name'),
                  controller: _name,
                  autofocus: true,
                  maxLength: 40,
                  textInputAction: TextInputAction.next,
                  onChanged: (_) => setState(() => _error = null),
                  style: text.bodyMedium,
                  decoration: const InputDecoration(
                    hintText: '填写课程名称',
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Row(
                children: [
                  Expanded(
                    child: AppFieldLabel(
                      label: '星期',
                      child: DropdownButtonFormField<int>(
                        key: const ValueKey('add-lesson-weekday'),
                        isExpanded: true,
                        style: text.bodyMedium,
                        icon: const Icon(AppIcons.chevronDown),
                        initialValue: _weekday,
                        items: [
                          for (var day = 1; day <= 7; day++)
                            DropdownMenuItem(
                              value: day,
                              child: Text('周${_weekdayLabels[day - 1]}'),
                            ),
                        ],
                        onChanged: _saving
                            ? null
                            : (value) =>
                                  setState(() => _weekday = value ?? _weekday),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: AppFieldLabel(
                      label: '开始节次',
                      child: DropdownButtonFormField<int>(
                        key: const ValueKey('add-lesson-start'),
                        isExpanded: true,
                        style: text.bodyMedium,
                        icon: const Icon(AppIcons.chevronDown),
                        initialValue: _start,
                        items: [
                          for (var period = 1; period <= periodCount; period++)
                            DropdownMenuItem(
                              value: period,
                              child: Text('第 $period 节'),
                            ),
                        ],
                        onChanged: _saving
                            ? null
                            : (value) => setState(() {
                                _start = value ?? _start;
                                if (_end < _start) _end = _start;
                              }),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: AppFieldLabel(
                      label: '结束节次',
                      child: DropdownButtonFormField<int>(
                        key: const ValueKey('add-lesson-end'),
                        isExpanded: true,
                        style: text.bodyMedium,
                        icon: const Icon(AppIcons.chevronDown),
                        initialValue: _end,
                        items: [
                          for (
                            var period = _start;
                            period <= periodCount;
                            period++
                          )
                            DropdownMenuItem(
                              value: period,
                              child: Text('第 $period 节'),
                            ),
                        ],
                        onChanged: _saving
                            ? null
                            : (value) => setState(() => _end = value ?? _end),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              Row(
                children: [
                  Expanded(
                    child: AppFieldLabel(
                      label: '起始周',
                      child: DropdownButtonFormField<int>(
                        key: const ValueKey('add-lesson-first-week'),
                        isExpanded: true,
                        style: text.bodyMedium,
                        icon: const Icon(AppIcons.chevronDown),
                        initialValue: _firstWeek,
                        items: [
                          for (var week = 1; week <= weekCount; week++)
                            DropdownMenuItem(
                              value: week,
                              child: Text('第 $week 周'),
                            ),
                        ],
                        onChanged: _saving
                            ? null
                            : (value) => setState(() {
                                _firstWeek = value ?? _firstWeek;
                                if (_lastWeek < _firstWeek) {
                                  _lastWeek = _firstWeek;
                                }
                              }),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: AppFieldLabel(
                      label: '结束周',
                      child: DropdownButtonFormField<int>(
                        key: const ValueKey('add-lesson-last-week'),
                        isExpanded: true,
                        style: text.bodyMedium,
                        icon: const Icon(AppIcons.chevronDown),
                        initialValue: _lastWeek,
                        items: [
                          for (var week = _firstWeek; week <= weekCount; week++)
                            DropdownMenuItem(
                              value: week,
                              child: Text('第 $week 周'),
                            ),
                        ],
                        onChanged: _saving
                            ? null
                            : (value) => setState(
                                () => _lastWeek = value ?? _lastWeek,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              AppFieldLabel(
                label: '地点（选填）',
                child: TextField(
                  key: const ValueKey('add-lesson-location'),
                  controller: _location,
                  maxLength: 40,
                  style: text.bodyMedium,
                  decoration: const InputDecoration(
                    hintText: '填写上课地点',
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              AppFieldLabel(
                label: '教师（选填）',
                child: TextField(
                  key: const ValueKey('add-lesson-teacher'),
                  controller: _teacher,
                  maxLength: 40,
                  style: text.bodyMedium,
                  decoration: const InputDecoration(
                    hintText: '填写教师姓名',
                    counterText: '',
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_error case final message?) ...[
          const SizedBox(height: AppSpace.md),
          AppPanel(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  AppIcons.error,
                  color: Theme.of(context).colorScheme.error,
                  size: 18,
                ),
                const SizedBox(width: AppSpace.sm),
                Expanded(child: Text(message, style: text.bodyMedium)),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
