import 'dart:convert';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/app_session.dart';
import 'package:qinghe_app/app/routes/app_routes.dart';
import 'package:qinghe_app/app/student_profile_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/app_button.dart';
import 'package:qinghe_app/app/widgets/app_field_label.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/data/import/timetable_import.dart';
import 'package:qinghe_app/data/import/timetable_import_preview.dart';
import 'package:qinghe_app/data/models/semester_config.dart';
import 'package:qinghe_app/data/models/timetable.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:qinghe_app/data/sources/school_registry.dart';
import 'package:qinghe_app/features/timetable_setup/widgets/import_preview_panel.dart';
import 'package:qinghe_app/features/timetable_setup/widgets/import_source_panel.dart';
import 'package:qinghe_app/features/timetable_setup/widgets/semester_fields.dart';
import 'package:qinghe_app/features/timetable_setup/widgets/setup_page.dart';

class TimetableImportPage extends StatefulWidget {
  const TimetableImportPage({this.firstRun = false, this.pickFile, super.key});

  final bool firstRun;
  final Future<XFile?> Function(List<XTypeGroup>)? pickFile;

  @override
  State<TimetableImportPage> createState() => _TimetableImportPageState();
}

class _TimetableImportPageState extends State<TimetableImportPage> {
  static const _newSemester = '';
  final _repository = Get.find<LocalTimetableRepository>();
  final _profile = Get.find<StudentProfileController>();
  final _previewKey = GlobalKey();
  final _errorKey = GlobalKey();
  late Timetable? _target = _repository.active;
  late SemesterConfig? _config = _target?.config;
  late SemesterConfig? _initialConfig = _config;
  TimetableImport? _draft;
  TimetableFileType? _fileType;
  String? _sourceLabel;
  TimetableImportPreview? _preview;
  String? _fileIssue;
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

