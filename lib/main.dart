import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/services/fcm_service.dart';
import 'core/services/firebase_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/timezone_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Core Services concurrently for lightning-fast cold start
  await Future.wait([
    TimezoneService.initialize(),
    FirebaseService.initialize(),
    NotificationService.initialize(),
    FcmService.initialize(),
  ]);

  runApp(const ProviderScope(child: HivemindApp()));
}
