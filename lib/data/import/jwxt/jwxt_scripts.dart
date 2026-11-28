import 'dart:convert';

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

function qingheRequest(method, url, body, onText, requestId) {
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
      qinghePost({ kind: "error", status: request.status, requestId: requestId });
      return;
    }
    onText(request.responseText);
  };
  request.onerror = function () {
    qinghePost({ kind: "error", status: request.status, reason: "network", requestId: requestId });
  };
  request.ontimeout = function () {
    qinghePost({ kind: "error", status: 0, reason: "timeout", requestId: requestId });
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

  /// 读取指定学年与学期的考试安排。
  ///
  /// 与课表使用同一份学年与学期编码。正方把分页与排序参数放在请求体里，
  /// 因此这里同时带上网格分页参数；某所学校没有配置考试接口时不做请求。
  static String exams(
    SchoolSource source, {
    required String year,
    required String term,
  }) {
    _requireCode(year);
    _requireCode(term);
    final search = [
      for (final entry in source.examDataQuery.entries)
        '${entry.key}=${Uri.encodeQueryComponent(entry.value)}',
    ].join('&');
    final path = search.isEmpty
        ? source.examDataPath
        : '${source.examDataPath}?$search';
    return '''
(function () {
$_prelude
  var body = "xnm=" + encodeURIComponent("$year") +
             "&xqm=" + encodeURIComponent("$term") +
             "&_search=false&queryModel.showCount=200" +
             "&queryModel.currentPage=1" +
             "&queryModel.sortName=&queryModel.sortOrder=asc";
  qingheRequest("POST", "$path", body, function (text) {
    qinghePost({ kind: "exams", body: text });
  });
})();
''';
  }

  /// 使用当前登录会话查询全部成绩，只回传显示和筛选需要的字段。
  static String grades(SchoolSource source, {required int requestId}) {
    return '''
(function () {
$_prelude
  var id = $requestId;
  var origin = ${jsonEncode(source.entry.origin)};
  var path = ${jsonEncode(source.gradeDataPath)};
  if (window.location.origin !== origin) {
    qinghePost({ kind: "error", reason: "login", requestId: id });
    return;
  }

  var result = [];
  var seen = 0;
  function scalar(value) {
    return typeof value === "string" || typeof value === "number" ? value : null;
  }
  function readPage(page) {
    var body = "xnm=&xqm=&_search=false&queryModel.showCount=100" +
      "&queryModel.currentPage=" + page +
      "&queryModel.sortName=&queryModel.sortOrder=asc&time=0";
    qingheRequest("POST", path, body, function (text) {
      var data;
      try { data = JSON.parse(text); } catch (error) {}
      if (!data || !Array.isArray(data.items)) {
        qinghePost({ kind: "error", reason: "gradesFormat", requestId: id });
        return;
      }
      for (var index = 0; index < data.items.length; index++) {
        var row = data.items[index];
        if (!row || typeof row !== "object") continue;
        result.push({
          course: scalar(row.kcmc),
          courseCode: scalar(row.kch || row.kch_id),
          score: scalar(row.cj),
          credit: scalar(row.xf),
          point: scalar(row.jd),
          courseType: scalar(row.kcxzmc),
          examType: scalar(row.ksxzmc || row.ksxz),
          year: scalar(row.xnmmc || row.xnm),
          term: scalar(row.xqmmc),
          termCode: scalar(row.xqm)
        });
      }
      seen += data.items.length;
      var pages = Number(data.totalPage || 0);
      var total = Number(data.totalResult || data.totalCount || 0);
      if ((!data.items.length && (page > 1 || page < pages)) ||
          (pages && page >= pages && total > seen)) {
        qinghePost({ kind: "error", reason: "gradesFormat", requestId: id });
        return;
      }
      if (page < pages || (!pages && seen < total)) {
        if (!data.items.length) {
          qinghePost({ kind: "error", reason: "gradesFormat", requestId: id });
          return;
        }
        readPage(page + 1);
        return;
      }
      qinghePost({ kind: "grades", rows: result, requestId: id });
    }, id);
  }
  readPage(1);
})();
''';
  }

  static void _requireCode(String value) {
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      throw const FormatException('学年与学期编码应为数字。');
    }
  }
}
