import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/providers/locale_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/routing/app_router.dart';
import 'core/services/realtime_reminder_service.dart';
import 'core/theme/app_theme.dart';
import 'features/reminders/providers/reminder_provider.dart';
import 'l10n/app_localizations.dart';

class HivemindApp extends ConsumerStatefulWidget {
  const HivemindApp({super.key});

  @override
  ConsumerState<HivemindApp> createState() => _HivemindAppState();
}

class _HivemindAppState extends ConsumerState<HivemindApp> {
  late final GoRouter _router;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<Uri>? _linkSub;
  final _appLinks = AppLinks();

  @override
  void initState() {
    super.initState();
    _router = AppRouter.createRouter();
    _initRealtimeListeners();
    _initDeepLinkHandling();
  }

  void _initRealtimeListeners() {
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        _startRealtime();
      }

      _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
        if (user != null) {
          _startRealtime();
        } else {
          RealtimeReminderService.stopListening();
        }
      });
    } catch (_) {
      // Ignored in test environment where Firebase is unmocked
    }
  }

  void _initDeepLinkHandling() {
    // Handle link that launched the app (cold start)
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) {
        _handleIncomingLink(uri.toString());
      }
    });

    // Handle links while app is already running (warm start)
    _linkSub = _appLinks.uriLinkStream.listen((uri) {
      _handleIncomingLink(uri.toString());
    });
  }

  Future<void> _handleIncomingLink(String link) async {
    try {
      if (FirebaseAuth.instance.isSignInWithEmailLink(link)) {
        final prefs = await SharedPreferences.getInstance();
        final email = prefs.getString('emailForSignIn');
        if (email == null || email.isEmpty) {
          // Email not found — can't complete sign-in without it
          return;
        }
        await FirebaseAuth.instance.signInWithEmailLink(
          email: email,
          emailLink: link,
        );
        await prefs.remove('emailForSignIn');
        if (mounted) {
          _router.go('/');
        }
      }
    } catch (e) {
      // Sign-in failed — ignore silently; user can retry on login screen
      debugPrint('Email link sign-in error: $e');
    }
  }

  void _startRealtime() {
    RealtimeReminderService.startListening(
      onNewReminder: (reminder) {
        // Automatically refresh reminders list in UI when new reminder arrives
        ref.read(remindersProvider.notifier).refresh();
      },
    );
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _linkSub?.cancel();
    RealtimeReminderService.stopListening();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: 'Hivemind',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: _router,
      locale: currentLocale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
