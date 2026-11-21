import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用级会话状态。
class AppSession extends GetxService {
  static const _onboardingCompletedKey = 'onboarding_completed';

  final onboardingCompleted = false.obs;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    onboardingCompleted.value =
        preferences.getBool(_onboardingCompletedKey) ?? false;
  }

  Future<void> completeOnboarding() async {
    onboardingCompleted.value = true;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_onboardingCompletedKey, true);
  }
}
