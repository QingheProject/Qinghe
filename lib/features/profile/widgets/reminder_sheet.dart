import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/reminder_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/widgets/app_button.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/app/widgets/app_sheet.dart';
import 'package:qinghe_app/services/notifications/course_notifications.dart';
import 'package:qinghe_app/services/notifications/reminder_plan.dart';

/// 打开「课程提醒」抽屉：选提前多久提醒，选完立刻重排通知。
Future<void> showReminderSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: AppMotion.style(context),
    backgroundColor: context.colors.surface,
    builder: (_) => const _ReminderSheet(),
  );
}

class _ReminderSheet extends StatelessWidget {
  const _ReminderSheet();

  @override
  Widget build(BuildContext context) {
    final settings = Get.find<ReminderController>();
    final colors = context.colors;

    return Obx(
      () => AppSheet(
        title: '课程提醒',
        subtitle: '上课前用系统通知提醒你，课程时间或地点变化后会自动重排。',
        note: '上课期间另有一条进度通知显示在当前课程上，可在状态栏直接看到剩余时间。',
        footer: AppButton(
          key: const ValueKey('reminder-preview-live'),
          label: '预览上课中通知',
          expand: true,
          onPressed: () async {
            if (!Get.isRegistered<CourseNotifications>()) return;
            await Get.find<CourseNotifications>().previewLive();
            if (context.mounted) {
              showAppToast(context, '已发送预览通知，20 秒后自动收回');
            }
          },
        ),
        children: [
          AppListGroup(
            children: [
              for (final minutes in reminderLeadOptions)
                AppListRow(
                  key: ValueKey('reminder-option-$minutes'),
                  icon: minutes == 0
                      ? AppIcons.notificationsOff
                      : AppIcons.notifications,
                  title: minutes == 0 ? '关闭提醒' : '提前 $minutes 分钟',
                  subtitle: minutes == 0 ? '不再发上课提醒' : null,
                  trailing: settings.leadMinutes.value == minutes
                      ? Icon(AppIcons.check, size: 18, color: colors.accent)
                      : null,
                  onTap: () async {
                    await settings.setLeadMinutes(minutes);
                    if (Get.isRegistered<CourseNotifications>()) {
                      await Get.find<CourseNotifications>().sync();
                    }
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}
