import 'dart:ui';

import 'package:alarm/alarm.dart';
import 'package:codebuzzer/models/contest.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class AlarmService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    await Alarm.init();
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_notification');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    // Add the 'settings:' label here
    await flutterLocalNotificationsPlugin.initialize(
      settings: initializationSettings, // This was the missing part
      onDidReceiveNotificationResponse: (details) {
        // Optional: Handle what happens when a user taps the notification
      },
    );
  }

  static Future<bool> checkAllPermissions() async {
    final status = await Permission.notification.status;
    final exact = await Permission.scheduleExactAlarm.status;
    final overlay = await Permission.systemAlertWindow.status;
    final battery = await Permission.ignoreBatteryOptimizations.status;
    return status.isGranted &&
        exact.isGranted &&
        overlay.isGranted &&
        battery.isGranted;
  }

  static Future<void> requestAllPermissions() async {
    // 1. Notifications
    await Permission.notification.request();

    // 2. Exact Alarm (Android 12+)
    await Permission.scheduleExactAlarm.request();

    // 3. System Alert Window (Overlay)
    await Permission.systemAlertWindow.request();

    // 4. Battery Optimization Exemption
    await Permission.ignoreBatteryOptimizations.request();
  }

  static Future<void> scheduleContestAlarm(Contest contest) async {
    final exact = await Permission.scheduleExactAlarm.status;
    if (!exact.isGranted) {
      throw AlarmPermissionException('Exact alarm permission is required to schedule alarms.');
    }

    DateTime notif30 = contest.startTime.subtract(const Duration(minutes: 30));
    DateTime notif10 = contest.startTime.subtract(const Duration(minutes: 10));
    DateTime ring5 = contest.startTime.subtract(const Duration(minutes: 5));
    DateTime exactTime = contest.startTime;

    int alarmId = contest.alarmId;

    Future<void> scheduleNotif(
      DateTime time,
      int idOffset,
      String title,
    ) async {
      try {
        if (time.isAfter(DateTime.now())) {
          await flutterLocalNotificationsPlugin.zonedSchedule(
            id: alarmId + idOffset,
            title: title,
            body: '${contest.name} on ${contest.site}',
            scheduledDate: tz.TZDateTime.from(time, tz.local),
            notificationDetails: const NotificationDetails(
              android: AndroidNotificationDetails(
                'contest_reminder_ch',
                'Contest Reminders',
                channelDescription: 'Reminders for upcoming contests',
                importance: Importance.max,
                priority: Priority.max,
                largeIcon: DrawableResourceAndroidBitmap('ic_notification'),
                color: Color(0xFF1CD065),
                ledColor: Color(0xFF1CD065),
                ledOnMs: 1000,
                ledOffMs: 500,
                category: AndroidNotificationCategory.alarm,
                audioAttributesUsage: AudioAttributesUsage.alarm,
              ),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        }
      } catch (e) {
        print('scheduleNotif error: $e');
      }
    }

    await scheduleNotif(notif30, 1, 'Contest in 30 minutes!');
    await scheduleNotif(notif10, 2, 'Contest in 10 minutes!');
    await scheduleNotif(exactTime, 3, 'Contest is starting now!');

    try {
      if (ring5.isAfter(DateTime.now())) {
        await _setAlarm(alarmId, ring5, contest.name);
      }
    } catch (e) {
      // ignore
    }
  }

  static Future<void> scheduleCustomAlarm(Contest contest) async {
    final exact = await Permission.scheduleExactAlarm.status;
    if (!exact.isGranted) {
      throw AlarmPermissionException('Exact alarm permission is required to schedule alarms.');
    }
    await _setAlarm(
      contest.alarmId,
      contest.startTime,
      contest.name,
      body: contest.description,
    );
  }

  static Future<void> _setAlarm(
    int id,
    DateTime dateTime,
    String title, {
    String body = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();
    String audioPath =
        prefs.getString('custom_alarm_path') ?? 'assets/alarm_music.mp3';

    // If it's a file path (doesn't start with assets/), verify it exists
    if (!audioPath.startsWith('assets/') && !File(audioPath).existsSync()) {
      audioPath = 'assets/alarm_music.mp3';
    }

    final alarmSettings = AlarmSettings(
      id: id,
      dateTime: dateTime,
      assetAudioPath: audioPath,
      loopAudio: true,
      vibrate: true,
      volumeSettings: VolumeSettings.fade(
        volume: 1.0,
        fadeDuration: const Duration(seconds: 3),
        volumeEnforced: false,
      ),
      notificationSettings: NotificationSettings(
        title: title,
        body: body,
        stopButton: 'DISMISS',
        icon: 'ic_notification',
        iconColor: const Color(0xFF1CD065),
      ),
      warningNotificationOnKill: true,
      androidFullScreenIntent: true,
    );
    await Alarm.set(alarmSettings: alarmSettings);
  }

  static Future<void> stopAlarm(int id) async {
    await Alarm.stop(id);
    await flutterLocalNotificationsPlugin.cancel(id: id + 1);
    await flutterLocalNotificationsPlugin.cancel(id: id + 2);
    await flutterLocalNotificationsPlugin.cancel(id: id + 3);
  }
}

class AlarmPermissionException implements Exception {
  final String message;
  AlarmPermissionException(this.message);
  @override
  String toString() => message;
}
