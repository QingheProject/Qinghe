import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/routes/app_routes.dart';
import 'package:qinghe_app/app/student_profile_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/app_button.dart';
import 'package:qinghe_app/app/widgets/app_field_label.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';
import 'package:qinghe_app/app/widgets/student_avatar.dart';

/// 个人信息编辑面板：昵称、学校与头像样式，保存后立即生效。
Future<bool?> showProfileEditorSheet(BuildContext context) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: AppMotion.style(context),
    builder: (_) => const _ProfileEditorSheet(),
  );
}

class _ProfileEditorSheet extends StatefulWidget {
  const _ProfileEditorSheet();

  @override
  State<_ProfileEditorSheet> createState() => _ProfileEditorSheetState();
}

class _ProfileEditorSheetState extends State<_ProfileEditorSheet> {
  final _profile = Get.find<StudentProfileController>();
  late final _nickname = TextEditingController(text: _profile.nickname);
  late String _school = _profile.school;
  late int _icon = _profile.avatarIcon;
  late int _color = _profile.avatarColor;
  bool _avatarOpen = false;
  bool _saving = false;

  @override
  void dispose() {
    _nickname.dispose();
    super.dispose();
  }

  /// 从学校列表选择学校。
  Future<void> _pickSchool(BuildContext context) async {
    // 路由按 void 注册，取通用返回值再自行校验，避免与路由泛型耦合。
    final picked = await Get.toNamed<Object?>(
      AppRoutes.schoolPicker,
      arguments: _school,
    );
    if (!mounted || picked is! String) return;
    setState(() => _school = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _profile.save(
        school: _school.trim(),
        nickname: _nickname.text.trim(),
      );
      await _profile.saveAvatar(icon: _icon, color: _color);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('个人信息已保存')));
    } on Exception {
      if (mounted) setState(() => _saving = false);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('保存失败，请重试')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final inset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: inset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            Row(
              children: [
                StudentAvatar(
                  iconIndex: _icon,
                  colorIndex: _color,
                  size: 60,
                  semanticLabel: '更换头像',
                  onTap: () => setState(() => _avatarOpen = !_avatarOpen),
                ),
                const SizedBox(width: AppSpace.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('个人资料', style: text.titleLarge),
                      const SizedBox(height: 2),
                      Text(
                        _avatarOpen ? '选择头像图形与底色' : '点击头像更换样式',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: '关闭',
                  icon: const Icon(AppIcons.close),
                ),
              ],
            ),
            AnimatedSize(
              duration: AppMotion.of(context, AppMotion.medium),
              curve: AppMotion.emphasized,
              alignment: Alignment.topCenter,
              child: _avatarOpen ? _avatarPicker(context) : const SizedBox(),
            ),
            const SizedBox(height: AppSpace.xl),
            AppFieldLabel(
              label: '昵称',
              child: TextField(
                key: const ValueKey('profile-name-field'),
                controller: _nickname,
                maxLength: 32,
                textInputAction: TextInputAction.next,
                style: text.bodyMedium,
                decoration: const InputDecoration(
                  hintText: '填写昵称',
                  prefixIcon: Icon(AppIcons.user, size: 20),
                  counterText: '',
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            AppFieldLabel(
              label: '学校',
              child: Pressable(
                key: const ValueKey('profile-school-field'),
                color: context.colors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.md),
                semanticLabel: _school.isEmpty ? '选择学校' : '已选学校 $_school，点击更换',
                onTap: _saving ? null : () => _pickSchool(context),
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
                          color: context.colors.inkMuted,
                        ),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: Text(
                            _school.isEmpty ? '选择学校' : _school,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.bodyMedium,
                          ),
                        ),
                        Icon(
                          AppIcons.chevronRight,
                          size: 16,
                          color: context.colors.inkFaint,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            AppButton(
              label: '保存',
              expand: true,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _avatarPicker(BuildContext context) {
    final colors = context.colors;
    final tones = CoursePalette.colors(CourseColorScheme.qinghe);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      key: const ValueKey('profile-avatar-options'),
      margin: const EdgeInsets.only(top: AppSpace.lg),
      padding: const EdgeInsets.all(AppSpace.md),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (
                var index = 0;
                index < AppIcons.avatarChoices.length;
                index++
              )
                _AvatarIconChoice(
                  icon: AppIcons.avatarChoices[index],
                  selected: index == _icon,
                  onTap: () => setState(() => _icon = index),
                ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Row(
            children: [
              for (var index = 0; index < tones.length; index++)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpace.sm),
                  child: _AvatarToneChoice(
                    color: dark
                        ? Color.lerp(tones[index], Colors.white, 0.24)!
                        : tones[index],
                    selected: index == _color,
                    onTap: () => setState(() => _color = index),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AvatarIconChoice extends StatelessWidget {
  const _AvatarIconChoice({
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: '选择头像图形',
      child: Material(
        color: selected ? colors.accentSoft : colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 42,
            height: 42,
            child: Icon(
              icon,
              size: 21,
              color: selected ? colors.accent : colors.inkMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarToneChoice extends StatelessWidget {
  const _AvatarToneChoice({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Semantics(
      button: true,
      selected: selected,
      label: '选择头像底色',
      child: InkResponse(
        onTap: onTap,
        radius: 18,
        child: AnimatedContainer(
          duration: AppMotion.of(context, AppMotion.fast),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? colors.ink : Colors.transparent,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}