  Future<void> _choose(TimetableFileType type) async {
    setState(() => _busy = true);
    try {
      final extensions = [type.name];
      final types = [
        XTypeGroup(
          label: '${type.name.toUpperCase()} 文件',
          extensions: extensions,
          mimeTypes: type == TimetableFileType.csv
              ? const ['text/csv', 'text/plain', 'application/vnd.ms-excel']
              : const ['application/json', 'text/plain'],
        ),
      ];
      final file =
          await (widget.pickFile?.call(types) ??
              openFile(acceptedTypeGroups: types));
      if (!mounted || file == null) return;
      if (await file.length() > TimetableImport.maxBytes) {
        throw const FormatException('文件超过 1 MB，请拆分后导入。');
      }
      final bytes = await file.readAsBytes();
      if (bytes.length > TimetableImport.maxBytes) {
        throw const FormatException('文件超过 1 MB，请拆分后导入。');
      }
      final String content;
      try {
        content = utf8.decode(bytes);
      } on FormatException {
        throw const FormatException('文件不是有效的 UTF-8 文本，请转换编码后重试。');
      }
      final draft = TimetableImport.parse(content, type);
      if (!mounted) return;
      setState(() {
        _draft = draft;
        _fileType = type;
        _sourceLabel = null;
        _preview = null;
        _fileIssue = null;
        _error = null;
        _acceptOverlap = false;
        if (_target == null && _config == null && draft.config != null) {
          _resetFields(draft.config);
        }
      });
    } on FormatException catch (error) {
      if (mounted) _fileError(error.message);
    } on Exception {
      if (mounted) _fileError('无法打开文件，请检查文件是否可读后重试。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _fileError(String message) => setState(() {
    _draft = null;
    _fileType = null;
    _sourceLabel = null;
    _preview = null;
    _fileIssue = message;
    _error = null;
  });

  void _clearFile() => setState(() {
    _draft = null;
    _fileType = null;
    _sourceLabel = null;
    _preview = null;
    _fileIssue = null;
    _error = null;
    _acceptOverlap = false;
  });

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

  Future<void> _copyTemplate() async {
    await Clipboard.setData(ClipboardData(text: TimetableImport.csvTemplate));
    if (mounted) showAppToast(context, 'CSV 表头与示例已复制。');
  }

  void _openSchool(String school) async {
    if (school.isEmpty && !widget.firstRun) {
      Get.toNamed<void>(AppRoutes.studentProfile);
      return;
    }
    final source = SchoolRegistry.forSchool(school);
    if (source == null || !source.isAvailable) {
      showAppToast(
        context,
        school.isEmpty ? '请返回上一步选择学校。' : '该学校尚未开放教务导入，请使用 CSV 或 JSON。',
      );
      return;
    }
    // 路由按 void 注册，这里取通用返回值再自行校验，避免与路由泛型耦合。
    final result = await Get.toNamed<Object?>(
      AppRoutes.jwxtImport,
      arguments: source,
    );
    if (!mounted || result is! TimetableImport) return;
    setState(() {
      _draft = result;
      _fileType = null;
      _sourceLabel = '教务系统';
      _preview = null;
      _fileIssue = null;
      _error = null;
      _acceptOverlap = false;
    });
  }

  String _schoolSubtitle(String school) {
    if (school.isEmpty) return '请先选择学校';
    final source = SchoolRegistry.forSchool(school);
    if (source == null) return '$school · 暂未适配';
    if (!source.isVerified) return '$school · 正在验证';
    if (!source.runsOnThisPlatform) return '$school · 当前平台暂未开放';
    return '$school · 读取学校课表';
  }

  TimetableImportPreview _buildPreview() {
    final config = _config;
    if (config == null) {
      throw const FormatException('请填写有效的第一教学周日期、总周数和每节时长。');
    }
    return TimetableImportPreview(
      base: _target,
      config: config,
      incoming: _draft?.rules ?? const [],
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
      await _repository.save(_preview ?? _buildPreview());
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
    } else {
      Get.back<void>();
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final draft = _draft;
    final fileConfig = draft?.config;
    final fileIssue = _fileIssue;
    final text = Theme.of(context).textTheme;
    return SetupPage(
      title: widget.firstRun ? '课表导入' : '课表导入与配置',
      description: '选择课表文件或从教务系统导入，核对学期与节次后再确认导入。',
      step: widget.firstRun ? 1 : null,
      actions: widget.firstRun
          ? [
              TextButton(
                onPressed: _busy ? null : _skip,
                child: const Text('稍后导入'),
              ),
            ]
          : null,
      footer: AppButton(
        label: _busy
            ? '处理中…'
            : preview != null
            ? '确认导入'
            : draft != null
            ? '检查并预览'
            : '保存学期配置',
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
          const _ImportNotice('已保存的课表读取失败，原有数据已保留。'),
          const SizedBox(height: AppSpace.md),
        ],
        Obx(() {
          final school = _profile.school;
          return ImportSourcePanel(
            schoolSubtitle: _schoolSubtitle(school),
            fileType: _fileType,
            draftLabel: _fileType == null ? _sourceLabel : null,
            ruleCount: draft?.rules.length ?? 0,
            onSelect: _busy ? null : _choose,
            onCopyTemplate: _busy ? null : _copyTemplate,
            onSchool: _busy ? null : () => _openSchool(school),
            onClear: _busy ? null : _clearFile,
            issue: fileIssue == null ? null : _ImportNotice(fileIssue),
          );
        }),
        const SizedBox(height: AppSpace.lg),
        AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('学期与节次', style: text.titleMedium),
              const SizedBox(height: AppSpace.md),
              if (_error case final message?) ...[
                _ImportNotice(message, key: _errorKey),
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
                            _resetFields(_target?.config ?? fileConfig);
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
                    label: const Text('应用文件中的学期配置'),
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

  Future<void> _skip() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _finish();
    } on Exception {
      if (mounted) _showFormIssue('无法完成首次设置，请重试。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _ImportNotice extends StatelessWidget {
  const _ImportNotice(this.message, {super.key});

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
