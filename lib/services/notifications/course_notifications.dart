import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:qinghe_app/app/reminder_controller.dart';
import 'package:qinghe_app/data/models/lesson_occurrence.dart';
import 'package:qinghe_app/data/repositories/local_timetable_repository.dart';
import 'package:qinghe_app/services/notifications/reminder_plan.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// 上课提醒与上课中的实时通知。
///
/// 提醒走 flutter_local_notifications 的定时通知；上课中的状态由原生侧用
/// Android 16 的进度样式通知展示，可以在状态栏胶囊 / 锁屏上看到。
class CourseNotifications extends GetxService {
  static const _channelId = 'class_reminder';
  static const _channelName = '上课提醒';
  static const _channelDescription = '课前提醒：课程名、时间与地点';

  static const _liveChannel = MethodChannel('dev.qinghe.qinghe_app/class_live');

  /// 桌面端与 Web 没有这套通知，全部方法直接跳过。
  static bool get supported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS || Platform.isMacOS);

  final _plugin = FlutterLocalNotificationsPlugin();
  Timer? _liveTimer;
  String? _liveSignature;

  @override
  void onInit() {
    super.onInit();
    unawaited(initialize());
  }

  @override
  void onClose() {
    _liveTimer?.cancel();
    super.onClose();
  }

  /// 初始化通知插件与时区，然后申请权限、排一次提醒。
  Future<void> initialize() async {
    if (!supported) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(_localLocation());

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
        macOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    await _requestPermissions();
    await sync();
    _startLiveLoop();
  }

  Future<void> _requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      await android.requestNotificationsPermission();
      await android.requestExactAlarmsPermission();
      return;
    }
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, sound: true);
  }

  /// 按当前课表与提醒设置重排所有提醒（上课 + 考试）。
  Future<void> sync() async {
    if (!supported || !Get.isRegistered<LocalTimetableRepository>()) return;
    final repository = Get.find<LocalTimetableRepository>();
    final settings = Get.isRegistered<ReminderController>()
        ? Get.find<ReminderController>()
        : null;
    if (settings == null) return;

    await _plugin.cancelAll();

    final now = DateTime.now();
    final days = <(DateTime, List<LessonOccurrence>)>[
      for (var index = 0; index < reminderHorizonDays; index++)
        (
          now.add(Duration(days: index)),
          repository.lessonsOn(now.add(Duration(days: index))),
        ),
    ];
    final plan = [
      ...planCourseReminders(
        now: now,
        leadMinutes: settings.classLeadMinutes.value,
        days: days,
      ),
      ...planExamReminders(
        now: now,
        leadMinutes: settings.examLeadMinutes.value,
        exams: repository.active?.exams ?? const [],
      ),
    ]..sort((left, right) => left.when.compareTo(right.when));

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final canScheduleExact =
        await android?.canScheduleExactNotifications() ?? false;

    for (final reminder in plan.take(reminderMaxCount)) {
      await _plugin.zonedSchedule(
        id: reminder.id,
        title: reminder.title,
        body: reminder.body,
        scheduledDate: tz.TZDateTime.from(reminder.when, tz.local),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.high,
            priority: Priority.high,
            category: AndroidNotificationCategory.reminder,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: canScheduleExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  /// 每半分钟看一次有没有正在上的课，用它驱动「上岛」的实时通知。
  void _startLiveLoop() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => unawaited(refreshLive()),
    );
    unawaited(refreshLive());
  }

  /// 有课在进行就更新实时通知，没有就收起。
  Future<void> refreshLive() async {
    if (!supported || !Platform.isAndroid) return;
    if (!Get.isRegistered<LocalTimetableRepository>()) return;
    final repository = Get.find<LocalTimetableRepository>();
    final now = DateTime.now();
    final minuteOfDay = now.hour * 60 + now.minute;
    final ongoing = repository
        .lessonsOn(now)
        .where((lesson) => lesson.statusAt(minuteOfDay) == LessonStatus.ongoing)
        .toList(growable: false);

    if (ongoing.isEmpty) {
      await stopLive();
      return;
    }

    final lesson = ongoing.first;
    final signature = '${lesson.id}|${lesson.startMinute}|${now.day}';
    final elapsed = (minuteOfDay - lesson.startMinute).clamp(
      0,
      lesson.durationMinutes,
    );
    final remaining = lesson.durationMinutes - elapsed;

    try {
      await _liveChannel.invokeMethod<void>('show', {
        'title': lesson.courseName,
        'text': remaining > 0
            ? '第 ${lesson.startPeriod}–${lesson.endPeriod} 节 · 还剩 $remaining 分钟'
            : '第 ${lesson.startPeriod}–${lesson.endPeriod} 节 · 即将下课',
        'shortText': remaining > 0 ? '剩 $remaining 分钟' : '即将下课',
        'progress': elapsed,
        'max': lesson.durationMinutes,
      });
      _liveSignature = signature;
    } on PlatformException {
      // 原生侧不支持（例如旧版本系统）时静默跳过。
    } on MissingPluginException {
      // 桌面端没有实现，忽略。
    }
  }

  /// 预览「上课中」的通知：发一条示例后自动撤回，方便用户在真机上看效果。
  Future<void> previewLive({
    Duration hold = const Duration(seconds: 20),
  }) async {
    if (!supported || !Platform.isAndroid) return;
    try {
      await _liveChannel.invokeMethod<void>('show', {
        'title': '示例课程 · 预览',
        'text': '第 3–4 节 · 还剩 30 分钟',
        'shortText': '剩 30 分钟',
        'progress': 15,
        'max': 45,
      });
    } on PlatformException {
      return;
    } on MissingPluginException {
      return;
    }
    Timer(hold, () => unawaited(stopLive()));
  }

  Future<void> stopLive() async {
    if (!supported || !Platform.isAndroid || _liveSignature == null) return;
    _liveSignature = null;
    try {
      await _liveChannel.invokeMethod<void>('cancel');
    } on PlatformException {
      // 忽略：通知可能已经被系统回收。
    } on MissingPluginException {
      // 忽略。
    }
  }

  /// 用固定的时区偏移构造本地时区，避免为拿时区名再引一个插件。
  tz.Location _localLocation() {
    final offset = DateTime.now().timeZoneOffset;
    if (offset.inMinutes % 60 != 0) return tz.getLocation('UTC');
    final hours = offset.inMinutes ~/ 60;
    if (hours == 0) return tz.getLocation('UTC');
    // Etc/GMT 的符号与常识相反：UTC+8 对应 Etc/GMT-8。
    final name = 'Etc/GMT${hours > 0 ? '-' : '+'}${hours.abs()}';
    try {
      return tz.getLocation(name);
    } on ArgumentError {
      return tz.getLocation('UTC');
    }
  }
}
