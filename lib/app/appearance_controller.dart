import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppearanceThemeMode { system, light, dark }

enum BottomBarStyle { floating, fixed }

enum NavigationContentStyle { icons, labels, iconsAndLabels }

class AppearanceController extends GetxService {
  static const _themeKey = 'appearance_theme';
  static const _bottomBarKey = 'bottom_bar_style';
  static const _navigationContentKey = 'navigation_content_style';

  final themeMode = AppearanceThemeMode.system.obs;
  final bottomBarStyle = BottomBarStyle.floating.obs;
  final navigationContentStyle = NavigationContentStyle.iconsAndLabels.obs;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    themeMode.value = _readEnum(
      AppearanceThemeMode.values,
      preferences.getString(_themeKey),
      AppearanceThemeMode.system,
    );
    bottomBarStyle.value = _readEnum(
      BottomBarStyle.values,
      preferences.getString(_bottomBarKey),
      BottomBarStyle.floating,
    );
    navigationContentStyle.value = _readEnum(
      NavigationContentStyle.values,
      preferences.getString(_navigationContentKey),
      NavigationContentStyle.iconsAndLabels,
    );
    Get.changeThemeMode(themeMode.value.materialMode);
  }

  Future<void> setThemeMode(AppearanceThemeMode value) async {
    themeMode.value = value;
    Get.changeThemeMode(value.materialMode);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeKey, value.name);
  }

  Future<void> setBottomBarStyle(BottomBarStyle value) async {
    bottomBarStyle.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_bottomBarKey, value.name);
  }

  Future<void> setNavigationContentStyle(NavigationContentStyle value) async {
    navigationContentStyle.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_navigationContentKey, value.name);
  }

  T _readEnum<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}

extension on AppearanceThemeMode {
  ThemeMode get materialMode => switch (this) {
    AppearanceThemeMode.system => ThemeMode.system,
    AppearanceThemeMode.light => ThemeMode.light,
    AppearanceThemeMode.dark => ThemeMode.dark,
  };
}
