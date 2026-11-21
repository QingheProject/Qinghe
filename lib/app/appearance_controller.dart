import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppearanceThemeMode { system, light, dark }

enum BottomBarStyle { floating, fixed }

enum NavigationContentStyle { icons, labels, iconsAndLabels }

enum ScheduleTextLayout { top, center, bottom, spaced }

enum ScheduleTimeAlignment { top, center, bottom }

enum ScheduleRailTextLayout { periodFirst, timeFirst, sideBySide }

class AppearanceController extends GetxService {
  static const _themeKey = 'appearance_theme';
  static const _accentToneKey = 'appearance_accent_tone';
  static const _courseColorSchemeKey = 'course_color_scheme';
  static const _bottomBarKey = 'bottom_bar_style';
  static const _navigationContentKey = 'navigation_content_style';
  static const _scheduleRowHeightKey = 'schedule_row_height';
  static const _scheduleCardWidthKey = 'schedule_card_width';
  static const _scheduleCardInsetKey = 'schedule_card_inset';
  static const _scheduleVerticalInsetKey = 'schedule_vertical_inset';
  static const _scheduleCardOpacityKey = 'schedule_card_opacity';
  static const _scheduleCourseSaturationKey = 'schedule_course_saturation';
  static const _scheduleBorderWidthKey = 'schedule_border_width';
  static const _scheduleShowBorderKey = 'schedule_show_border';
  static const _scheduleShowTopLineKey = 'schedule_show_top_line';
  static const _scheduleShowLocationKey = 'schedule_show_location';
  static const _scheduleShowTeacherKey = 'schedule_show_teacher';
  static const _scheduleShowTimeKey = 'schedule_show_time';
  static const _scheduleShowCurrentTimeLineKey =
      'schedule_show_current_time_line';
  static const _scheduleShowWeekendKey = 'schedule_show_weekend';
  static const _scheduleShowGridLinesKey = 'schedule_show_grid_lines';
  static const _scheduleTextLayoutKey = 'schedule_text_layout';
  static const _scheduleTimeAlignmentKey = 'schedule_time_alignment';
  static const _scheduleStartTimesKey = 'schedule_start_times';
  static const _schedulePeriodDurationKey = 'schedule_period_duration';
  static const _scheduleRailTextLayoutKey = 'schedule_rail_text_layout';

  static const defaultScheduleStartTimes = [
    '08:00',
    '08:55',
    '10:00',
    '10:55',
    '14:00',
    '14:55',
    '16:00',
    '16:55',
    '19:00',
    '19:55',
  ];

