import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/app_button.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/data/import/timetable_import.dart';
import 'package:qinghe_app/features/timetable_setup/widgets/setup_page.dart';

/// 粘贴 JSON 导入课表：直接在输入框里写或粘贴 JSON，右侧提供模板。
class JsonImportPage extends StatefulWidget {
  const JsonImportPage({super.key, this.initialText});

  /// 打开时预先填入的内容，便于从上次输入继续改。
  final String? initialText;

  @override
  State<JsonImportPage> createState() => _JsonImportPageState();
}

class _JsonImportPageState extends State<JsonImportPage> {
  late final _controller = TextEditingController(
    text: widget.initialText ?? '',
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fillTemplate() {
    setState(() {
      _controller.text = TimetableImport.jsonTemplate;
      _error = null;
    });
  }

  Future<void> _copyTemplate() async {
    await Clipboard.setData(ClipboardData(text: TimetableImport.jsonTemplate));
    if (mounted) showAppToast(context, 'JSON 模板已复制。');
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    try {
      final draft = TimetableImport.parseJson(_controller.text);
      Get.back<Object?>(result: draft);
    } on FormatException catch (error) {
      setState(() => _error = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final empty = _controller.text.trim().isEmpty;

    return SetupPage(
      title: '粘贴 JSON',
      description: '把课表 JSON 粘进来，或者点「插入模板」再改内容。',
      footer: AppButton(
        label: '导入这份课表',
        expand: true,
        onPressed: empty ? null : _submit,
      ),
      actions: [
        TextButton(
          key: const ValueKey('json-copy-template'),
          onPressed: _copyTemplate,
          child: const Text('复制模板'),
        ),
      ],
      children: [
        AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('JSON 内容', style: text.titleMedium),
                  const Spacer(),
                  TextButton.icon(
                    key: const ValueKey('json-insert-template'),
                    onPressed: _fillTemplate,
                    icon: const Icon(AppIcons.copy, size: 16),
                    label: const Text('插入模板'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpace.xs),
              TextField(
                key: const ValueKey('json-input'),
                controller: _controller,
                minLines: 10,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                onChanged: (_) => setState(() => _error = null),
                style: text.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  height: 1.35,
                ),
                decoration: const InputDecoration(
                  hintText: '{ "version": 1, "courses": [ … ] }',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              Text(
                '模板里包含学期配置与一门示例课程；字段说明见下方的类型提示。',
                style: text.labelSmall?.copyWith(color: colors.inkMuted),
              ),
            ],
          ),
        ),
        if (_error case final message?) ...[
          const SizedBox(height: AppSpace.md),
          _JsonNotice(message),
        ],
        const SizedBox(height: AppSpace.md),
        AppPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('字段速查', style: text.titleSmall),
              const SizedBox(height: AppSpace.xs),
              for (final line in const [
                'semester.week1Monday：第一教学周的周一，YYYY-MM-DD',
                'semester.periodStartTimes：每节开始时间，HH:mm',
                'rules[].weekday：1–7，1 是周一',
                'rules[].weeks：教学周数组，例如 [1,2,3]',
                'rules[].startPeriod / endPeriod：起止节次',
                'type：regular 普通课，lab 实验课',
              ])
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(line, style: text.bodySmall),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _JsonNotice extends StatelessWidget {
  const _JsonNotice(this.message);

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
