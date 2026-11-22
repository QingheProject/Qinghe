import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/routes/app_routes.dart';
import 'package:qinghe_app/app/student_profile_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/app/widgets/app_tag.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:qinghe_app/features/profile/widgets/my_courses_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    void soon(String feature) => showAppToast(context, '$feature即将推出');
    const soonTag = AppTag(label: '即将推出', tone: AppTagTone.faint);
    final profile = Get.find<StudentProfileController>();
    final timetables = Get.find<LocalTimetableRepository>();

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            key: const ValueKey('profile-scroll'),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              const AppPageHeader(title: '我的'),
              const SizedBox(height: 24),
              Obx(
                () => _ProfileCard(
                  nickname: profile.nickname,
                  school: profile.school,
                ),
              ),
              const SizedBox(height: 20),
              Obx(
                () => MyCoursesCard(
                  timetable: timetables.active,
                  now: DateTime.now(),
                ),
              ),
              const SizedBox(height: 20),
              AppListGroup(
                title: '课表',
                children: [
                  AppListRow(
                    icon: Icons.view_week_outlined,
                    title: '课表外观',
                    subtitle: '尺寸、信息与间距',
                    onTap: () =>
                        Get.toNamed<void>(AppRoutes.scheduleAppearance),
                  ),
                  AppListRow(
                    icon: Icons.date_range_outlined,
                    title: '课表导入与配置',
                    subtitle: '学期、节次和导入来源',
                    onTap: () => Get.toNamed<void>(AppRoutes.timetableImport),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AppListGroup(
                title: '偏好',
                children: [
                  AppListRow(
                    icon: Icons.palette_outlined,
                    title: '外观与布局',
                    onTap: () => Get.toNamed<void>(AppRoutes.appearance),
                  ),
                  AppListRow(
                    icon: Icons.notifications_none_rounded,
                    title: '课程提醒',
                    trailing: soonTag,
                    onTap: () => soon('课程提醒'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AppListGroup(
                title: '其他',
                children: [
                  AppListRow(
                    icon: Icons.auto_awesome_outlined,
                    title: '重新查看引导',
                    onTap: () => Get.toNamed<void>(AppRoutes.onboarding),
                  ),
                  AppListRow(
                    icon: Icons.info_outline_rounded,
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
  const _ProfileCard({required this.nickname, required this.school});

  final String nickname;
  final String school;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return Pressable(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      semanticLabel: '编辑个人信息',
      onTap: () => Get.toNamed<void>(AppRoutes.studentProfile),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.lg),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colors.accentSoft,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(Icons.person_outline, color: colors.accent),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nickname.isEmpty ? '个人信息' : nickname,
                    style: text.titleMedium,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    school.isEmpty
                        ? (nickname.isEmpty ? '填写学校与昵称' : '填写学校')
                        : school,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Icon(Icons.edit_outlined, color: colors.inkMuted, size: 19),
          ],
        ),
      ),
    );
  }
}
