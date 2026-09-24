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
  /// Functions. Release builds use Play Integrity / DeviceCheck; debug builds
  /// use the debug providers, whose tokens must be registered in the Firebase
  /// Console under App Check > Apps > Manage debug tokens.
  static Future<void> _activateAppCheck() async {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
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