  final themeMode = AppearanceThemeMode.system.obs;
  final accentTone = AppAccentTone.qinghe.obs;
  final courseColorScheme = CourseColorScheme.qinghe.obs;
  final bottomBarStyle = BottomBarStyle.floating.obs;
  final navigationContentStyle = NavigationContentStyle.iconsAndLabels.obs;
  final scheduleRowHeight = 52.0.obs;
  final scheduleCardWidth = 1.0.obs;
  final scheduleCardInset = 2.0.obs;
  final scheduleVerticalInset = 2.0.obs;
  final scheduleCardOpacity = 1.0.obs;
  final scheduleCourseSaturation = 1.0.obs;
  final scheduleBorderWidth = 1.0.obs;
  final scheduleShowBorder = false.obs;
  final scheduleShowTopLine = true.obs;
  final scheduleShowLocation = true.obs;
  final scheduleShowTeacher = false.obs;
  final scheduleShowTime = true.obs;
  final scheduleShowCurrentTimeLine = true.obs;
  final scheduleShowWeekend = true.obs;
  final scheduleShowGridLines = true.obs;
  final scheduleTextLayout = ScheduleTextLayout.spaced.obs;
  final scheduleTimeAlignment = ScheduleTimeAlignment.center.obs;
  final scheduleStartTimes = defaultScheduleStartTimes.toList().obs;
  final schedulePeriodDuration = 45.0.obs;
  final scheduleRailTextLayout = ScheduleRailTextLayout.periodFirst.obs;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    themeMode.value = _readEnum(
      AppearanceThemeMode.values,
      preferences.getString(_themeKey),
      AppearanceThemeMode.system,
    );
    accentTone.value = _readEnum(
      AppAccentTone.values,
      preferences.getString(_accentToneKey),
      AppAccentTone.qinghe,
    );
    courseColorScheme.value = _readEnum(
      CourseColorScheme.values,
      preferences.getString(_courseColorSchemeKey),
      CourseColorScheme.qinghe,
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
    scheduleRowHeight.value = _readDouble(
      preferences,
      _scheduleRowHeightKey,
      fallback: 52,
      minimum: 42,
      maximum: 68,
    );
    scheduleCardWidth.value = _readDouble(
      preferences,
      _scheduleCardWidthKey,
      fallback: 1,
      minimum: 0.72,
      maximum: 1,
    );
    scheduleCardInset.value = _readDouble(
      preferences,
      _scheduleCardInsetKey,
      fallback: 2,
      minimum: 0,
      maximum: 5,
    );
    scheduleVerticalInset.value = _readDouble(
      preferences,
      _scheduleVerticalInsetKey,
      fallback: 2,
      minimum: 0,
      maximum: 8,
    );
    scheduleCardOpacity.value = _readDouble(
      preferences,
      _scheduleCardOpacityKey,
      fallback: 1,
      minimum: 0.7,
      maximum: 1,
    );
    scheduleCourseSaturation.value = _readDouble(
      preferences,
      _scheduleCourseSaturationKey,
      fallback: 1,
      minimum: 0,
      maximum: 1,
    );
    scheduleBorderWidth.value = _readDouble(
      preferences,
      _scheduleBorderWidthKey,
      fallback: 1,
      minimum: 0.5,
      maximum: 2.5,
    );
    scheduleShowBorder.value =
        preferences.getBool(_scheduleShowBorderKey) ?? false;
    scheduleShowTopLine.value =
        preferences.getBool(_scheduleShowTopLineKey) ?? true;
    scheduleShowLocation.value =
        preferences.getBool(_scheduleShowLocationKey) ?? true;
    scheduleShowTeacher.value =
        preferences.getBool(_scheduleShowTeacherKey) ?? false;
    scheduleShowTime.value = preferences.getBool(_scheduleShowTimeKey) ?? true;
    scheduleShowCurrentTimeLine.value =
        preferences.getBool(_scheduleShowCurrentTimeLineKey) ?? true;
    scheduleShowWeekend.value =
        preferences.getBool(_scheduleShowWeekendKey) ?? true;
    scheduleShowGridLines.value =
        preferences.getBool(_scheduleShowGridLinesKey) ?? true;
    scheduleTextLayout.value = _readEnum(
      ScheduleTextLayout.values,
      preferences.getString(_scheduleTextLayoutKey),
      ScheduleTextLayout.spaced,
    );
    scheduleTimeAlignment.value = _readEnum(
      ScheduleTimeAlignment.values,
      preferences.getString(_scheduleTimeAlignmentKey),
      ScheduleTimeAlignment.center,
    );
    final storedStartTimes = preferences.getStringList(_scheduleStartTimesKey);
    if (storedStartTimes != null &&
        storedStartTimes.length == defaultScheduleStartTimes.length &&
        storedStartTimes.every(_isValidTime)) {
      scheduleStartTimes.assignAll(storedStartTimes);
    }
    schedulePeriodDuration.value = _readDouble(
      preferences,
      _schedulePeriodDurationKey,
      fallback: 45,
      minimum: 20,
      maximum: 120,
    );
    scheduleRailTextLayout.value = _readEnum(
      ScheduleRailTextLayout.values,
      preferences.getString(_scheduleRailTextLayoutKey),
      ScheduleRailTextLayout.periodFirst,
    );
  }

