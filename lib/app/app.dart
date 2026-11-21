import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/appearance_controller.dart';
import 'package:qinghe_app/app/app_binding.dart';
import 'package:qinghe_app/app/routes/app_pages.dart';
import 'package:qinghe_app/app/routes/app_routes.dart';
import 'package:qinghe_app/app/theme/app_theme.dart';
import 'package:qinghe_app/app/widgets/desktop_window_frame.dart';

class QingheApp extends StatefulWidget {
  const QingheApp({super.key});

  @override
  State<QingheApp> createState() => _QingheAppState();
}

class _QingheAppState extends State<QingheApp> {
  late final AppearanceController _appearance;
  late final AppBinding _binding;

  @override
  void initState() {
    super.initState();
    _appearance = AppearanceController();
    _binding = AppBinding(_appearance);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GetMaterialApp(
        title: '青禾',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightFor(_appearance.accentTone.value),
        darkTheme: AppTheme.darkFor(_appearance.accentTone.value),
        themeMode: _appearance.themeMode.value.materialMode,
        initialBinding: _binding,
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
            child: DesktopWindowFrame(child: child ?? const SizedBox.shrink()),
          );
        },
      ),
    );
  }
}
