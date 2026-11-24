import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 上课提醒的设置：提前多少分钟提醒，0 表示关闭。
class ReminderController extends GetxController {
  static const _key = 'course_reminder_lead_minutes_v1';
  static const defaultLeadMinutes = 15;

  /// 0 表示不提醒。
  final leadMinutes = defaultLeadMinutes.obs;

  bool get enabled => leadMinutes.value > 0;

  String get summary => enabled ? '课前 ${leadMinutes.value} 分钟提醒' : '已关闭';

  @override
  void onInit() {
    super.onInit();
    load();
  }

  Future<void> load() async {
    final store = await SharedPreferences.getInstance();
    final stored = store.getInt(_key);
    if (stored != null && stored >= 0) {
      leadMinutes.value = stored;
    }
  }

  Future<void> setLeadMinutes(int minutes) async {
    if (minutes < 0) return;
    leadMinutes.value = minutes;
    final store = await SharedPreferences.getInstance();
    await store.setInt(_key, minutes);
  }
}
