import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/routes/app_routes.dart';
import 'package:qinghe_app/app/student_profile_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/app/widgets/app_tag.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';
import 'package:qinghe_app/app/widgets/student_avatar.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:qinghe_app/features/profile/widgets/profile_editor_sheet.dart';
import 'package:qinghe_app/features/profile/widgets/semester_progress_card.dart';
import 'package:qinghe_app/features/shell/controllers/shell_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    void soon(String feature) => showAppToast(context, '$feature即将推出');
    const soonTag = AppTag(label: '即将推出', tone: AppTagTone.faint);
    final profile = Get.find<StudentProfileController>();
    final timetables = Get.find<LocalTimetableRepository>();

    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            key: const ValueKey('profile-scroll'),
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.paddingOf(context).bottom + 24,
            ),
            children: [
              const AppPageHeader(title: '我的'),
              const SizedBox(height: 24),
              Obx(
                () => _ProfileCard(
                  nickname: profile.nickname,
                  school: profile.school,
                  avatarIcon: profile.avatarIcon,
                  avatarColor: profile.avatarColor,
                  onTap: () => showProfileEditorSheet(context),
                ),
              ),
              const SizedBox(height: 20),
              Obx(() {
                final timetable = timetables.active;
                return SemesterProgressCard(
                  key: const ValueKey('profile-semester-dial'),
                  timetable: timetable,
                  now: DateTime.now(),
                  onTap: () {
                    if (timetable == null) {
                      Get.toNamed<void>(AppRoutes.timetableImport);
                      return;
                    }
                    Get.find<ShellController>().selectSection(1);
                  },
                );
              }),
              const SizedBox(height: 20),
              AppListGroup(
                title: '设置',
                children: [
                  AppListRow(
                    icon: AppIcons.columns,
                    title: '课表外观',
                    subtitle: '尺寸、信息与间距',
                    onTap: () =>
                        Get.toNamed<void>(AppRoutes.scheduleAppearance),
                  ),
                  AppListRow(
                    icon: AppIcons.upload,
                    title: '课表导入',
                    subtitle: '教务系统、CSV 或 JSON',
                    onTap: () => Get.toNamed<void>(AppRoutes.timetableImport),
                  ),
                  AppListRow(
                    icon: AppIcons.calendarCheck,
                    title: '学期与节次',
                    subtitle: '教学周与上课时间',
                    onTap: () => Get.toNamed<void>(AppRoutes.semesterConfig),
                  ),
                  Obx(() {
                    final exams = timetables.active?.exams ?? const [];
                    return AppListRow(
                      key: const ValueKey('profile-exams'),
                      icon: AppIcons.clock,
                      title: '考试信息',
                      subtitle: exams.isEmpty
                          ? '尚未读取考试安排'
                          : '${exams.length} 场考试',
                      onTap: () => Get.toNamed<void>(AppRoutes.exams),
                    );
                  }),
                  AppListRow(
                    icon: AppIcons.palette,
                    title: '外观',
                    subtitle: '主题与配色',
                    onTap: () => Get.toNamed<void>(AppRoutes.appearance),
                  ),
                  AppListRow(
                    icon: AppIcons.notifications,
                    title: '课程提醒',
                    trailing: soonTag,
                    onTap: () => soon('课程提醒'),
                  ),
                  AppListRow(
                    icon: AppIcons.info,
                    title: '关于青禾',
                    subtitle: '离线大学课表 · 0.1.0',
                    onTap: () => showAppToast(context, '青禾 0.1.0'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.nickname,
    required this.school,
    required this.avatarIcon,
    required this.avatarColor,
    required this.onTap,
  });

  final String nickname;
  final String school;
  final int avatarIcon;
  final int avatarColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final hasName = nickname.trim().isNotEmpty;

    return Pressable(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      semanticLabel: '编辑个人信息',
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Row(
          children: [
            StudentAvatar(
              iconIndex: avatarIcon,
              colorIndex: avatarColor,
              size: 58,
              onTap: onTap,
            ),
            const SizedBox(width: AppSpace.lg),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasName ? nickname : '未填写昵称',
                    style: text.titleMedium?.copyWith(
                      color: hasName ? colors.ink : colors.inkMuted,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(AppIcons.school, size: 14, color: colors.inkFaint),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          school.trim().isEmpty ? '填写学校名称' : school,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            AnimatedContainer(
              duration: AppMotion.of(context, AppMotion.fast),
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: colors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(AppIcons.edit, color: colors.inkMuted, size: 17),
            ),
          ],
        ),
      ),
    );
  }
}
