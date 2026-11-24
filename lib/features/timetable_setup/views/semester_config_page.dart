import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/app_session.dart';
import 'package:qinghe_app/app/routes/app_routes.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/app_button.dart';
import 'package:qinghe_app/app/widgets/app_field_label.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/data/import/timetable_import.dart';
import 'package:qinghe_app/data/import/timetable_import_preview.dart';
import 'package:qinghe_app/data/models/semester_config.dart';
import 'package:qinghe_app/data/models/timetable.dart';
import 'package:qinghe_app/data/models/timetable_exam.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:qinghe_app/features/timetable_setup/widgets/import_preview_panel.dart';
import 'package:qinghe_app/features/timetable_setup/widgets/semester_fields.dart';
import 'package:qinghe_app/features/timetable_setup/widgets/setup_page.dart';

/// 打开学期与节次配置页时传入的参数。
class SemesterConfigArgs {
  const SemesterConfigArgs({
    this.draft,
    this.label,
    this.firstRun = false,
    this.exams = const [],
    this.examIssue = '',
  });

  final TimetableImport? draft;
  final String? label;

  /// 首次设置流程中，保存后直接进入主界面。
  final bool firstRun;

  /// 与课表同批读到的考试安排。
  final List<TimetableExam> exams;

  /// 考试读取失败的原因；为空表示读取成功或该校不提供考试接口。
  final String examIssue;
}

/// 学期与节次配置：填写教学周与上课时间，预览差异后写入本地课表。
///
/// [draft] 为空时只保存学期配置，不导入课程。
class SemesterConfigPage extends StatefulWidget {
  const SemesterConfigPage({
    this.firstRun = false,
    this.draft,
    this.sourceLabel,
    this.exams = const [],
    this.examIssue = '',
    super.key,
  });

  final bool firstRun;
  final TimetableImport? draft;

  /// 数据来源名称，例如「教务系统」，用于提示将要导入的内容。
  final String? sourceLabel;

  /// 与课表同批读到的考试安排。
  final List<TimetableExam> exams;

  /// 考试读取失败的原因。
  final String examIssue;

  @override
  State<SemesterConfigPage> createState() => _SemesterConfigPageState();
}

class _SemesterConfigPageState extends State<SemesterConfigPage> {
  static const _newSemester = '';
  final _repository = Get.find<LocalTimetableRepository>();
  final _previewKey = GlobalKey();
  final _errorKey = GlobalKey();
  late Timetable? _target = _repository.active;
  late SemesterConfig? _config = _target?.config ?? widget.draft?.config;
  late SemesterConfig? _initialConfig = _config;
  TimetableImportPreview? _preview;
  String? _error;
  bool _acceptOverlap = false;
  bool _busy = false;
  int _formVersion = 0;

  void _changeConfig(SemesterConfig? config) {
    setState(() {
      _config = config;
      _preview = null;
      _error = null;
      _acceptOverlap = false;
    });
  }

  void _resetFields(SemesterConfig? config) {
    _initialConfig = config;
    _config = config;
    _formVersion++;
    _preview = null;
    _error = null;
    _acceptOverlap = false;
  }

