import 'package:get/get.dart';
import 'package:qinghe_app/app/routes/app_routes.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/features/onboarding/bindings/onboarding_binding.dart';
import 'package:qinghe_app/features/onboarding/views/onboarding_page.dart';
import 'package:qinghe_app/features/timetable_setup/views/student_profile_page.dart';
import 'package:qinghe_app/features/timetable_setup/views/timetable_import_page.dart';
import 'package:qinghe_app/features/profile/views/appearance_page.dart';
import 'package:qinghe_app/features/profile/views/schedule_appearance_page.dart';
import 'package:qinghe_app/features/shell/bindings/shell_binding.dart';
import 'package:qinghe_app/features/shell/views/app_shell_page.dart';
import 'package:qinghe_app/features/splash/bindings/splash_binding.dart';
import 'package:qinghe_app/features/splash/views/splash_page.dart';

abstract final class AppPages {
  static final routes = <GetPage<void>>[
    GetPage<void>(
      name: AppRoutes.splash,
      page: SplashPage.new,
      binding: SplashBinding(),
    ),
    GetPage<void>(
      name: AppRoutes.onboarding,
      page: OnboardingPage.new,
      binding: OnboardingBinding(),
      transition: Transition.fadeIn,
      transitionDuration: AppMotion.medium,
    ),
    GetPage<void>(
      name: AppRoutes.shell,
      page: AppShellPage.new,
      binding: ShellBinding(),
      transition: Transition.fadeIn,
      transitionDuration: AppMotion.medium,
    ),
    GetPage<void>(
      name: AppRoutes.appearance,
      page: AppearancePage.new,
      transition: Transition.rightToLeft,
      transitionDuration: AppMotion.medium,
    ),
    GetPage<void>(
      name: AppRoutes.scheduleAppearance,
      page: ScheduleAppearancePage.new,
      transition: Transition.rightToLeft,
      transitionDuration: AppMotion.medium,
    ),
    GetPage<void>(
      name: AppRoutes.studentProfile,
      page: () => StudentProfilePage(firstRun: Get.arguments == true),
      transition: Transition.rightToLeft,
      transitionDuration: AppMotion.medium,
    ),
    GetPage<void>(
      name: AppRoutes.timetableImport,
      page: () => TimetableImportPage(firstRun: Get.arguments == true),
      transition: Transition.rightToLeft,
      transitionDuration: AppMotion.medium,
    ),
  ];
}
