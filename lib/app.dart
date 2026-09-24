import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleIncomingLink(uri.toString());
        });
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
        var email = prefs.getString('emailForSignIn');

        // Fallback: prompt the user to confirm their address if the pending
        // sign-in email is gone (fresh install). The link's own query parameters
        // are attacker-controlled and are deliberately not trusted here.
        if (email == null || email.isEmpty) {
          final navContext = AppRouter.navigatorKey.currentContext;
          if (navContext != null && navContext.mounted) {
            email = await _promptEmailForSignIn(navContext);
          }
        }

        if (email == null || email.trim().isEmpty) {
          return;
        }

        final cred = await FirebaseAuth.instance.signInWithEmailLink(
          email: email.trim(),
          emailLink: link,
        );

        if (cred.user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(cred.user!.uid)
              .set({
                'display_name': email.split('@').first,
                'email': email.trim(),
                'created_at': DateTime.now().toUtc().toIso8601String(),
                'updated_at': DateTime.now().toUtc().toIso8601String(),
              }, SetOptions(merge: true));
        }

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

  Future<String?> _promptEmailForSignIn(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('E-Mail bestätigen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Bitte bestätige deine E-Mail-Adresse, um die Anmeldung mit dem Magic Link abzuschließen.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'E-Mail',
                  hintText: 'name@example.com',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: const Text('Abbrechen'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Anmelden'),
            ),
          ],
        );
      },
    );
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
