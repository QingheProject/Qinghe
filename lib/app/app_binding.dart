import 'package:get/get.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/app_session.dart';
import 'package:qinghe_app/app/reminder_controller.dart';
import 'package:qinghe_app/app/student_profile_controller.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:qinghe_app/services/notifications/course_notifications.dart';

/// 应用启动时装配的全局依赖。
class AppBinding extends Bindings {
  AppBinding(this.appearance);

  final AppearanceController appearance;

  @override
  void dependencies() {
    Get
      ..put(appearance, permanent: true)
      ..put(AppSession(), permanent: true)
      ..put(StudentProfileController(), permanent: true)
      ..put(LocalTimetableRepository(), permanent: true)
      ..put(ReminderController(), permanent: true)
      ..put(CourseNotifications(), permanent: true);
  }
}
