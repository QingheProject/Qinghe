import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/app_binding.dart';
import 'package:qinghe_app/app/routes/app_pages.dart';
import 'package:qinghe_app/app/routes/app_routes.dart';
import 'package:qinghe_app/app/theme/app_theme.dart';

class QingheApp extends StatelessWidget {
  const QingheApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: '青禾',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      initialBinding: AppBinding(),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.routes,
      builder: (context, child) {
        final dark = Theme.of(context).brightness == Brightness.dark;
        final overlay = dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: overlay.copyWith(
            statusBarColor: Colors.transparent,
            systemNavigationBarColor: Theme.of(context).colorScheme.surface,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
