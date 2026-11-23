import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:qinghe_app/data/import/jwxt/jwxt_scripts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';

/// 打开学校官方登录页并执行取数脚本的最小浏览器接口。
///
/// 只有这里知道 WebView 插件的差异，导入流程本身对平台无感知。
abstract interface class JwxtBrowser {
  Widget get view;

  Future<void> open(Uri uri);

  Future<void> reload();

  /// 执行一段脚本，结果通过 [createJwxtBrowser] 的 `onMessage` 回传。
  Future<void> run(String script);

  Future<void> dispose();
}

/// 创建当前平台可用的浏览器；没有可用 WebView 的平台返回 null。
JwxtBrowser? createJwxtBrowser({required ValueChanged<String> onMessage}) {
  if (Platform.isAndroid) return _AndroidJwxtBrowser(onMessage: onMessage);
  if (Platform.isWindows) return _WindowsJwxtBrowser(onMessage: onMessage);
  return null;
}

class _AndroidJwxtBrowser implements JwxtBrowser {
  _AndroidJwxtBrowser({required ValueChanged<String> onMessage}) {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        JwxtScripts.channel,
        onMessageReceived: (message) => onMessage(message.message),
      );
  }

  late final WebViewController _controller;

  @override
  Widget get view => WebViewWidget(controller: _controller);

  @override
  Future<void> open(Uri uri) => _controller.loadRequest(uri);

  @override
  Future<void> reload() => _controller.reload();

  @override
  Future<void> run(String script) => _controller.runJavaScript(script);

  @override
  Future<void> dispose() async {}
}

class _WindowsJwxtBrowser implements JwxtBrowser {
  _WindowsJwxtBrowser({required ValueChanged<String> onMessage})
    : _onMessage = onMessage;

  final ValueChanged<String> _onMessage;
  final _controller = WebviewController();
  bool _ready = false;

  Future<void> _ensureReady() async {
    if (_ready) return;
    await _controller.initialize();
    _controller.webMessage.listen((message) {
      if (message is String) _onMessage(message);
    });
    _ready = true;
  }

  @override
  Widget get view => Webview(_controller);

  @override
  Future<void> open(Uri uri) async {
    await _ensureReady();
    await _controller.loadUrl(uri.toString());
  }

  @override
  Future<void> reload() async {
    await _ensureReady();
    await _controller.reload();
  }

  @override
  Future<void> run(String script) async {
    await _ensureReady();
    await _controller.executeScript(script);
  }

  @override
  Future<void> dispose() async {
    if (_ready) await _controller.dispose();
  }
}
