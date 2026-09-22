import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';
import 'timezone_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
    await TimezoneService.initialize();
    await NotificationService.initialize();

    debugPrint('FCM background message received: ${message.messageId}');

    final data = message.data;
    final reminderId = data['reminder_id'] ?? data['id'];
    final title = data['title'] ?? message.notification?.title;
    final notes = data['notes'] ?? message.notification?.body;
    final rawDueAt = data['due_at']?.toString();

    if (reminderId != null && title != null && rawDueAt != null && rawDueAt.isNotEmpty) {
      final dueAt = DateTime.tryParse(rawDueAt);
      if (dueAt != null && dueAt.isAfter(DateTime.now())) {
        await NotificationService.scheduleReminder(
          id: reminderId.hashCode,
          title: title.toString(),
          body: notes?.toString(),
          scheduledDate: dueAt,
          payload: reminderId.toString(),
        );
        debugPrint('Scheduled background reminder #$reminderId for $dueAt');
      }
    }
  } catch (e) {
    debugPrint('Error in FCM background handler: $e');
  }
}

class FcmService {
  FcmService._();

  static bool _isInitialized = false;

  static Future<void> initialize({
    void Function(String reminderId)? onReminderTap,
  }) async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp();
      _isInitialized = true;
      debugPrint('Firebase Core successfully initialized');

      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Launch permissions and token sync in background to unblock app startup
      _setupMessagingAsync(onReminderTap);
    } catch (e) {
      debugPrint('Error initializing FcmService: $e');
    }
  }

  static Future<void> _setupMessagingAsync(
    void Function(String reminderId)? onReminderTap,
  ) async {
    try {
      final messaging = FirebaseMessaging.instance;

      // Request notification permissions
      final settings = await messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      debugPrint('FCM authorization status: ${settings.authorizationStatus}');

      // Enable foreground notification presentation on Apple platforms
      if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        await messaging.setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );
      }

      // Fetch FCM Token & sync with Firestore users collection
      await syncCurrentToken();

      // Listen for token updates
      messaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
        syncTokenToFirestore(newToken);
      });

      // Handle messages received while app is in foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('FCM Foreground message received: ${message.data}');
        final notification = message.notification;
        final data = message.data;

        final title = notification?.title ?? data['title'] ?? 'Neuer Reminder';
        final body = notification?.body ?? data['body'] ?? '';
        final reminderId = data['reminder_id'] ?? data['id'];
        final rawDueAt = data['due_at']?.toString();

        NotificationService.showNotification(
          id: (reminderId ?? title).hashCode,
          title: title,
          body: body,
          payload: reminderId?.toString(),
        );

        if (reminderId != null && rawDueAt != null && rawDueAt.isNotEmpty) {
          final dueAt = DateTime.tryParse(rawDueAt);
          if (dueAt != null && dueAt.isAfter(DateTime.now())) {
            NotificationService.scheduleReminder(
              id: reminderId.hashCode,
              title: title,
              body: data['notes']?.toString() ?? body,
              scheduledDate: dueAt,
              payload: reminderId.toString(),
            );
            debugPrint('Scheduled foreground reminder #$reminderId for $dueAt');
          }
        }
      });

      // Handle notification interaction when app is in background
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('FCM notification opened app: ${message.data}');
        final reminderId = message.data['reminder_id'] ?? message.data['id'];
        if (reminderId != null && onReminderTap != null) {
          onReminderTap(reminderId.toString());
        }
      });

      // Handle launch from terminated state
      final initialMessage = await messaging.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('FCM initial message on app launch: ${initialMessage.data}');
        final reminderId = initialMessage.data['reminder_id'] ?? initialMessage.data['id'];
        if (reminderId != null && onReminderTap != null) {
          onReminderTap(reminderId.toString());
        }
      }

      // Automatically sync token whenever Firebase auth state changes (e.g. user signs in)
      FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          syncCurrentToken();
        }
      });
    } catch (e) {
      debugPrint('Error in FCM background setup: $e');
    }
  }

  static Future<void> syncCurrentToken() async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        debugPrint('FCM Token retrieved: $token');
        await syncTokenToFirestore(token);
      }
    } catch (e) {
      debugPrint('Error retrieving FCM token: $e');
    }
  }

  static Future<void> syncTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcm_token': token,
        'email': user.email,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }, SetOptions(merge: true));

      debugPrint('Synced FCM token for user ${user.uid} to Firestore');
    } catch (e) {
      debugPrint('Error syncing FCM token to Firestore: $e');
    }
  }
}

