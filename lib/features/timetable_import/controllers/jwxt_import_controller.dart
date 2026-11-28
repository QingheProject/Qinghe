import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:qinghe_app/data/import/jwxt/jwxt_exam_parser.dart';
import 'package:qinghe_app/data/import/jwxt/jwxt_grades.dart';
import 'package:qinghe_app/data/import/jwxt/jwxt_import_draft.dart';
import 'package:qinghe_app/data/import/jwxt/jwxt_kb_parser.dart';
import 'package:qinghe_app/data/import/jwxt/jwxt_scripts.dart';
import 'package:qinghe_app/data/import/jwxt/jwxt_semester_options.dart';
import 'package:qinghe_app/data/import/timetable_import.dart';
import 'package:qinghe_app/data/repositories/local_academic_repository.dart';
import 'package:qinghe_app/data/sources/school_source.dart';
import 'package:qinghe_app/features/timetable_import/widgets/jwxt_browser.dart';

/// 教务导入的进度，界面按阶段展示不同操作。
enum JwxtImportStage {
  opening,
  awaitingLogin,
  readingSemesters,
  choosingSemester,
  readingTimetable,
  readingExams,
  readingGrades,
  fetched,
  failed,
}

/// 用户在官方页面登录后，依次读取课表、考试和全部成绩。
///
/// 控制器只通过 [JwxtBrowser] 与页面交互，不持有任何登录凭证。
class JwxtImportController extends GetxController {
  JwxtImportController(this.source, this._academics);

  final SchoolSource source;
  final LocalAcademicRepository _academics;

  final stage = JwxtImportStage.opening.obs;
  final error = ''.obs;
  final options = Rx<JwxtSemesterOptions?>(null);
  final year = ''.obs;
  final term = ''.obs;
  final skipped = <String>[].obs;
  final result = Rx<JwxtTimetableParse?>(null);

  /// 考试读取结果；读取失败时为空，原因放在 [examIssue]。
  final examResult = Rx<JwxtExamParse?>(null);
  final examIssue = ''.obs;
  final examSkipped = <String>[].obs;
  final gradesResult = Rx<JwxtGrades?>(null);
  final gradesIssue = ''.obs;

  JwxtBrowser? _browser;
  Completer<Map<String, dynamic>>? _pending;
  int? _pendingRequestId;
  int _lastRequestId = 0;

  static const _timeout = Duration(seconds: 30);

  bool get isBusy => switch (stage.value) {
    JwxtImportStage.opening ||
    JwxtImportStage.readingSemesters ||
    JwxtImportStage.readingTimetable ||
    JwxtImportStage.readingExams ||
    JwxtImportStage.readingGrades => true,
    _ => false,
  };

  bool get _hasSemester => year.value.isNotEmpty && term.value.isNotEmpty;

  bool get canRead =>
      _browser != null && !isBusy && (options.value == null || _hasSemester);

  String get semesterLabel =>
      options.value?.labelOf(year.value, term.value) ?? '';

  void attach(JwxtBrowser browser) {
    _browser = browser;
  }

  @override
  void onClose() {
    _pending = null;
    _browser?.dispose();
    _browser = null;
    super.onClose();
  }

  Future<void> begin() async {
    final browser = _browser;
    if (browser == null) {
      _fail('当前平台无法打开教务系统页面，请改用 JSON 导入。');
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

  void selectSemester(String? selectedYear, String? selectedTerm) {
    if (isBusy) return;
    final nextYear = selectedYear ?? year.value;
    final nextTerm = selectedTerm ?? term.value;
    if (year.value == nextYear && term.value == nextTerm) return;
    year.value = nextYear;
    term.value = nextTerm;
    result.value = null;
    error.value = '';
    stage.value = JwxtImportStage.choosingSemester;
  }

  /// 首次使用教务页面默认的学期，之后可选择学期重新读取。
  Future<void> readAll() async {
    if (!canRead) return;
    error.value = '';
    result.value = null;
    gradesResult.value = null;
    gradesIssue.value = '';
    if (options.value == null && !await _readSemesters()) return;
    if (_browser == null) return;
    if (!_hasSemester) {
      stage.value = JwxtImportStage.choosingSemester;
      return;
    }

    stage.value = JwxtImportStage.readingTimetable;
    final timetableIssue = await _readTimetable();
    if (_browser == null) return;
    if (timetableIssue == null) {
      stage.value = JwxtImportStage.readingExams;
      await _readExams();
    }
    if (_browser == null) return;
    if (source.hasGrades) {
      stage.value = JwxtImportStage.readingGrades;
      await _readGrades();
    }
    if (_browser == null) return;
    if (timetableIssue != null) {
      _fail(timetableIssue);
    } else {
      stage.value = JwxtImportStage.fetched;
    }
  }

  Future<bool> _readSemesters() async {
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
      return true;
    } on FormatException catch (failure) {
      _fail(failure.message);
    } on TimeoutException {
      _fail('读取学期列表超时，请确认已经登录后重试。');
    } on Exception {
      _fail('读取学期列表失败，请重试。');
    }
    return false;
  }

  Future<String?> _readTimetable() async {
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
      return null;
    } on FormatException catch (failure) {
      return failure.message;
    } on TimeoutException {
      return '读取课表超时，请重新登录后重试。';
    } on Exception {
      return '读取课表失败，请重试。';
    }
  }

