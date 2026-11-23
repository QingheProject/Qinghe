import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:qinghe_app/data/import/jwxt/jwxt_kb_parser.dart';
import 'package:qinghe_app/data/import/jwxt/jwxt_scripts.dart';
import 'package:qinghe_app/data/import/jwxt/jwxt_semester_options.dart';
import 'package:qinghe_app/data/import/timetable_import.dart';
import 'package:qinghe_app/data/sources/school_source.dart';
import 'package:qinghe_app/features/timetable_import/widgets/jwxt_browser.dart';

/// 教务导入的进度，界面按阶段展示不同操作。
enum JwxtImportStage {
  opening,
  awaitingLogin,
  readingSemesters,
  choosingSemester,
  readingTimetable,
  fetched,
  failed,
}

/// 教务导入流程：打开官方页面 → 用户自行登录 → 读取学期与课表 → 交给导入预览。
///
/// 控制器只通过 [JwxtBrowser] 与页面交互，不持有任何登录凭证。
class JwxtImportController extends GetxController {
  JwxtImportController(this.source);

  final SchoolSource source;

  final stage = JwxtImportStage.opening.obs;
  final error = ''.obs;
  final options = Rx<JwxtSemesterOptions?>(null);
  final year = ''.obs;
  final term = ''.obs;
  final skipped = <String>[].obs;
  final result = Rx<JwxtTimetableParse?>(null);

  JwxtBrowser? _browser;
  Completer<Map<String, dynamic>>? _pending;

  static const _timeout = Duration(seconds: 30);

  bool get canReadSemesters =>
      !isBusy && stage.value != JwxtImportStage.fetched;

  bool get isBusy =>
      stage.value == JwxtImportStage.opening ||
      stage.value == JwxtImportStage.readingSemesters ||
      stage.value == JwxtImportStage.readingTimetable;

  bool get canReadTimetable =>
      !isBusy &&
      options.value != null &&
      year.value.isNotEmpty &&
      term.value.isNotEmpty;

  String get semesterLabel =>
      options.value?.labelOf(year.value, term.value) ?? '';

  void attach(JwxtBrowser browser) {
    _browser = browser;
  }

  @override
  void onClose() {
    _pending = null;
    _browser?.dispose();
    super.onClose();
  }

  Future<void> begin() async {
    final browser = _browser;
    if (browser == null) {
      _fail('当前平台无法打开教务系统页面，请改用 CSV 或 JSON 导入。');
      return;
    }
    error.value = '';
    stage.value = JwxtImportStage.awaitingLogin;
    try {
      await browser.open(source.entry);
    } on Exception {
      _fail('无法打开教务系统页面，请检查网络后重试。');
    }
  }

  Future<void> reload() async {
    final browser = _browser;
    if (browser == null) return;
    error.value = '';
    try {
      await browser.reload();
    } on Exception {
      _fail('页面刷新失败，请重试。');
    }
  }

  /// 读取学年与学期列表，要求用户已经登录。
  Future<void> readSemesters() async {
    if (isBusy) return;
    error.value = '';
    stage.value = JwxtImportStage.readingSemesters;
    try {
      final reply = await _request(JwxtScripts.semesters(source));
      if (reply['kind'] != 'semesters') {
        throw const FormatException('教务系统没有返回学期列表。');
      }
      final parsed = JwxtSemesterOptions.parse('${reply['html'] ?? ''}');
      options.value = parsed;
      year.value = parsed.defaultYear ?? '';
      term.value = parsed.defaultTerm ?? '';
      stage.value = JwxtImportStage.choosingSemester;
    } on FormatException catch (failure) {
      _fail(failure.message);
    } on TimeoutException {
      _fail('读取学期列表超时，请确认已经登录后重试。');
    } on Exception {
      _fail('读取学期列表失败，请重试。');
    }
  }

  /// 按选择的学年与学期读取课表。
  Future<void> readTimetable() async {
    if (isBusy || !canReadTimetable) return;
    error.value = '';
    stage.value = JwxtImportStage.readingTimetable;
    try {
      final reply = await _request(
        JwxtScripts.timetable(source, year: year.value, term: term.value),
      );
      if (reply['kind'] != 'timetable') {
        throw const FormatException('教务系统没有返回课表数据。');
      }
      final parsed = JwxtTimetableParse.parse(
        '${reply['body'] ?? ''}',
        semesterLabel: semesterLabel,
      );
      result.value = parsed;
      skipped.assignAll(parsed.skipped);
      stage.value = JwxtImportStage.fetched;
    } on FormatException catch (failure) {
      _fail(failure.message);
    } on TimeoutException {
      _fail('读取课表超时，请重新登录后重试。');
    } on Exception {
      _fail('读取课表失败，请重试。');
    }
  }

  /// 把读到的课表交给现有的导入预览流程。
  TimetableImport? takeDraft() {
    final parsed = result.value;
    if (parsed == null) return null;
    return TimetableImport(parsed.rules);
  }

  /// WebView 回传的消息入口。
  void handleMessage(String raw) {
    final completer = _pending;
    if (completer == null || completer.isCompleted) return;
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      return;
    }
    if (decoded is! Map<String, dynamic>) return;
    if (decoded['kind'] == 'error') {
      completer.completeError(FormatException(_requestFailure(decoded)));
      return;
    }
    completer.complete(decoded);
  }

  static String _requestFailure(Map<String, dynamic> reply) {
    if (reply['reason'] == 'timeout') return '教务系统没有响应，请稍后重试。';
    if (reply['reason'] == 'network') return '无法连接教务系统，请检查网络后重试。';
    final status = reply['status'];
    if (status is int && status >= 300 && status < 400) {
      return '登录状态已失效（HTTP $status），请重新登录后重试。';
    }
    return '教务系统返回 HTTP $status，请稍后重试。';
  }

  Future<Map<String, dynamic>> _request(String script) async {
    final browser = _browser;
    if (browser == null) throw const FormatException('当前平台无法执行取数脚本。');
    final completer = Completer<Map<String, dynamic>>();
    _pending = completer;
    try {
      await browser.run(script);
      return await completer.future.timeout(_timeout);
    } finally {
      if (identical(_pending, completer)) _pending = null;
    }
  }

  void _fail(String message) {
    error.value = message;
    stage.value = JwxtImportStage.failed;
  }
}
