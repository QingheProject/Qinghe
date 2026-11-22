import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 应用级会话状态。
class AppSession extends GetxService {
  static const _onboardingCompletedKey = 'onboarding_completed';
  static const _setupStartedKey = 'setup_started';

  final onboardingCompleted = false.obs;
  bool setupStarted = false;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    onboardingCompleted.value =
        preferences.getBool(_onboardingCompletedKey) ?? false;
    setupStarted = preferences.getBool(_setupStartedKey) ?? false;
  }

  Future<void> startSetup() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_setupStartedKey, true);
    setupStarted = true;
  }

  Future<void> completeOnboarding() async {
    onboardingCompleted.value = true;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_onboardingCompletedKey, true);
  }
}
