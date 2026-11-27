import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';

Future<T?> showAppSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: false,
    sheetAnimationStyle: AppMotion.style(context),
  );
}

/// 应用内所有底部抽屉的统一外壳。
///
/// 统一的部分：顶部拖拽条、标题字号与内边距、关闭按钮、内容滚动区的左右留白、
/// 底部说明文字与操作按钮的位置。各处的抽屉只负责传标题和内容。
class AppSheet extends StatelessWidget {
  const AppSheet({
    required this.title,
    required this.children,
    this.subtitle,
    this.actions = const <Widget>[],
    this.note,
    this.footer,
    this.showClose = true,
    this.maxHeightFactor = 0.82,
    super.key,
  });

  final String title;

  /// 标题下的一句说明。
  final String? subtitle;

  /// 标题右侧、关闭按钮左边的操作，例如「回到本周」。
  final List<Widget> actions;

  /// 底部的补充说明，例如「主题仍在『我的』页面」。
  final String? note;

  /// 固定在底部的主操作，例如「保存时间」。
  final Widget? footer;
  final bool showClose;

  /// 抽屉最高占屏幕的比例。
  final double maxHeightFactor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * maxHeightFactor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpace.sm),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 8, 0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(title, style: text.titleMedium),
                    ),
                  ),
                  ...actions,
                  if (showClose)
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: '关闭',
                      constraints: const BoxConstraints.tightFor(
                        width: 44,
                        height: 44,
                      ),
                      icon: const Icon(AppIcons.close, size: 20),
                    ),
                ],
              ),
            ),
            if (subtitle case final line?)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 0),
                child: Text(
                  line,
                  style: text.bodySmall?.copyWith(color: colors.inkMuted),
                ),
              ),
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  footer == null ? 16 : 4,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
            if (note case final line?)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(
                  line,
                  style: text.labelSmall?.copyWith(color: colors.inkMuted),
                ),
              ),
            if (footer case final widget?)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: widget,
              )
            else
              const SizedBox(height: AppSpace.sm),
          ],
        ),
      ),
    );
  }
}

/// 抽屉标题右侧的文字操作，例如「回到本周」。
///
class AppSheetAction extends StatelessWidget {
  const AppSheetAction({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
        minimumSize: const Size(0, 44),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.standard,
        textStyle: Theme.of(context).textTheme.labelMedium,
        foregroundColor: colors.accent,
      ),
      child: Text(label),
    );
  }
}
