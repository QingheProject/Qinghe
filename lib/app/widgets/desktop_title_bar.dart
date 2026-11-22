import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_icons.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/app/theme/app_tokens.dart';
import 'package:qinghe_app/app/widgets/brand_mark.dart';

/// 桌面端自绘标题栏：左侧品牌，右侧窗口按钮，中间整条区域可拖动窗口。
///
/// 只负责呈现与手势，窗口操作通过回调交给外部，便于在测试中替换。
class DesktopTitleBar extends StatelessWidget {
  const DesktopTitleBar({
    required this.maximized,
    required this.onStartDrag,
    required this.onMinimize,
    required this.onToggleMaximize,
    required this.onClose,
    this.height = 40,
    super.key,
  });

  final bool maximized;
  final VoidCallback onStartDrag;
  final VoidCallback onMinimize;
  final VoidCallback onToggleMaximize;
  final VoidCallback onClose;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = Theme.of(context).textTheme;

    return SizedBox(
      key: const ValueKey('desktop-title-bar'),
      height: height,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) => onStartDrag(),
              onDoubleTap: onToggleMaximize,
              child: Padding(
                padding: const EdgeInsets.only(left: 14),
                child: Row(
                  children: [
                    const ExcludeSemantics(child: BrandMark(size: 17)),
                    const SizedBox(width: AppSpace.sm),
                    Flexible(
                      child: Text(
                        '青禾',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelMedium?.copyWith(
                          color: colors.inkMuted,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          _CaptionButton(
            buttonKey: const ValueKey('title-bar-minimize'),
            icon: AppIcons.windowMinimize,
            label: '最小化',
            onTap: onMinimize,
          ),
          _CaptionButton(
            buttonKey: const ValueKey('title-bar-maximize'),
            icon: maximized ? AppIcons.windowRestore : AppIcons.windowMaximize,
            label: maximized ? '还原' : '最大化',
            onTap: onToggleMaximize,
          ),
          _CaptionButton(
            buttonKey: const ValueKey('title-bar-close'),
            icon: AppIcons.close,
            label: '关闭',
            onTap: onClose,
            destructive: true,
          ),
        ],
      ),
    );
  }
}

class _CaptionButton extends StatefulWidget {
  const _CaptionButton({
    required this.buttonKey,
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final Key buttonKey;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  State<_CaptionButton> createState() => _CaptionButtonState();
}

class _CaptionButtonState extends State<_CaptionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = widget.destructive && _hovered
        ? Colors.white
        : (_hovered ? colors.ink : colors.inkMuted);
    final background = _hovered
        ? (widget.destructive
              ? const Color(0xFFC42B1C)
              : colors.ink.withValues(alpha: 0.06))
        : Colors.transparent;

    return Semantics(
      button: true,
      label: widget.label,
      child: ExcludeSemantics(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            key: widget.buttonKey,
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: AppMotion.of(context, AppMotion.medium),
              width: 46,
              height: 40,
              color: background,
              child: Icon(widget.icon, size: 16, color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}
