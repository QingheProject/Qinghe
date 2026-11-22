import 'package:get/get.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/app_session.dart';
import 'package:qinghe_app/app/routes/app_routes.dart';
import 'package:qinghe_app/app/student_profile_controller.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';

/// 启动页：并行完成本地准备工作与开场动画，二者都结束后离开。
class SplashController extends GetxController {
  SplashController(
    this._session,
    this._appearance,
    this._profile,
    this._timetable,
  );

  final AppSession _session;
  final AppearanceController _appearance;
  final StudentProfileController _profile;
  final LocalTimetableRepository _timetable;
  late final Future<void> _ready;
  bool _leaving = false;

  @override
  void onInit() {
    super.onInit();
    _ready = _prepare();
  }

  Future<void> _prepare() async {
    await Future.wait([
      _session.load(),
      _appearance.load(),
      _profile.load(),
      _timetable.load(),
    ]);
  }

  /// 开场动画结束时调用；重复调用只会跳转一次。
  Future<void> leave() async {
    if (_leaving) return;
    _leaving = true;
    await _ready;
    if (_session.onboardingCompleted.value) {
      Get.offAllNamed<void>(AppRoutes.shell);
    } else if (_session.setupStarted) {
      Get.offAllNamed<void>(AppRoutes.studentProfile, arguments: true);
    } else {
      Get.offAllNamed<void>(AppRoutes.onboarding);
    }
  }
}
