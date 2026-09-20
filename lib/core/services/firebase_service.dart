import 'package:cloud_firestore/cloud_firestore.dart';
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
      _isInitialized = true;
      debugPrint('FirebaseService initialized successfully');
    } catch (e) {
      debugPrint('FirebaseService initialization note: $e');
    }
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
