import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/routes/app_routes.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/app/widgets/app_tag.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    void soon(String feature) => showAppToast(context, '$feature即将推出');
    const soonTag = AppTag(label: '即将推出', tone: AppTagTone.faint);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.paddingOf(context).bottom + 24,
        ),
        children: [
          const AppPageHeader(title: '我的'),
          const SizedBox(height: 24),
          AppListGroup(
            title: '课表',
            children: [
              AppListRow(
                icon: Icons.date_range_outlined,
                title: '学期与节次',
                trailing: soonTag,
                onTap: () => soon('学期设置'),
              ),
              AppListRow(
                icon: Icons.upload_file_outlined,
                title: 'CSV 模板导入',
                trailing: soonTag,
                onTap: () => soon('CSV 导入'),
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
    );
  }
}