  void _scrollTo(GlobalKey key) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = key.currentContext;
      if (target != null) Scrollable.ensureVisible(target, alignment: 0.05);
    });
  }

  void _showFormIssue(String message) {
    setState(() => _error = message);
    _scrollTo(_errorKey);
  }

  TimetableImportPreview _buildPreview() {
    final config = _config;
    if (config == null) {
      throw const FormatException('请填写有效的第一教学周日期、总周数和每节时长。');
    }
    return TimetableImportPreview(
      base: _target,
      config: config,
      incoming: widget.draft?.rules ?? const [],
    );
  }

  void _generatePreview() {
    FocusScope.of(context).unfocus();
    try {
      final preview = _buildPreview();
      setState(() {
        _preview = preview;
        _error = null;
        _acceptOverlap = false;
      });
      _scrollTo(_previewKey);
    } on FormatException catch (error) {
      _showFormIssue(error.message);
    }
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    setState(() => _busy = true);
    try {
      await _repository.save(
        _preview ?? _buildPreview(),
        exams: widget.exams.isEmpty ? null : widget.exams,
      );
      if (mounted) await _finish();
    } on FormatException catch (error) {
      if (mounted) _showFormIssue(error.message);
    } on Exception {
      if (mounted) _showFormIssue('保存失败，请重试。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish() async {
    if (widget.firstRun) {
      await Get.find<AppSession>().completeOnboarding();
      if (mounted) Get.offAllNamed<void>(AppRoutes.shell);
      return;
    }
    Get.back<Object?>(result: true);
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final draft = widget.draft;
    final fileConfig = draft?.config;
    final text = Theme.of(context).textTheme;

    return SetupPage(
      title: '学期与节次',
      description: draft == null
          ? '设置教学周与上课时间，保存后即可在课表中查看课程。'
          : '核对学期与节次后确认导入，个人配色与备注会保留。',
      step: widget.firstRun ? 2 : null,
      stepCount: 3,
      footer: AppButton(
        label: _busy
            ? '处理中…'
            : preview != null
            ? '确认导入'
            : draft == null
            ? '保存学期配置'
            : '检查并预览',
        expand: true,
        onPressed:
            _busy ||
                _repository.readFailed ||
                (preview != null &&
                    preview.conflictCount > 0 &&
                    !_acceptOverlap)
            ? null
            : draft != null && preview == null
            ? _generatePreview
            : _save,
      ),
      children: [
        if (_repository.readFailed) ...[
          const _ConfigNotice('已保存的课表读取失败，原有数据已保留。'),
          const SizedBox(height: AppSpace.md),
        ],
        if (draft != null)
          AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('待导入数据', style: text.labelMedium),
                const SizedBox(height: AppSpace.xs),
                Text(
                  '${widget.sourceLabel ?? '文件'} · ${draft.rules.length} 条安排',
                  style: text.titleMedium,
                ),
                if (widget.exams.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    '考试 ${widget.exams.length} 场，会一起写入课表',
                    style: text.bodySmall,
                  ),
                ] else if (widget.examIssue.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    '考试信息未获取：${widget.examIssue}',
                    style: text.bodySmall?.copyWith(
                      color: context.colors.inkMuted,
                    ),
                  ),
                ],
              ],
            ),
          ),
        if (draft != null) const SizedBox(height: AppSpace.lg),
        AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('学期与节次', style: text.titleMedium),
              const SizedBox(height: AppSpace.md),
              if (_error case final message?) ...[
                _ConfigNotice(message, key: _errorKey),
                const SizedBox(height: AppSpace.md),
              ],
              if (_repository.timetables.isNotEmpty) ...[
                AppFieldLabel(
                  label: '目标学期',
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    style: text.bodyMedium,
                    icon: const Icon(AppIcons.chevronDown),
                    initialValue: _target?.id ?? _newSemester,
                    items: [
                      for (final timetable in _repository.timetables)
                        DropdownMenuItem(
                          value: timetable.id,
                          child: Text(
                            '${timetable.config.name} · ${timetable.config.firstDay}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      const DropdownMenuItem(
                        value: _newSemester,
                        child: Text('新建学期'),
                      ),
                    ],
                    onChanged: _busy
                        ? null
                        : (id) => setState(() {
                            _target = _repository.find(id);
                            _resetFields(
                              _target?.config ?? fileConfig ?? _config,
                            );
                          }),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
              ],
              if (fileConfig != null &&
                  jsonEncode(fileConfig.toJson()) !=
                      jsonEncode(_config?.toJson()))
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _busy
                        ? null
                        : () => setState(() => _resetFields(fileConfig)),
                    icon: const Icon(AppIcons.calendarCheck),
                    label: const Text('应用数据中的学期配置'),
                  ),
                ),
              AbsorbPointer(
                absorbing: _busy,
                child: SemesterFields(
                  key: ValueKey(_formVersion),
                  initial: _initialConfig,
                  onChanged: _changeConfig,
                ),
              ),
            ],
          ),
        ),
        if (preview != null) ...[
          const SizedBox(height: AppSpace.lg),
          ImportPreviewPanel(
            key: _previewKey,
            preview: preview,
            acceptOverlap: _acceptOverlap,
            onAcceptOverlap: _busy
                ? null
                : (value) => setState(() => _acceptOverlap = value ?? false),
          ),
        ],
      ],
    );
  }
}

class _ConfigNotice extends StatelessWidget {
  const _ConfigNotice(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint =
        theme.inputDecorationTheme.errorStyle?.color ?? theme.colorScheme.error;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            tint.withValues(alpha: 0.08),
            context.colors.surface,
          ),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(AppIcons.error, color: tint, size: 18),
            const SizedBox(width: AppSpace.sm),
            Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
          ],
        ),
      ),
    );
  }
}