  Future<void> _readGrades() async {
    final requestId = ++_lastRequestId;
    try {
      final reply = await _request(
        JwxtScripts.grades(source, requestId: requestId),
        requestId: requestId,
        timeout: const Duration(minutes: 1),
      );
      if (reply['kind'] != 'grades') {
        throw const FormatException('教务系统没有返回成绩数据。');
      }
      final grades = JwxtGrades.parse(reply['rows']);
      gradesResult.value = grades;
      try {
        await _academics.save((
          school: source.school,
          semester: '全部成绩',
          grades: grades,
        ));
      } on Exception {
        gradesIssue.value = '成绩已读取，但本机保存失败。';
      }
    } on FormatException catch (failure) {
      gradesIssue.value = failure.message;
    } on TimeoutException {
      gradesIssue.value = '读取成绩超时，请确认已经登录后重试。';
    } on Exception {
      gradesIssue.value = '读取成绩失败，请重试。';
    }
  }

  /// 读取考试安排。
  ///
  /// 考试是课表的补充信息：读取失败只记录原因，不影响已经读到的上课安排。
  Future<void> _readExams() async {
    examResult.value = null;
    examIssue.value = '';
    examSkipped.clear();
    if (!source.hasExams) return;
    try {
      final reply = await _request(
        JwxtScripts.exams(source, year: year.value, term: term.value),
      );
      if (reply['kind'] != 'exams') {
        throw const FormatException('教务系统没有返回考试数据。');
      }
      final parsed = JwxtExamParse.parse(
        '${reply['body'] ?? ''}',
        semesterLabel: semesterLabel,
      );
      examResult.value = parsed;
      examSkipped.assignAll(parsed.skipped);
    } on FormatException catch (failure) {
      examIssue.value = failure.message;
    } on TimeoutException {
      examIssue.value = '读取考试信息超时，可稍后再试。';
    } on Exception {
      examIssue.value = '读取考试信息失败，可稍后再试。';
    }
  }

  /// 重新单独读取考试安排，用于课表已导入后补考表。
  Future<void> readExamsOnly() async {
    if (isBusy || !source.hasExams) return;
    stage.value = JwxtImportStage.readingExams;
    try {
      await _readExams();
    } finally {
      stage.value = JwxtImportStage.fetched;
    }
  }

  /// 把读到的课表与考试交给现有的导入预览流程。
  JwxtImportDraft? takeDraft() {
    if (stage.value != JwxtImportStage.fetched) return null;
    final parsed = result.value;
    if (parsed == null) return null;
    return JwxtImportDraft(
      table: TimetableImport(parsed.rules),
      exams: examResult.value?.exams ?? const [],
      examIssue: examIssue.value,
      examSkipped: examSkipped,
    );
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
    if (decoded is! Map<String, dynamic> ||
        decoded['requestId'] != _pendingRequestId) {
      return;
    }
    if (decoded['kind'] == 'error') {
      completer.completeError(FormatException(_requestFailure(decoded)));
      return;
    }
    completer.complete(decoded);
  }

  static String _requestFailure(Map<String, dynamic> reply) {
    if (reply['reason'] == 'login') return '请先在学校的官方页面完成登录。';
    if (reply['reason'] == 'gradesFormat') {
      return '成绩接口未返回可识别的数据，请确认已登录且成绩查询已开放。';
    }
    if (reply['reason'] == 'timeout') return '教务系统没有响应，请稍后重试。';
    if (reply['reason'] == 'network') return '无法连接教务系统，请检查网络后重试。';
    final status = reply['status'];
    if (status is int && status >= 300 && status < 400) {
      return '登录状态已失效（HTTP $status），请重新登录后重试。';
    }
    return '教务系统返回 HTTP $status，请稍后重试。';
  }

  Future<Map<String, dynamic>> _request(
    String script, {
    int? requestId,
    Duration timeout = _timeout,
  }) async {
    final browser = _browser;
    if (browser == null) throw const FormatException('当前平台无法执行取数脚本。');
    final completer = Completer<Map<String, dynamic>>();
    _pending = completer;
    _pendingRequestId = requestId;
    try {
      await browser.run(script);
      return await completer.future.timeout(timeout);
    } finally {
      if (identical(_pending, completer)) {
        _pending = null;
        _pendingRequestId = null;
      }
    }
  }

  void _fail(String message) {
    error.value = message;
    stage.value = JwxtImportStage.failed;
  }
}
