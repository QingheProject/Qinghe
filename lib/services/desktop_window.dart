import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// 桌面端窗口集成：无边框窗口、自绘标题栏所需的窗口控制。
///
/// 只在 Windows 与 Linux 生效；安卓与测试环境调用任何方法都安全返回。
abstract final class DesktopWindow {
  /// 首屏尺寸与最小尺寸，避免课表列宽被压到无法阅读。
  static const defaultSize = Size(1180, 800);
  static const minimumSize = Size(760, 560);

  static bool _initialized = false;

  static bool get isSupported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.windows ||
          defaultTargetPlatform == TargetPlatform.linux);

  /// 隐藏系统标题栏并显示窗口，之后由 [DesktopTitleBar] 负责拖拽与控制。
  static Future<void> initialize() async {
    if (!isSupported || _initialized) return;
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: defaultSize,
      minimumSize: minimumSize,
      center: true,
      title: '青禾',
      titleBarStyle: TitleBarStyle.hidden,
      backgroundColor: Colors.transparent,
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    _initialized = true;
  }

  static Future<void> startDragging() async {
    if (!_initialized) return;
    await windowManager.startDragging();
  }

  static Future<void> minimize() async {
    if (!_initialized) return;
    await windowManager.minimize();
  }

  static Future<void> close() async {
    if (!_initialized) return;
    await windowManager.close();
  }

  static Future<bool> isMaximized() async {
    if (!_initialized) return false;
    return windowManager.isMaximized();
  }

  static Future<void> toggleMaximize() async {
    if (!_initialized) return;
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }

  static void addListener(WindowListener listener) {
    if (!_initialized) return;
    windowManager.addListener(listener);
  }

  static void removeListener(WindowListener listener) {
    if (!_initialized) return;
    windowManager.removeListener(listener);
  }
}
