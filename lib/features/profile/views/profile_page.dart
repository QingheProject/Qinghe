import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/reminder_controller.dart';
import 'package:qinghe_app/app/routes/app_routes.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:qinghe_app/features/profile/widgets/semester_progress_card.dart';
import 'package:qinghe_app/features/shell/controllers/shell_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final timetables = Get.find<LocalTimetableRepository>();
    final reminder = Get.find<ReminderController>();

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
                    icon: AppIcons.palette,
                    title: '外观',
                    subtitle: '主题与配色',
                    onTap: () => Get.toNamed<void>(AppRoutes.appearance),
                  ),
                  Obx(
                    () => AppListRow(
                      key: const ValueKey('profile-reminder'),
                      icon: AppIcons.notifications,
                      title: '课程提醒',
                      subtitle: reminder.classEnabled
                          ? '课前 ${reminder.classLeadMinutes.value} 分钟提醒'
                          : '已关闭',
                      onTap: () => Get.toNamed<void>(AppRoutes.reminders),
                    ),
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
