import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/routes/app_routes.dart';
import 'package:qinghe_app/app/student_profile_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/app_button.dart';
import 'package:qinghe_app/app/widgets/app_field_label.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/features/timetable_setup/widgets/setup_page.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({this.firstRun = false, super.key});

  final bool firstRun;

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final _profile = Get.find<StudentProfileController>();
  late final _school = TextEditingController(text: _profile.school);
  late final _nickname = TextEditingController(text: _profile.nickname);
  bool _saving = false;

  @override
  void dispose() {
    _school.dispose();
    _nickname.dispose();
    super.dispose();
  }

  void _next() {
    if (widget.firstRun) {
      Get.toNamed<void>(AppRoutes.timetableImport, arguments: true);
    } else {
      Get.back<void>();
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _profile.save(
        school: _school.text.trim(),
        nickname: _nickname.text.trim(),
      );
      if (mounted) _next();
    } on Exception {
      if (mounted) showAppToast(context, '个人信息保存失败，请重试。');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SetupPage(
    title: '个人信息',
    description: '学校用于匹配教务导入。学校和昵称仅保存在本机。',
    step: widget.firstRun ? 0 : null,
    actions: widget.firstRun
        ? [
            TextButton(
              onPressed: _saving ? null : _next,
              child: const Text('稍后填写'),
            ),
          ]
        : null,
    footer: AppButton(
      label: widget.firstRun ? '继续到课表导入' : '保存资料',
      expand: true,
      onPressed: _saving ? null : _save,
    ),
    children: [
      AppPanel(
        child: Column(
          children: [
            AppFieldLabel(
              label: '学校',
              child: TextField(
                key: const ValueKey('setup-school'),
                controller: _school,
                maxLength: 80,
                textInputAction: TextInputAction.next,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: '搜索或填写学校名称',
                  prefixIcon: const Icon(AppIcons.school, size: 20),
                  prefixIconColor: context.colors.inkMuted,
                  counterText: '',
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            if (_school.text.trim().isNotEmpty &&
                _school.text.trim() != '西南科技大学' &&
                '西南科技大学'.contains(_school.text.trim())) ...[
              const SizedBox(height: AppSpace.sm),
              Material(
                color: context.colors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.md),
                clipBehavior: Clip.antiAlias,
                child: AppListRow(
                  icon: AppIcons.school,
                  title: '西南科技大学',
                  onTap: () => setState(() => _school.text = '西南科技大学'),
                ),
              ),
            ],
            const SizedBox(height: AppSpace.lg),
            AppFieldLabel(
              label: '昵称（选填）',
              child: TextField(
                key: const ValueKey('setup-nickname'),
                controller: _nickname,
                maxLength: 32,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: '填写昵称',
                  prefixIcon: const Icon(AppIcons.user, size: 20),
                  prefixIconColor: context.colors.inkMuted,
                  counterText: '',
                ),
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
