import 'package:get/get.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/app_session.dart';
import 'package:qinghe_app/app/routes/app_routes.dart';

/// 启动页：并行完成本地准备工作与开场动画，二者都结束后离开。
class SplashController extends GetxController {
  SplashController(this._session, this._appearance);

  final AppSession _session;
  final AppearanceController _appearance;
  late final Future<void> _ready;
  bool _leaving = false;

  @override
  void onInit() {
    super.onInit();
    _ready = _prepare();
  }

  Future<void> _prepare() async {
    await Future.wait([_session.load(), _appearance.load()]);
  }

  /// 开场动画结束时调用；重复调用只会跳转一次。
  Future<void> leave() async {
    if (_leaving) return;
    _leaving = true;
    await _ready;
    Get.offAllNamed<void>(
      _session.onboardingCompleted.value
          ? AppRoutes.shell
          : AppRoutes.onboarding,
    );
  }
}
