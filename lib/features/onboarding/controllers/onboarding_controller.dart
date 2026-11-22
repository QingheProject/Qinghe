import 'package:get/get.dart';
import 'package:qinghe_app/app/app_session.dart';
import 'package:qinghe_app/app/routes/app_routes.dart';

/// 开始使用引导的步骤状态。
class OnboardingController extends GetxController {
  OnboardingController(this._session);

  static const stepCount = 4;

  final AppSession _session;
  final step = 0.obs;
  bool _finishing = false;

  /// 最近一次切换的方向：1 为前进，-1 为后退，用于决定进出场方向。
  int direction = 1;

  bool get isLast => step.value == stepCount - 1;
  bool get isFirst => step.value == 0;

  /// 按钮“继续”：最后一步时完成引导。
  void next() {
    if (isLast) {
      finish();
    } else {
      _goTo(step.value + 1);
    }
  }

  /// 滑动前进：最后一步不因误滑而直接离开。
  void swipeNext() {
    if (!isLast) _goTo(step.value + 1);
  }

  void back() {
    if (!isFirst) _goTo(step.value - 1);
  }

  Future<void> finish() async {
    if (_finishing) return;
    _finishing = true;
    if (_session.onboardingCompleted.value) {
      Get.back<void>();
      return;
    }
    await _session.startSetup();
    Get.offAllNamed<void>(AppRoutes.studentProfile, arguments: true);
  }

  Future<void> skip() async {
    if (_finishing) return;
    _finishing = true;
    if (_session.onboardingCompleted.value) {
      Get.back<void>();
      return;
    }
    await _session.completeOnboarding();
    Get.offAllNamed<void>(AppRoutes.shell);
  }

  void _goTo(int target) {
    direction = target > step.value ? 1 : -1;
    step.value = target;
  }
}
