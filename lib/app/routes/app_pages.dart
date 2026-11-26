import 'package:get/get.dart';
import 'package:qinghe_app/app/routes/app_routes.dart';
import 'package:qinghe_app/app/theme/app_motion.dart';
import 'package:qinghe_app/data/sources/school_source.dart';
import 'package:qinghe_app/features/course_edit/views/add_lesson_page.dart';
import 'package:qinghe_app/features/exams/views/exam_list_page.dart';
import 'package:qinghe_app/features/profile/views/reminder_settings_page.dart';
import 'package:qinghe_app/features/onboarding/bindings/onboarding_binding.dart';
import 'package:qinghe_app/features/onboarding/views/onboarding_page.dart';
import 'package:qinghe_app/features/timetable_import/views/jwxt_import_page.dart';
import 'package:qinghe_app/features/timetable_setup/views/json_import_page.dart';
import 'package:qinghe_app/features/timetable_setup/views/school_picker_page.dart';
import 'package:qinghe_app/features/timetable_setup/views/semester_config_page.dart';
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
      name: AppRoutes.schoolPicker,
      page: () => SchoolPickerPage(selected: '${Get.arguments ?? ''}'),
      transition: Transition.rightToLeft,
      transitionDuration: AppMotion.medium,
    ),
    GetPage<void>(
      name: AppRoutes.timetableImport,
      page: () => TimetableImportPage(firstRun: Get.arguments == true),
      transition: Transition.rightToLeft,
      transitionDuration: AppMotion.medium,
    ),
    GetPage<void>(
      name: AppRoutes.reminders,
      page: ReminderSettingsPage.new,
      transition: Transition.rightToLeft,
      transitionDuration: AppMotion.medium,
    ),
    GetPage<void>(
      name: AppRoutes.addLesson,
      page: () {
        final args = Get.arguments;
        if (args is AddLessonArgs) {
          return AddLessonPage(
            weekday: args.weekday,
            period: args.period,
            rule: args.rule,
          );
        }
        return const AddLessonPage(weekday: 1, period: 1);
      },
      transition: Transition.rightToLeft,
      transitionDuration: AppMotion.medium,
    ),
    GetPage<void>(
      name: AppRoutes.jsonImport,
      page: JsonImportPage.new,
      transition: Transition.rightToLeft,
      transitionDuration: AppMotion.medium,
    ),
    GetPage<void>(
      name: AppRoutes.semesterConfig,
      page: () {
        final args = Get.arguments;
        return SemesterConfigPage(
          firstRun: args is SemesterConfigArgs && args.firstRun,
          draft: args is SemesterConfigArgs ? args.draft : null,
          sourceLabel: args is SemesterConfigArgs ? args.label : null,
          exams: args is SemesterConfigArgs ? args.exams : const [],
          examIssue: args is SemesterConfigArgs ? args.examIssue : '',
        );
      },
      transition: Transition.rightToLeft,
      transitionDuration: AppMotion.medium,
    ),
    GetPage<void>(
      name: AppRoutes.exams,
      page: ExamListPage.new,
      transition: Transition.rightToLeft,
      transitionDuration: AppMotion.medium,
    ),
    GetPage<void>(
      name: AppRoutes.jwxtImport,
      page: () => JwxtImportPage(source: Get.arguments as SchoolSource),
      transition: Transition.rightToLeft,
      transitionDuration: AppMotion.medium,
    ),
  ];
}
