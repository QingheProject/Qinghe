import 'package:get/get.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:qinghe_app/features/home/controllers/home_controller.dart';
import 'package:qinghe_app/features/schedule/controllers/schedule_controller.dart';
import 'package:qinghe_app/features/shell/controllers/shell_controller.dart';

class ShellBinding extends Bindings {
  @override
  void dependencies() {
    Get
      ..lazyPut<ShellController>(ShellController.new)
      ..lazyPut<HomeController>(
        () => HomeController(Get.find<LocalTimetableRepository>()),
      )
      ..lazyPut<ScheduleController>(
        () => ScheduleController(Get.find<LocalTimetableRepository>()),
      );
  }
}
