import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/routes/app_routes.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/app_button.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';
import 'package:qinghe_app/data/models/timetable_exam.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:qinghe_app/features/schedule/widgets/exam_sheet.dart';

/// 考试信息：按日期列出本学期的考试，可查看详情。
class ExamListPage extends StatelessWidget {
  const ExamListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final repository = Get.find<LocalTimetableRepository>();
    final table = repository.active;
    final exams = table?.exams ?? const <TimetableExam>[];
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    return Scaffold(
      backgroundColor: colors.canvas,
      appBar: AppBar(title: const Text('考试信息'), centerTitle: true),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: exams.isEmpty
                ? _EmptyExams(
                    hasTimetable: table != null,
                    onImport: () =>
                        Get.toNamed<void>(AppRoutes.timetableImport),
                  )
                : ListView.separated(
                    key: const ValueKey('exam-list'),
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    itemCount: exams.length + 1,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            '${table?.config.name ?? '本学期'} · 共 ${exams.length} 场考试',
                            style: text.labelMedium,
                          ),
                        );
                      }
                      final exam = exams[index - 1];
                      return _ExamRow(
                        exam: exam,
                        today: todayDate,
                        colorIndex: table?.examColorIndex(exam) ?? 0,
                        onTap: () => showExamDialog(
                          context,
                          exam,
                          colorIndex: table?.examColorIndex(exam) ?? 0,
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}

class _ExamRow extends StatelessWidget {
  const _ExamRow({
    required this.exam,
    required this.today,
    required this.colorIndex,
    required this.onTap,
  });

  final TimetableExam exam;
  final DateTime today;
  final int colorIndex;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    final appearance = Get.isRegistered<AppearanceController>()
        ? Get.find<AppearanceController>()
        : null;
    final tone = CoursePalette.of(
      context,
      colorIndex,
      appearance?.courseColorScheme.value ?? CourseColorScheme.qinghe,
      appearance?.scheduleCourseSaturation.value ?? 1,
    );
    final days = exam.day.difference(today).inDays;
    final countdown = switch (days) {
      < 0 => '已结束',
      0 => '今天',
      1 => '明天',
      _ => '$days 天后',
    };
    final upcoming = days >= 0;
    final details = [
      if (exam.timeLabel.isNotEmpty) exam.timeLabel,
      if (exam.location.isNotEmpty) exam.location,
      if (exam.seat.isNotEmpty) '座位 ${exam.seat}',
    ].join(' · ');

    return Pressable(
      key: ValueKey('exam-row-${exam.id}'),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      color: colors.surface,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日期块用这门课的课表配色，和课表里的卡片对得上。
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: tone.background,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${exam.date.month}月',
                    style: text.labelSmall?.copyWith(
                      color: tone.foreground.withValues(alpha: 0.78),
                      height: 1.1,
                    ),
                  ),
                  Text(
                    '${exam.date.day}',
                    style: text.titleMedium?.copyWith(
                      color: tone.foreground,
                      height: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          exam.courseName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleMedium?.copyWith(color: colors.ink),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Text(
                        countdown,
                        style: text.labelSmall?.copyWith(
                          color: upcoming ? tone.foreground : colors.inkFaint,
                        ),
                      ),
                    ],
                  ),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      details,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: colors.inkMuted),
                    ),
                  ],
                  if (exam.note.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      exam.note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: colors.inkFaint),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            Icon(AppIcons.chevronRight, size: 16, color: colors.inkFaint),
          ],
        ),
      ),
    );
  }
}

class _EmptyExams extends StatelessWidget {
  const _EmptyExams({required this.hasTimetable, required this.onImport});

  final bool hasTimetable;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
      child: Column(
        children: [
          Icon(AppIcons.calendarCheck, size: 34, color: colors.inkFaint),
          const SizedBox(height: AppSpace.md),
          Text(
            hasTimetable ? '本学期还没有考试信息' : '导入课表后在这里查看考试',
            textAlign: TextAlign.center,
            style: text.titleMedium,
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            hasTimetable
                ? '在教务系统导入时会一起读取考试安排；如果当时没有读到，可以重新导入一次。'
                : '考试安排随课表一起从教务系统读取，也可用 CSV／JSON 导入课表后手动补充。',
            textAlign: TextAlign.center,
            style: text.bodySmall,
          ),
          const SizedBox(height: AppSpace.lg),
          AppButton(label: '去导入课表', expand: true, onPressed: onImport),
        ],
      ),
    );
  }
}
