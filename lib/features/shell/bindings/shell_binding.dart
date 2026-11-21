import 'package:get/get.dart';
import 'package:qinghe_app/data/repositories/sample_timetable_repository.dart';
import 'package:qinghe_app/features/home/controllers/home_controller.dart';
import 'package:qinghe_app/features/shell/controllers/shell_controller.dart';

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    Get
      ..lazyPut<ShellController>(ShellController.new)
      ..lazyPut<HomeController>(
        () => HomeController(Get.find<SampleTimetableRepository>()),
      );
  }
}
