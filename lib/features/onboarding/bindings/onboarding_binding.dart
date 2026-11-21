import 'package:get/get.dart';
import 'package:qinghe_app/app/app_session.dart';
import 'package:qinghe_app/features/onboarding/controllers/onboarding_controller.dart';

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OnboardingController>(
      () => OnboardingController(Get.find<AppSession>()),
    );
  }
}
