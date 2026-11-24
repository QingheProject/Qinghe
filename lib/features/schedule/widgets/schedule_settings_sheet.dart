import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/routes/app_routes.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/widgets/app_sections.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';

/// 课表设置抽屉：把与课表相关的设置集中在这里，不再散落到别处。
Future<void> showScheduleSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: AppMotion.style(context),
    backgroundColor: context.colors.surface,
    builder: (sheetContext) => const _SettingsSheet(),
  );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final colors = context.colors;
    final repository = Get.isRegistered<LocalTimetableRepository>()
        ? Get.find<LocalTimetableRepository>()
        : null;
    final exams = repository?.active?.exams.length ?? 0;

    void open(String route) {
      Navigator.of(context).pop();
      Get.toNamed<void>(route);
    }

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const SizedBox(width: 4),
                Expanded(child: Text('课表设置', style: text.titleMedium)),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: '关闭',
                  icon: const Icon(AppIcons.close, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 4),
            AppListGroup(
              title: '课表',
              children: [
                AppListRow(
                  key: const ValueKey('schedule-settings-appearance'),
                  icon: AppIcons.columns,
                  title: '课表外观',
                  subtitle: '尺寸、信息与间距',
                  onTap: () => open(AppRoutes.scheduleAppearance),
                ),
                AppListRow(
                  key: const ValueKey('schedule-settings-import'),
                  icon: AppIcons.upload,
                  title: '课表导入',
                  subtitle: '教务系统、JSON',
                  onTap: () => open(AppRoutes.timetableImport),
                ),
                AppListRow(
                  key: const ValueKey('schedule-settings-semester'),
                  icon: AppIcons.calendarCheck,
                  title: '学期与节次',
                  subtitle: '教学周与上课时间',
                  onTap: () => open(AppRoutes.semesterConfig),
                ),
                AppListRow(
                  key: const ValueKey('schedule-settings-exams'),
                  icon: AppIcons.clock,
                  title: '考试信息',
                  subtitle: exams == 0 ? '尚未读取考试安排' : '$exams 场考试',
                  onTap: () => open(AppRoutes.exams),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 4),
              child: Text(
                '主题、课程提醒等应用级设置仍在「我的」页面。',
                style: text.labelSmall?.copyWith(color: colors.inkMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
