import 'package:get/get.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/app_session.dart';
import 'package:qinghe_app/app/student_profile_controller.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:qinghe_app/features/splash/controllers/splash_controller.dart';

class SplashBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SplashController>(
      () => SplashController(
        Get.find<AppSession>(),
        Get.find<AppearanceController>(),
        Get.find<StudentProfileController>(),
        Get.find<LocalTimetableRepository>(),
      ),
    );
  }
}
