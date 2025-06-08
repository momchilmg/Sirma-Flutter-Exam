import 'dart:developer';
import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    tz.initializeTimeZones();
    if (!Platform.isWindows) {
      String? timeZoneName = await FlutterTimezone.getLocalTimezone();
      timeZoneName = timeZoneName.replaceAll('Kiev', 'Kyiv'); //need to corect name of the city
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launch');
    const settings = InitializationSettings(android: android);

    final androidPlugin = _notificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    final isGranted = await androidPlugin?.requestNotificationsPermission();
    if (isGranted == false) {
      await Permission.notification.request();
    }

    await _notificationsPlugin.initialize(settings);
  }

  static Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledTime,
    required int id,
  }) async {
    await _notificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      tz.TZDateTime.from(scheduledTime.toLocal(), tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'calendar_event_channel',
          'Calendar Event Notifications',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: null,
      payload: scheduledTime.toLocal().toIso8601String(),
    );
  }

  //for debugging - DEBUG CONSOLE in VSCode
  static Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    final pending = await _notificationsPlugin.pendingNotificationRequests();
    log('Pending notifications: ${pending.length}');
    for (var p in pending) {
      log('  - ID: ${p.id}, Title: ${p.title}, Body: ${p.body}, Payload: ${p.payload}');
    }
    return pending;
  }
}
