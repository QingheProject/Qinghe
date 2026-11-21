import 'package:get/get.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/app_session.dart';
import 'package:qinghe_app/data/repositories/sample_timetable_repository.dart';

/// 应用启动时装配的全局依赖。
class AppBinding extends Bindings {
  AppBinding(this.appearance);

  final AppearanceController appearance;

  @override
  void dependencies() {
    Get
      ..put(appearance, permanent: true)
      ..put(AppSession(), permanent: true)
      ..put(SampleTimetableRepository(), permanent: true);
  }
}
