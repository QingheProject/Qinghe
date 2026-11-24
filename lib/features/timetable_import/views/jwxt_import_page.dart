import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/app_button.dart';
import 'package:qinghe_app/app/widgets/app_field_label.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/data/import/jwxt/jwxt_semester_options.dart';
import 'package:qinghe_app/data/sources/school_source.dart';
import 'package:qinghe_app/features/timetable_import/controllers/jwxt_import_controller.dart';
import 'package:qinghe_app/features/timetable_import/widgets/jwxt_browser.dart';

typedef JwxtBrowserBuilder =
    JwxtBrowser? Function({required ValueChanged<String> onMessage});

/// 教务系统导入页：打开学校官方页面完成登录，再读取课表交给导入预览。
class JwxtImportPage extends StatefulWidget {
  const JwxtImportPage({
    required this.source,
    this.browserBuilder = createJwxtBrowser,
    super.key,
  });

  final SchoolSource source;
  final JwxtBrowserBuilder browserBuilder;

  @override
  State<JwxtImportPage> createState() => _JwxtImportPageState();
}

class _JwxtImportPageState extends State<JwxtImportPage> {
  late final JwxtImportController _controller;
  JwxtBrowser? _browser;

  @override
  void initState() {
    super.initState();
    _controller = JwxtImportController(widget.source);
    _browser = widget.browserBuilder(onMessage: _controller.handleMessage);
    if (_browser case final browser?) {
      _controller.attach(browser);
      _controller.begin();
    }
  }

  @override
  void dispose() {
    _controller.onClose();
    super.dispose();
  }

