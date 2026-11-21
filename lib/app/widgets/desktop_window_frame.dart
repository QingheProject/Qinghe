import 'package:flutter/material.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:qinghe_app/app/widgets/desktop_title_bar.dart';
import 'package:qinghe_app/services/desktop_window.dart';
import 'package:window_manager/window_manager.dart';

/// 在桌面端把整个应用包进自绘标题栏里；其他平台原样返回内容。
class DesktopWindowFrame extends StatefulWidget {
  const DesktopWindowFrame({required this.child, super.key});

  final Widget child;

  @override
  State<DesktopWindowFrame> createState() => _DesktopWindowFrameState();
}

class _DesktopWindowFrameState extends State<DesktopWindowFrame> {
  final _watcher = _MaximizeWatcher();
  bool _maximized = false;

  @override
  void initState() {
    super.initState();
    if (!DesktopWindow.isSupported) return;
    _watcher.onChanged = _syncMaximized;
    DesktopWindow.addListener(_watcher);
    _syncMaximized();
  }

  @override
  void dispose() {
    if (DesktopWindow.isSupported) {
      DesktopWindow.removeListener(_watcher);
    }
    super.dispose();
  }

  Future<void> _syncMaximized() async {
    final maximized = await DesktopWindow.isMaximized();
    if (!mounted || maximized == _maximized) return;
    setState(() => _maximized = maximized);
  }

  Future<void> _toggleMaximize() async {
    await DesktopWindow.toggleMaximize();
    await _syncMaximized();
  }

  @override
  Widget build(BuildContext context) {
    if (!DesktopWindow.isSupported) return widget.child;

    return ColoredBox(
      color: context.colors.canvas,
      child: Column(
        children: [
          DesktopTitleBar(
            maximized: _maximized,
            onStartDrag: () => DesktopWindow.startDragging(),
            onMinimize: () => DesktopWindow.minimize(),
            onToggleMaximize: _toggleMaximize,
            onClose: () => DesktopWindow.close(),
          ),
          Expanded(child: widget.child),
        ],
      ),
    );
  }
}

/// 窗口最大化状态变化时刷新标题栏上的按钮图标。
class _MaximizeWatcher with WindowListener {
  VoidCallback? onChanged;

  @override
  void onWindowMaximize() => onChanged?.call();

  @override
  void onWindowUnmaximize() => onChanged?.call();

  @override
  void onWindowRestore() => onChanged?.call();
}
