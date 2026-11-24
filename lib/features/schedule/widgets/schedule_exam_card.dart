import 'package:flutter/material.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/widgets/pressable.dart';
import 'package:qinghe_app/data/models/timetable_exam.dart';

/// 课表里的考试卡片。
///
/// 结构、间距、字号与配色都与 [ScheduleLessonCard] 共用同一套外观设置，
/// 只是把「地点／教师」换成「考试 · 时间／考场」，看起来就是同一张课表里的卡片。
class ScheduleExamCard extends StatelessWidget {
  const ScheduleExamCard({
    required this.exam,
    required this.compact,
    required this.colorIndex,
    required this.colorScheme,
    required this.saturation,
    required this.backgroundOpacity,
    required this.cornerRadius,
    required this.showBorder,
    required this.borderWidth,
    required this.showTopLine,
    required this.showLocation,
    required this.textLayout,
    required this.onTap,
    super.key,
  });

  final TimetableExam exam;
  final bool compact;
  final int colorIndex;
  final CourseColorScheme colorScheme;
  final double saturation;
  final double backgroundOpacity;
  final double cornerRadius;
  final bool showBorder;
  final double borderWidth;
  final bool showTopLine;
  final bool showLocation;
  final ScheduleTextLayout textLayout;

  /// 点击时传出卡片在屏幕上的位置，对话框据此从卡片放大展开。
  final ValueChanged<Rect?> onTap;

  @override
  Widget build(BuildContext context) {
    final tone = CoursePalette.of(context, colorIndex, colorScheme, saturation);
    final text = Theme.of(context).textTheme;
    final metadata = [
      ['考试', if (exam.timeLabel.isNotEmpty) exam.timeLabel].join(' '),
      if (showLocation && exam.location.isNotEmpty) exam.location,
    ].join('\n');
    final radius = BorderRadius.circular(cornerRadius);

    return Builder(
      builder: (cardContext) {
        Rect? origin() {
          final render = cardContext.findRenderObject();
          if (render is! RenderBox || !render.hasSize) return null;
          return render.localToGlobal(Offset.zero) & render.size;
        }

        return Semantics(
          button: true,
          onTap: () => onTap(origin()),
          label: [
            '考试',
            exam.courseName,
            if (exam.timeLabel.isNotEmpty) exam.timeLabel,
            if (exam.location.isNotEmpty) exam.location,
          ].join('，'),
          child: ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tone.background.withValues(alpha: backgroundOpacity),
                border: showBorder
                    ? Border.all(
                        color: tone.foreground.withValues(alpha: 0.36),
                        width: borderWidth,
                      )
                    : null,
                borderRadius: radius,
              ),
              child: Pressable(
                key: ValueKey('exam-${exam.id}'),
                onTap: () => onTap(origin()),
                splashColor: tone.foreground.withValues(alpha: 0.12),
                borderRadius: radius,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final metadataVisible = constraints.maxHeight >= 64;
                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 4 : 7,
                        vertical: compact ? 6 : 7,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (showTopLine) ...[
                            Container(
                              width: compact ? 14 : 18,
                              height: 2,
                              decoration: BoxDecoration(
                                color: tone.foreground,
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            const SizedBox(height: 4),
                          ],
                          Expanded(
                            child: _content(
                              metadata: metadataVisible ? metadata : null,
                              titleStyle: text.labelSmall?.copyWith(
                                color: tone.foreground,
                                fontSize: compact ? 10.5 : 12,
                                height: 1.18,
                                fontWeight: FontWeight.w700,
                              ),
                              metadataStyle: text.labelSmall?.copyWith(
                                color: tone.foreground.withValues(alpha: 0.78),
                                fontSize: compact ? 8.5 : 9.5,
                                height: 1.12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _content({
    required String? metadata,
    required TextStyle? titleStyle,
    required TextStyle? metadataStyle,
  }) {
    final centered = textLayout == ScheduleTextLayout.center;
    final title = Text(
      exam.courseName,
      maxLines: metadata == null ? 5 : 3,
      overflow: TextOverflow.ellipsis,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: titleStyle,
    );
    final metadataText = metadata == null
        ? null
        : Text(
            metadata,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            textAlign: centered ? TextAlign.center : TextAlign.start,
            style: metadataStyle,
          );

    if (textLayout == ScheduleTextLayout.spaced) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: title),
          if (metadataText != null) metadataText,
        ],
      );
    }

    final alignment = switch (textLayout) {
      ScheduleTextLayout.top => MainAxisAlignment.start,
      ScheduleTextLayout.center => MainAxisAlignment.center,
      ScheduleTextLayout.bottom => MainAxisAlignment.end,
      ScheduleTextLayout.spaced => MainAxisAlignment.spaceBetween,
    };
    return Column(
      mainAxisAlignment: alignment,
      crossAxisAlignment: centered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        Flexible(child: title),
        if (metadataText != null) ...[const SizedBox(height: 4), metadataText],
      ],
    );
  }
}
