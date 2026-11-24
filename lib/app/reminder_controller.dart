import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 提醒设置：上课提醒与考试提醒各有一个开关和自定义的提前时间。
///
/// 提前时间直接存分钟数，0 表示关闭。
class ReminderController extends GetxController {
  static const _classLeadKey = 'course_reminder_class_lead_v2';
  static const _examLeadKey = 'course_reminder_exam_lead_v2';

  /// 旧版本只存了一个总提前量，读出来迁移到「上课提醒」。
  static const _legacyLeadKey = 'course_reminder_lead_minutes_v1';

  static const defaultClassLeadMinutes = 15;
  static const defaultExamLeadMinutes = 60;

  /// 最多允许提前 2 天。
  static const maxLeadMinutes = 2880;

  final classLeadMinutes = defaultClassLeadMinutes.obs;
  final examLeadMinutes = defaultExamLeadMinutes.obs;

  bool get classEnabled => classLeadMinutes.value > 0;
  bool get examEnabled => examLeadMinutes.value > 0;

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final store = await SharedPreferences.getInstance();
    final classLead = store.getInt(_classLeadKey);
    if (classLead != null && classLead >= 0) {
      classLeadMinutes.value = classLead;
    } else {
      final legacy = store.getInt(_legacyLeadKey);
      if (legacy != null && legacy >= 0) classLeadMinutes.value = legacy;
    }
    final examLead = store.getInt(_examLeadKey);
    if (examLead != null && examLead >= 0) {
      examLeadMinutes.value = examLead;
    }
  }

  Future<void> setClassLeadMinutes(int minutes) async {
    classLeadMinutes.value = _clamp(minutes);
    final store = await SharedPreferences.getInstance();
    await store.setInt(_classLeadKey, classLeadMinutes.value);
  }

  Future<void> setExamLeadMinutes(int minutes) async {
    examLeadMinutes.value = _clamp(minutes);
    final store = await SharedPreferences.getInstance();
    await store.setInt(_examLeadKey, examLeadMinutes.value);
  }

  Future<void> setClassEnabled(bool enabled) => setClassLeadMinutes(
    enabled
        ? (classLeadMinutes.value > 0
              ? classLeadMinutes.value
              : defaultClassLeadMinutes)
        : 0,
  );

  Future<void> setExamEnabled(bool enabled) => setExamLeadMinutes(
    enabled
        ? (examLeadMinutes.value > 0
              ? examLeadMinutes.value
              : defaultExamLeadMinutes)
        : 0,
  );

  /// 0 表示关闭，其余夹在 1 分钟到 2 天之间。
  int _clamp(int minutes) {
    if (minutes <= 0) return 0;
    if (minutes > maxLeadMinutes) return maxLeadMinutes;
    return minutes;
  }
}
