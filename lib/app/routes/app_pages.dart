import 'package:get/get.dart';
import 'package:qinghe_app/app/routes/app_routes.dart';
import 'package:qinghe_app/features/onboarding/bindings/onboarding_binding.dart';
import 'package:qinghe_app/features/onboarding/views/onboarding_page.dart';
import 'package:qinghe_app/features/profile/views/appearance_page.dart';
import 'package:qinghe_app/features/shell/bindings/shell_binding.dart';
import 'package:qinghe_app/features/shell/views/app_shell_page.dart';
import 'package:qinghe_app/features/splash/bindings/splash_binding.dart';
import 'package:qinghe_app/features/splash/views/splash_page.dart';

abstract final class AppPages {
  static const _fade = Duration(milliseconds: 420);

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
      transitionDuration: _fade,
    ),
    GetPage<void>(
      name: AppRoutes.shell,
      page: AppShellPage.new,
      binding: ShellBinding(),
      transition: Transition.fadeIn,
      transitionDuration: _fade,
    ),
    GetPage<void>(
      name: AppRoutes.appearance,
      page: AppearancePage.new,
      transition: Transition.rightToLeft,
      transitionDuration: const Duration(milliseconds: 180),
    ),
  ];
}
