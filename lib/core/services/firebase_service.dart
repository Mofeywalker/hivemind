import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  FirebaseService._();

  static bool _isInitialized = false;

  static Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      await Firebase.initializeApp();
      await _activateAppCheck();
      _isInitialized = true;
      debugPrint('FirebaseService initialized successfully');
    } catch (e) {
      debugPrint('FirebaseService initialization note: $e');
    }
  }

  /// App Check attestation, required by the createHivemind / joinHivemind Cloud
  /// Functions. Release builds use Play Integrity / DeviceCheck. Debug builds
  /// cannot attest, so they use the debug providers whose token must be
  /// registered in the Firebase Console (App Check > Apps > Manage debug
  /// tokens). Pass it at build time to keep the secret out of the repository:
  ///
  ///   `flutter run --dart-define=APP_CHECK_DEBUG_TOKEN=<uuid>`
  ///
  /// Without the define the SDK generates its own token and prints it to logcat.
  static Future<void> _activateAppCheck() async {
    const debugToken = String.fromEnvironment('APP_CHECK_DEBUG_TOKEN');

    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? (debugToken.isEmpty
                ? const AndroidDebugProvider()
                : const AndroidDebugProvider(debugToken: debugToken))
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? (debugToken.isEmpty
                ? const AppleDebugProvider()
                : const AppleDebugProvider(debugToken: debugToken))
          : const AppleDeviceCheckProvider(),
    );
  }

  static bool get isInitialized {
    try {
      return _isInitialized || Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  static FirebaseAuth? get maybeAuth {
    try {
      if (!isInitialized) return null;
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  static FirebaseAuth get auth => FirebaseAuth.instance;

  static FirebaseFirestore get firestore => FirebaseFirestore.instance;

  static User? get currentUser {
    try {
      return maybeAuth?.currentUser;
    } catch (_) {
      return null;
    }
  }

  static String? get currentUserId => currentUser?.uid;

  static bool get isAuthenticated => currentUser != null;
}
