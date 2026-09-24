import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../../features/hiveminds/presentation/qr_scanner_screen.dart';
import '../../features/reminders/presentation/timeline_screen.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static GoRouter createRouter() {
    Stream<dynamic>? authStream;
    try {
      authStream = FirebaseAuth.instance.authStateChanges();
    } catch (_) {
      authStream = null;
    }

    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: '/',
      refreshListenable: authStream != null
          ? GoRouterRefreshStream(authStream)
          : null,
      redirect: (BuildContext context, GoRouterState state) {
        User? user;
        try {
          user = FirebaseAuth.instance.currentUser;
        } catch (_) {
          user = null;
        }
        final isLoggingIn = state.matchedLocation == '/login';

        if (user == null && !isLoggingIn) {
          return '/login';
        }

        if (user != null && isLoggingIn) {
          return '/';
        }

        return null;
      },
      routes: [
        GoRoute(path: '/', builder: (context, state) => const TimelineScreen()),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),
        GoRoute(
          path: '/qr-scanner',
          builder: (context, state) => const QrScannerScreen(),
        ),
      ],
    );
  }
}

class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