  void _runPrimaryAction() {
    switch (_controller.stage.value) {
      case JwxtImportStage.fetched:
        final draft = _controller.takeDraft();
        if (draft != null) Get.back<Object?>(result: draft);
      case JwxtImportStage.choosingSemester:
        _controller.readTimetable();
      case JwxtImportStage.failed:
        _controller.options.value == null
            ? _controller.readSemesters()
            : _controller.readTimetable();
      case JwxtImportStage.awaitingLogin:
      case JwxtImportStage.readingSemesters:
        _controller.readSemesters();
      case JwxtImportStage.opening:
      case JwxtImportStage.readingTimetable:
      case JwxtImportStage.readingExams:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(
        title: const Text('教务系统导入'),
        centerTitle: true,
        actions: [
          Obx(
            () => IconButton(
              tooltip: '重新加载页面',
              onPressed: _controller.isBusy ? null : _controller.reload,
              icon: const Icon(AppIcons.refresh),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Obx(() {
          final stage = _controller.stage.value;
          final fetched = _controller.result.value;
          final options = _controller.options.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _StatusBar(
                school: widget.source.school,
                text: _JwxtStageText.status(stage),
                error: _controller.error.value,
              ),
              Expanded(
                child: switch ((fetched, _browser)) {
                  (final parse?, _) => _ResultPanel(
                    semester: _controller.semesterLabel,
                    count: parse.rules.length,
                    skipped: _controller.skipped,
                    examCount: _controller.examResult.value?.exams.length ?? 0,
                    examIssue: _controller.examIssue.value,
                    examSkipped: _controller.examSkipped,
                  ),
                  (null, final browser?) => ColoredBox(
                    color: colors.surface,
                    child: browser.view,
                  ),
                  _ => const _UnsupportedPanel(),
                },
              ),
              if (options != null && fetched == null)
                _SemesterPanel(
                  options: options,
                  year: _controller.year.value,
                  term: _controller.term.value,
                  enabled: !_controller.isBusy,
                  onChanged: (year, term) {
                    if (year != null) _controller.year.value = year;
                    if (term != null) _controller.term.value = term;
                  },
                ),
              _ActionBar(
                label: _JwxtStageText.button(stage, options != null),
                enabled: _canRunPrimary(stage),
                busy: _controller.isBusy,
                secondaryLabel: fetched == null ? null : '重新读取',
                onSecondary: fetched == null ? null : _controller.readSemesters,
                onPressed: _runPrimaryAction,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.lg,
                  0,
                  AppSpace.lg,
                  AppSpace.sm,
                ),
                child: Text(
                  '登录在学校官方页面完成，青禾不读取也不保存学校账号与密码。',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  bool _canRunPrimary(JwxtImportStage stage) {
    if (_controller.isBusy || _browser == null) return false;
    if (stage == JwxtImportStage.choosingSemester) {
      return _controller.canReadTimetable;
    }
    return true;
  }
}

abstract final class _JwxtStageText {
  static String status(JwxtImportStage stage) => switch (stage) {
    JwxtImportStage.opening => '正在打开学校登录页面…',
    JwxtImportStage.awaitingLogin => '请在上方页面完成登录，然后读取课表。',
    JwxtImportStage.readingSemesters => '正在读取学期列表…',
    JwxtImportStage.choosingSemester => '选择要导入的学年与学期。',
    JwxtImportStage.readingTimetable => '正在读取课表…',
    JwxtImportStage.readingExams => '正在读取考试信息…',
    JwxtImportStage.fetched => '课表已读取，请核对后使用。',
    JwxtImportStage.failed => '操作未完成，请按提示处理后重试。',
  };

  static String button(JwxtImportStage stage, bool hasOptions) =>
      switch (stage) {
        JwxtImportStage.opening => '正在打开…',
        JwxtImportStage.awaitingLogin => '我已登录，读取学期',
        JwxtImportStage.readingSemesters => '读取中…',
        JwxtImportStage.choosingSemester => '读取本学期课表',
        JwxtImportStage.readingTimetable => '读取中…',
        JwxtImportStage.readingExams => '读取中…',
        JwxtImportStage.fetched => '使用这份课表',
        JwxtImportStage.failed => hasOptions ? '重试读取课表' : '重试读取学期',
      };
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({
    required this.school,
    required this.text,
    required this.error,
  });

  final String school;
  final String text;
  final String error;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final tint =
        theme.inputDecorationTheme.errorStyle?.color ?? theme.colorScheme.error;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('$school · 教务系统', style: theme.textTheme.labelMedium),
          const SizedBox(height: 2),
          Semantics(
            liveRegion: true,
            child: Text(
              error.isEmpty ? text : error,
              style: error.isEmpty
                  ? theme.textTheme.bodySmall
                  : theme.textTheme.bodySmall?.copyWith(color: tint),
            ),
          ),
        ],
      ),
    );
  }
}

class _SemesterPanel extends StatelessWidget {
  const _SemesterPanel({
    required this.options,
    required this.year,
    required this.term,
    required this.enabled,
    required this.onChanged,
  });

  final JwxtSemesterOptions options;
  final String year;
  final String term;
  final bool enabled;
  final void Function(String? year, String? term) onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: context.colors.line),
          bottom: BorderSide(color: context.colors.line),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
        AppSpace.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: AppFieldLabel(
              label: '学年',
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                style: text.bodyMedium,
                icon: const Icon(AppIcons.chevronDown),
                initialValue: year.isEmpty ? null : year,
                items: [
                  for (final choice in options.years)
                    DropdownMenuItem(
                      value: choice.value,
                      child: Text(
                        choice.label,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: enabled ? (value) => onChanged(value, null) : null,
              ),
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: AppFieldLabel(
              label: '学期',
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                style: text.bodyMedium,
                icon: const Icon(AppIcons.chevronDown),
                initialValue: term.isEmpty ? null : term,
                items: [
                  for (final choice in options.terms)
                    DropdownMenuItem(
                      value: choice.value,
                      child: Text(
                        _termLabel(options, year, choice),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: enabled ? (value) => onChanged(null, value) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _termLabel(
    JwxtSemesterOptions options,
    String year,
    JwxtSemesterChoice choice,
  ) {
    final full = options.labelOf(year, choice.value);
    final parts = full.split(' ');
    return parts.length > 1 ? parts.last : choice.label;
  }
}

class _ResultPanel extends StatelessWidget {
  const _ResultPanel({
    required this.semester,
    required this.count,
    required this.skipped,
    required this.examCount,
    required this.examIssue,
    required this.examSkipped,
  });

  final String semester;
  final int count;
  final List<String> skipped;
  final int examCount;
  final String examIssue;
  final List<String> examSkipped;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('已读取 $count 条上课安排', style: text.titleMedium),
                const SizedBox(height: AppSpace.xs),
                Text(
                  semester.isEmpty ? '学期信息未读取' : semester,
                  style: text.bodySmall,
                ),
                const SizedBox(height: AppSpace.sm),
                Semantics(
                  liveRegion: true,
                  child: Row(
                    children: [
                      Icon(
                        examIssue.isEmpty
                            ? AppIcons.calendarCheck
                            : AppIcons.info,
                        size: 16,
                        color: examIssue.isEmpty
                            ? colors.accent
                            : colors.inkMuted,
                      ),
                      const SizedBox(width: AppSpace.xs),
                      Expanded(
                        child: Text(
                          examIssue.isEmpty
                              ? '考试信息 $examCount 场'
                              : '上课安排已读到，考试信息未获取：$examIssue',
                          style: text.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (skipped.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            AppPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${skipped.length} 条安排没有固定的星期或节次，已跳过',
                    style: text.titleSmall,
                  ),
                  const SizedBox(height: AppSpace.xs),
                  for (final item in skipped)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(item, style: text.bodySmall),
                    ),
                ],
              ),
            ),
          ],
          if (examSkipped.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            AppPanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${examSkipped.length} 场考试缺少日期，已跳过',
                    style: text.titleSmall,
                  ),
                  const SizedBox(height: AppSpace.xs),
                  for (final item in examSkipped)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(item, style: text.bodySmall),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _UnsupportedPanel extends StatelessWidget {
  const _UnsupportedPanel();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Text(
          '当前平台没有可用的内置浏览器，请使用 CSV 或 JSON 导入课表。',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.label,
    required this.enabled,
    required this.busy,
    required this.onPressed,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String label;
  final bool enabled;
  final bool busy;
  final VoidCallback onPressed;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.md,
        AppSpace.lg,
        AppSpace.sm,
      ),
      child: Row(
        children: [
          if (secondaryLabel case final secondary?) ...[
            AppButton(
              label: secondary,
              tone: AppButtonTone.secondary,
              onPressed: busy ? null : onSecondary,
            ),
            const SizedBox(width: AppSpace.sm),
          ],
          Expanded(
            child: AppButton(
              label: label,
              expand: true,
              onPressed: enabled ? onPressed : null,
            ),
          ),
        ],
      ),
    );
  }
}
