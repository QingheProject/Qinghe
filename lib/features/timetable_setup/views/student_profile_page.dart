import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/routes/app_routes.dart';
import 'package:qinghe_app/app/student_profile_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/app_button.dart';
import 'package:qinghe_app/app/widgets/app_field_label.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';
import 'package:qinghe_app/features/timetable_setup/widgets/setup_page.dart';

class StudentProfilePage extends StatefulWidget {
  const StudentProfilePage({this.firstRun = false, super.key});

  final bool firstRun;

  @override
  State<StudentProfilePage> createState() => _StudentProfilePageState();
}

class _StudentProfilePageState extends State<StudentProfilePage> {
  final _profile = Get.find<StudentProfileController>();
  late String _school = _profile.school;
  late final _nickname = TextEditingController(text: _profile.nickname);
  bool _saving = false;

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  Future<void> _pickSchool() async {
    // 路由按 void 注册，取通用返回值再自行校验，避免与路由泛型耦合。
    final picked = await Get.toNamed<Object?>(
      AppRoutes.schoolPicker,
      arguments: _school,
    );
    if (!mounted || picked is! String) return;
    setState(() => _school = picked);
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
        school: _school.trim(),
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
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final school = _school.trim();

    return SetupPage(
      title: '个人信息',
      description: '学校决定能否使用教务系统导入。学校和昵称仅保存在本机。',
      step: widget.firstRun ? 0 : null,
      stepCount: 3,
      actions: widget.firstRun
          ? [
              TextButton(
                onPressed: _saving ? null : _next,
                child: const Text('稍后填写'),
              ),
            ]
          : null,
      footer: AppButton(
        label: widget.firstRun ? '继续导入数据' : '保存资料',
        expand: true,
        onPressed: _saving ? null : _save,
      ),
      children: [
        AppPanel(
          child: Column(
            children: [
              AppFieldLabel(
                label: '学校',
                child: Pressable(
                  key: const ValueKey('setup-school'),
                  color: colors.surfaceMuted,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  semanticLabel: school.isEmpty ? '选择学校' : '已选学校 $school，点击更换',
                  onTap: _saving ? null : _pickSchool,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpace.md,
                        vertical: AppSpace.sm,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            AppIcons.school,
                            size: 20,
                            color: colors.inkMuted,
                          ),
                          const SizedBox(width: AppSpace.md),
                          Expanded(
                            child: Text(
                              school.isEmpty ? '选择学校' : school,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodyMedium?.copyWith(
                                color: school.isEmpty
                                    ? colors.inkMuted
                                    : colors.ink,
                              ),
                            ),
                          ),
                          Icon(
                            AppIcons.chevronRight,
                            size: 16,
                            color: colors.inkFaint,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              AppFieldLabel(
                label: '昵称（选填）',
                child: TextField(
                  key: const ValueKey('setup-nickname'),
                  controller: _nickname,
                  maxLength: 32,
                  style: text.bodyMedium,
                  decoration: InputDecoration(
                    hintText: '填写昵称',
                    prefixIcon: const Icon(AppIcons.user, size: 20),
                    prefixIconColor: colors.inkMuted,
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
}