  Future<void> setThemeMode(AppearanceThemeMode value) async {
    themeMode.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_themeKey, value.name);
  }

  Future<void> setAccentTone(AppAccentTone value) async {
    accentTone.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_accentToneKey, value.name);
  }

  Future<void> setCourseColorScheme(CourseColorScheme value) async {
    courseColorScheme.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_courseColorSchemeKey, value.name);
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

  void previewScheduleRowHeight(double value) {
    scheduleRowHeight.value = value.clamp(42, 68).toDouble();
  }

  Future<void> setScheduleRowHeight(double value) async {
    previewScheduleRowHeight(value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_scheduleRowHeightKey, scheduleRowHeight.value);
  }

  void previewScheduleCardWidth(double value) {
    scheduleCardWidth.value = value.clamp(0.72, 1).toDouble();
  }

  Future<void> setScheduleCardWidth(double value) async {
    previewScheduleCardWidth(value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_scheduleCardWidthKey, scheduleCardWidth.value);
  }

  void previewScheduleCardInset(double value) {
    scheduleCardInset.value = value.clamp(0, 5).toDouble();
  }

  Future<void> setScheduleCardInset(double value) async {
    previewScheduleCardInset(value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(_scheduleCardInsetKey, scheduleCardInset.value);
  }

  void previewScheduleVerticalInset(double value) {
    scheduleVerticalInset.value = value.clamp(0, 8).toDouble();
  }

  Future<void> setScheduleVerticalInset(double value) async {
    previewScheduleVerticalInset(value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(
      _scheduleVerticalInsetKey,
      scheduleVerticalInset.value,
    );
  }

  void previewScheduleCardOpacity(double value) {
    scheduleCardOpacity.value = value.clamp(0.7, 1).toDouble();
  }

  Future<void> setScheduleCardOpacity(double value) async {
    previewScheduleCardOpacity(value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(
      _scheduleCardOpacityKey,
      scheduleCardOpacity.value,
    );
  }

  void previewScheduleCourseSaturation(double value) {
    scheduleCourseSaturation.value = value.clamp(0, 1).toDouble();
  }

  Future<void> setScheduleCourseSaturation(double value) async {
    previewScheduleCourseSaturation(value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(
      _scheduleCourseSaturationKey,
      scheduleCourseSaturation.value,
    );
  }

  void previewScheduleBorderWidth(double value) {
    scheduleBorderWidth.value = value.clamp(0.5, 2.5).toDouble();
  }

  Future<void> setScheduleBorderWidth(double value) async {
    previewScheduleBorderWidth(value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(
      _scheduleBorderWidthKey,
      scheduleBorderWidth.value,
    );
  }

  Future<void> setScheduleShowBorder(bool value) async {
    scheduleShowBorder.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_scheduleShowBorderKey, value);
  }

  Future<void> setScheduleShowTopLine(bool value) async {
    scheduleShowTopLine.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_scheduleShowTopLineKey, value);
  }

  Future<void> setScheduleShowLocation(bool value) async {
    scheduleShowLocation.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_scheduleShowLocationKey, value);
  }

  Future<void> setScheduleShowTeacher(bool value) async {
    scheduleShowTeacher.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_scheduleShowTeacherKey, value);
  }

  Future<void> setScheduleShowTime(bool value) async {
    scheduleShowTime.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_scheduleShowTimeKey, value);
  }

  Future<void> setScheduleShowCurrentTimeLine(bool value) async {
    scheduleShowCurrentTimeLine.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_scheduleShowCurrentTimeLineKey, value);
  }

  Future<void> setScheduleShowWeekend(bool value) async {
    scheduleShowWeekend.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_scheduleShowWeekendKey, value);
  }

  Future<void> setScheduleShowGridLines(bool value) async {
    scheduleShowGridLines.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_scheduleShowGridLinesKey, value);
  }

  Future<void> setScheduleTextLayout(ScheduleTextLayout value) async {
    scheduleTextLayout.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_scheduleTextLayoutKey, value.name);
  }

  Future<void> setScheduleTimeAlignment(ScheduleTimeAlignment value) async {
    scheduleTimeAlignment.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_scheduleTimeAlignmentKey, value.name);
  }

  Future<void> setScheduleStartTimes(List<String> values) async {
    if (values.length != defaultScheduleStartTimes.length ||
        !values.every(_isValidTime)) {
      return;
    }
    scheduleStartTimes.assignAll(values);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setStringList(_scheduleStartTimesKey, values);
  }

  void previewSchedulePeriodDuration(double value) {
    schedulePeriodDuration.value = value.clamp(20, 120).toDouble();
  }

  Future<void> setSchedulePeriodDuration(double value) async {
    previewSchedulePeriodDuration(value);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setDouble(
      _schedulePeriodDurationKey,
      schedulePeriodDuration.value,
    );
  }

  Future<void> setScheduleRailTextLayout(ScheduleRailTextLayout value) async {
    scheduleRailTextLayout.value = value;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_scheduleRailTextLayoutKey, value.name);
  }

  T _readEnum<T extends Enum>(List<T> values, String? name, T fallback) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  double _readDouble(
    SharedPreferences preferences,
    String key, {
    required double fallback,
    required double minimum,
    required double maximum,
  }) {
    final stored = preferences.get(key);
    if (stored is! num) return fallback;
    return stored.toDouble().clamp(minimum, maximum).toDouble();
  }

  bool _isValidTime(String value) {
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
    if (match == null) return false;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    return hour < 24 && minute < 60;
  }
}

String calculateScheduleEndTime(String startTime, int durationMinutes) {
  final parts = startTime.split(':');
  if (parts.length != 2) return startTime;
  final hourValue = int.tryParse(parts[0]);
  final minuteValue = int.tryParse(parts[1]);
  if (hourValue == null || minuteValue == null) return startTime;
  final startMinutes = hourValue * 60 + minuteValue;
  final endMinutes = (startMinutes + durationMinutes) % (24 * 60);
  final hour = endMinutes ~/ 60;
  final minute = endMinutes % 60;
  return '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';
}

extension AppearanceThemeModeValue on AppearanceThemeMode {
  ThemeMode get materialMode => switch (this) {
    AppearanceThemeMode.system => ThemeMode.system,
    AppearanceThemeMode.light => ThemeMode.light,
    AppearanceThemeMode.dark => ThemeMode.dark,
  };
}
