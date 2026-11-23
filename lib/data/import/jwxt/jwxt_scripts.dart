import 'package:qinghe_app/data/sources/school_source.dart';

/// 在教务系统页面里执行的取数脚本。
///
/// 脚本使用页面自己的登录状态发起同源请求，然后把结果交回应用，因此应用既不
/// 读取也不保存学校的登录凭证。回调通道按平台自动选择：安卓使用注入的
/// `QingheJwxt` 对象，Windows 使用 WebView2 的 `window.chrome.webview`。
///
/// 两个请求都用 XMLHttpRequest 而不是 fetch：教务系统的移动端接口会跟随
/// 跨站重定向，fetch 在那种情况下只会抛出一个含糊的网络错误，XHR 则能拿到
/// 状态码，便于把「登录失效」和「接口变化」区分开。
abstract final class JwxtScripts {
  /// 安卓 WebView 里注册的回调通道名。
  static const channel = 'QingheJwxt';

  /// 单个请求的超时时间，略小于控制器等待回调的时间。
  static const requestTimeoutMillis = 20000;

  static const _prelude =
      '''
function qinghePost(payload) {
  var text = JSON.stringify(payload);
  try {
    if (window.QingheJwxt && window.QingheJwxt.postMessage) {
      window.QingheJwxt.postMessage(text);
      return;
    }
  } catch (error) {}
  try {
    if (window.chrome && window.chrome.webview &&
        window.chrome.webview.postMessage) {
      window.chrome.webview.postMessage(text);
    }
  } catch (error) {}
}

function qingheRequest(method, url, body, onText) {
  var request = new XMLHttpRequest();
  request.open(method, url, true);
  request.timeout = $requestTimeoutMillis;
  request.setRequestHeader("Accept", "application/json, text/javascript, */*; q=0.01");
  request.setRequestHeader("X-Requested-With", "XMLHttpRequest");
  if (body !== null) {
    request.setRequestHeader(
      "Content-Type", "application/x-www-form-urlencoded; charset=UTF-8");
  }
  request.onload = function () {
    if (request.status !== 200) {
      qinghePost({ kind: "error", status: request.status });
      return;
    }
    onText(request.responseText);
  };
  request.onerror = function () {
    qinghePost({ kind: "error", status: request.status, reason: "network" });
  };
  request.ontimeout = function () {
    qinghePost({ kind: "error", status: 0, reason: "timeout" });
  };
  request.send(body);
}
''';

  /// 读取课表页上的学年与学期下拉框。
  ///
  /// 只回传这两个下拉框自身的 HTML，不携带页面其它内容。
  static String semesters(SchoolSource source) {
    final search = source.timetablePageQuery.isEmpty
        ? ''
        : '?${source.timetablePageQuery.entries.map((entry) => '${entry.key}=${entry.value}').join('&')}';
    return '''
(function () {
$_prelude
  qingheRequest("GET", "${source.timetablePagePath}$search", null, function (html) {
    var doc = new DOMParser().parseFromString(html, "text/html");
    var selects = doc.querySelectorAll("select");
    var parts = [];
    for (var i = 0; i < selects.length; i++) {
      var select = selects[i];
      if (select.id === "xnm" || select.id === "xqm" ||
          select.name === "xnm" || select.name === "xqm") {
        parts.push(select.outerHTML);
      }
    }
    qinghePost({ kind: "semesters", html: parts.join("") });
  });
})();
''';
  }

  /// 读取指定学年与学期的课表 JSON。
  ///
  /// `kblx=2` 表示按学期取整张课表；`doType=app` 与官方移动端页面一致。
  static String timetable(
    SchoolSource source, {
    required String year,
    required String term,
  }) {
    _requireCode(year);
    _requireCode(term);
    return '''
(function () {
$_prelude
  var body = "xnm=" + encodeURIComponent("$year") +
             "&xqm=" + encodeURIComponent("$term") +
             "&kblx=2&doType=app";
  qingheRequest("POST", "${source.timetableDataPath}", body, function (text) {
    qinghePost({ kind: "timetable", body: text });
  });
})();
''';
  }

  static void _requireCode(String value) {
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      throw const FormatException('学年与学期编码应为数字。');
    }
  }
}
