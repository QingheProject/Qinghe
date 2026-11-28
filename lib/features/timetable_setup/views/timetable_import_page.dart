import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/app_session.dart';
import 'package:qinghe_app/app/routes/app_routes.dart';
import 'package:qinghe_app/app/student_profile_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/app_button.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/data/import/jwxt/jwxt_import_draft.dart';
import 'package:qinghe_app/data/import/timetable_import.dart';
import 'package:qinghe_app/data/models/timetable_exam.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:qinghe_app/data/sources/school_registry.dart';
import 'package:qinghe_app/features/timetable_setup/views/semester_config_page.dart';
import 'package:qinghe_app/features/timetable_setup/widgets/import_source_panel.dart';
import 'package:qinghe_app/features/timetable_setup/widgets/setup_page.dart';

/// 选择数据来源，课表可继续到学期与节次配置页。
class TimetableImportPage extends StatefulWidget {
  const TimetableImportPage({this.firstRun = false, super.key});

  final bool firstRun;

  @override
  State<TimetableImportPage> createState() => _TimetableImportPageState();
}

class _TimetableImportPageState extends State<TimetableImportPage> {
  final _repository = Get.find<LocalTimetableRepository>();
  final _profile = Get.find<StudentProfileController>();
  TimetableImport? _draft;
  String? _sourceLabel;
  String? _draftIssue;
  List<TimetableExam> _exams = const [];
  String _examIssue = '';
  bool _busy = false;

  void _applyJson(TimetableImport draft) => setState(() {
    _draft = draft;
    _sourceLabel = 'JSON';
    _draftIssue = null;
    // 粘贴的 JSON 不带考试，避免把上一次读取的考试混进新学期。
    _exams = const [];
    _examIssue = '';
  });

  void _clearDraft() => setState(() {
    _draft = null;
    _sourceLabel = null;
    _draftIssue = null;
    _exams = const [];
    _examIssue = '';
  });

  /// 打开粘贴 JSON 的页面。
  Future<void> _openJson() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final result = await Get.toNamed<Object?>(AppRoutes.jsonImport);
      if (!mounted || result is! TimetableImport) return;
      _applyJson(result);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 打开学校列表选择学校；选中后写回个人信息。
  Future<void> _pickSchool() async {
    // 路由按 void 注册，取通用返回值再自行校验，避免与路由泛型耦合。
    final picked = await Get.toNamed<Object?>(
      AppRoutes.schoolPicker,
      arguments: _profile.school,
    );
    if (!mounted || picked is! String || picked.isEmpty) return;
    await _profile.save(school: picked, nickname: _profile.nickname);
    if (mounted) setState(() {});
  }

  /// 使用所选学校的教务系统读取课表。
  Future<void> _openJwxt() async {
    final school = _profile.school.trim();
    if (school.isEmpty) {
      await _pickSchool();
      return;
    }
    final source = SchoolRegistry.forSchool(school);
    if (source == null || !source.isAvailable) {
      showAppToast(context, '该学校尚未开放教务导入，请改用 JSON 粘贴导入。');
      return;
    }
    // 路由按 void 注册，这里取通用返回值再自行校验，避免与路由泛型耦合。
    final result = await Get.toNamed<Object?>(
      AppRoutes.jwxtImport,
      arguments: source,
    );
    if (!mounted || result is! JwxtImportDraft) return;
    setState(() {
      _draft = result.table;
      _exams = result.exams;
      _examIssue = result.examIssue;
      _sourceLabel = '教务系统';
      _draftIssue = null;
    });
  }

  String get _schoolSubtitle {
    final school = _profile.school.trim();
    if (school.isEmpty) return '请先选择学校';
    final source = SchoolRegistry.forSchool(school);
    if (source == null) return '$school · 需粘贴 JSON 导入';
    if (!source.isVerified) return '$school · 正在验证';
    if (!source.runsOnThisPlatform) return '$school · 当前平台暂未开放';
    return '$school · ${source.hasGrades ? '课表、考试与成绩' : '读取学校课表'}';
  }

  /// 进入学期与节次配置；已读取的数据会一起带过去。
  Future<void> _next() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final saved = await Get.toNamed<Object?>(
        AppRoutes.semesterConfig,
        arguments: SemesterConfigArgs(
          draft: _draft,
          label: _sourceLabel,
          firstRun: widget.firstRun,
          exams: _exams,
          examIssue: _examIssue,
        ),
      );
      if (!mounted) return;
      if (saved == true && !widget.firstRun) Get.back<void>();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _skip() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await Get.find<AppSession>().completeOnboarding();
      if (mounted) Get.offAllNamed<void>(AppRoutes.shell);
    } on Exception {
      if (mounted) showAppToast(context, '无法完成首次设置，请重试。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    final draftIssue = _draftIssue;
    return SetupPage(
      title: '导入数据',
      description: '从教务系统读取课表、考试和成绩，或粘贴 JSON 导入课表。',
      step: widget.firstRun ? 1 : null,
      stepCount: 3,
      actions: widget.firstRun
          ? [
              TextButton(
                onPressed: _busy ? null : _skip,
                child: const Text('稍后导入'),
              ),
            ]
          : null,
      footer: AppButton(
        label: _busy ? '处理中…' : '下一步：学期与节次',
        expand: true,
        onPressed: _busy || _repository.readFailed ? null : _next,
      ),
      children: [
        if (_repository.readFailed) ...[
          const _ImportNotice('已保存的课表读取失败，原有数据已保留。'),
          const SizedBox(height: AppSpace.md),
        ],
        Obx(
          () => ImportSourcePanel(
            schoolSubtitle: _schoolSubtitle,
            hasSchool: _profile.school.trim().isNotEmpty,
            jsonSelected: _sourceLabel == 'JSON',
            draftLabel: _sourceLabel,
            ruleCount: draft?.rules.length ?? 0,
            onJson: _busy ? null : _openJson,
            onSchool: _busy ? null : _openJwxt,
            onPickSchool: _busy ? null : _pickSchool,
            onClear: _busy ? null : _clearDraft,
            issue: draftIssue == null ? null : _ImportNotice(draftIssue),
          ),
        ),
      ],
    );
  }
}

class _ImportNotice extends StatelessWidget {
  const _ImportNotice(this.message);

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
