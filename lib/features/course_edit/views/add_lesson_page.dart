import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/app_button.dart';
import 'package:qinghe_app/app/widgets/app_field_label.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:qinghe_app/features/timetable_setup/widgets/setup_page.dart';

/// 打开添加课程页时传入的参数：从课表里点的那一格。
class AddLessonArgs {
  const AddLessonArgs({required this.weekday, required this.period});

  final int weekday;
  final int period;
}

const _weekdayLabels = ['一', '二', '三', '四', '五', '六', '日'];

/// 添加课程：填课程名、地点、教师，星期与节次由点击的那一格预填。
class AddLessonPage extends StatefulWidget {
  const AddLessonPage({required this.weekday, required this.period, super.key});

  final int weekday;
  final int period;

  @override
  State<AddLessonPage> createState() => _AddLessonPageState();
}

class _AddLessonPageState extends State<AddLessonPage> {
  final _repository = Get.find<LocalTimetableRepository>();
  final _name = TextEditingController();
  final _location = TextEditingController();
  final _teacher = TextEditingController();
  late int _weekday = widget.weekday;
  late int _start = widget.period;
  late int _end = widget.period;
  late int _firstWeek = 1;
  late int _lastWeek = _repository.active?.config.weekCount ?? 18;
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
      await _repository.addLesson(
        name: _name.text,
        weekday: _weekday,
        startPeriod: _start,
        endPeriod: _end < _start ? _start : _end,
        weeks: [for (var week = _firstWeek; week <= _lastWeek; week++) week],
        location: _location.text,
        teacher: _teacher.text,
      );
      if (!mounted) return;
      showAppToast(context, '已添加到课表');
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

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final config = _repository.active?.config;
    final periodCount = config?.periodStartTimes.length ?? 12;
    final weekCount = config?.weekCount ?? 18;

    return SetupPage(
      title: '添加课程',
      description: '从空白格新增课程，之后可以在课程详情里继续修改。',
      footer: AppButton(
        label: _saving ? '保存中…' : '保存到课表',
        expand: true,
        onPressed: _saving ? null : _save,
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
