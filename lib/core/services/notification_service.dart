import 'dart:io';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'timezone_service.dart';

class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'hivemind_reminders';
  static const String channelName = 'Hivemind Reminders';
  static const String channelDescription =
      'Notifications for scheduled collaborative Hivemind reminders';

  static const String activityChannelId = 'hivemind_activity';
  static const String activityChannelName = 'Hivemind Activity';
  static const String activityChannelDescription =
      'Notifications for new reminders and group activity';

  static Future<void> initialize({
    void Function(NotificationResponse)? onNotificationTap,
  }) async {
    const androidSettings = AndroidInitializationSettings(
      '@drawable/ic_notification',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _plugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: onNotificationTap,
      );

      if (!kIsWeb && Platform.isAndroid) {
        final androidImpl = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

        const reminderChannel = AndroidNotificationChannel(
          channelId,
          channelName,
          description: channelDescription,
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        );
        await androidImpl?.createNotificationChannel(reminderChannel);

        const activityChannel = AndroidNotificationChannel(
          activityChannelId,
          activityChannelName,
          description: activityChannelDescription,
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
        );
        await androidImpl?.createNotificationChannel(activityChannel);

        // Request permissions asynchronously without blocking the startup frame
        androidImpl
            ?.requestNotificationsPermission()
            .then((_) {
              androidImpl.requestExactAlarmsPermission();
            })
            .catchError((e) {
              debugPrint('Notification permissions request note: $e');
            });
      }
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
    }
  }

  static Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      final androidDetails = AndroidNotificationDetails(
        activityChannelId,
        activityChannelName,
        channelDescription: activityChannelDescription,
        icon: '@drawable/ic_notification',
        color: const Color(0xFFF59E0B),
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: details,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error showing immediate notification #$id: $e');
    }
  }

  static Future<void> scheduleReminder({
    required int id,
    required String title,
    String? body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      final tzScheduled = TimezoneService.fromDateTime(scheduledDate);
      if (tzScheduled.isBefore(
        tz.TZDateTime.now(TimezoneService.localLocation),
      )) {
        return; // Don't schedule past dates
      }

      final androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        icon: '@drawable/ic_notification',
        color: const Color(0xFFF59E0B),
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final details = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      AndroidScheduleMode scheduleMode =
          AndroidScheduleMode.exactAllowWhileIdle;
      if (!kIsWeb && Platform.isAndroid) {
        final androidImpl = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final canExact =
            await androidImpl?.canScheduleExactNotifications() ?? false;
        if (!canExact) {
          scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;
          debugPrint(
            'Exact alarms not permitted. Falling back to inexactAllowWhileIdle for reminder #$id',
          );
        }
      }

      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduled,
        notificationDetails: details,
        androidScheduleMode: scheduleMode,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error scheduling notification #$id: $e');
    }
  }

  static Future<bool> canScheduleExactAlarms() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      return await androidImpl?.canScheduleExactNotifications() ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> requestExactAlarmsPermission() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      await androidImpl?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('Error requesting exact alarms permission: $e');
    }
  }

  static Future<void> cancelReminder(int id) async {
    try {
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('Error cancelling notification #$id: $e');
    }
  }

  static Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Error cancelling all notifications: $e');
    }
  }
}
