import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../utils/reminder_time_formatter.dart';
import 'notification_service.dart';

class RealtimeReminderService {
  RealtimeReminderService._();

  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _hivemindsSub;
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _remindersSub;
  static bool _isListening = false;
  static bool _initialLoadDone = false;
  static final Set<String> _recentlyNotifiedIds = <String>{};
  static List<String> _currentHivemindIds = [];

  static void startListening({void Function(Map<String, dynamic> newReminder)? onNewReminder}) {
    if (_isListening) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      _isListening = true;
      _initialLoadDone = false;

      // Listen to the user's joined Hiveminds to always query permitted reminder documents
      _hivemindsSub = FirebaseFirestore.instance
          .collection('hiveminds')
          .where('member_ids', arrayContains: currentUserId)
          .snapshots()
          .listen((hivemindsSnap) {
        final hivemindIds = hivemindsSnap.docs.map((d) => d.id).toList();
        _updateRemindersSubscription(hivemindIds, currentUserId, onNewReminder);
      }, onError: (err) {
        debugPrint('RealtimeReminderService hiveminds stream error: $err');
      });
    } catch (e) {
      debugPrint('Error starting RealtimeReminderService: $e');
    }
  }

  static void _updateRemindersSubscription(
    List<String> hivemindIds,
    String currentUserId,
    void Function(Map<String, dynamic> newReminder)? onNewReminder,
  ) {
    if (listEquals(_currentHivemindIds, hivemindIds) && _remindersSub != null) {
      return;
    }
    _currentHivemindIds = List<String>.from(hivemindIds);
    _remindersSub?.cancel();
    _remindersSub = null;

    if (hivemindIds.isEmpty) return;

    // Firestore 'whereIn' supports up to 30 elements
    final targetIds = hivemindIds.take(30).toList();

    _remindersSub = FirebaseFirestore.instance
        .collection('reminders')
        .where('hivemind_id', whereIn: targetIds)
        .snapshots()
        .listen((snapshot) {
      // Skip first emission batch to only notify on genuinely new inserts
      if (!_initialLoadDone) {
        _initialLoadDone = true;
        for (final doc in snapshot.docs) {
          _recentlyNotifiedIds.add(doc.id);
        }
        return;
      }

      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;

        final newRecord = change.doc.data();
        if (newRecord == null) continue;

        final reminderId = change.doc.id;
        final createdBy = newRecord['created_by']?.toString();

        // Determine if created by current user or other member
        final isOwn = (createdBy == currentUserId);
        final prefix = isOwn ? 'Erinnerung erstellt' : 'Neuer Reminder';

        if (_recentlyNotifiedIds.contains(reminderId)) {
          continue;
        }
        _recentlyNotifiedIds.add(reminderId);
        Future.delayed(const Duration(seconds: 30), () {
          _recentlyNotifiedIds.remove(reminderId);
        });

        final title = newRecord['title']?.toString() ?? 'Neuer Reminder';
        final rawDueAt = newRecord['due_at']?.toString();
        final rrule = newRecord['rrule']?.toString();

        DateTime dueAt;
        try {
          dueAt = rawDueAt != null ? DateTime.parse(rawDueAt) : DateTime.now();
        } catch (_) {
          dueAt = DateTime.now();
        }

        final timeTrigger = ReminderTimeFormatter.formatTimeTrigger(
          dueAt: dueAt,
          rrule: rrule,
        );

        // Display notification on device
        NotificationService.showNotification(
          id: (reminderId).hashCode,
          title: '$prefix: $title',
          body: timeTrigger,
          payload: reminderId,
        );

        // Schedule the future reminder alarm
        if (dueAt.isAfter(DateTime.now())) {
          NotificationService.scheduleReminder(
            id: (reminderId).hashCode,
            title: title,
            body: newRecord['notes']?.toString() ?? timeTrigger,
            scheduledDate: dueAt,
            payload: reminderId,
          );
        }

        onNewReminder?.call({...newRecord, 'id': reminderId});
      }
    }, onError: (error) {
      debugPrint('RealtimeReminderService reminders stream error: $error');
    });
  }

  static void stopListening() {
    if (!_isListening) return;
    try {
      _hivemindsSub?.cancel();
      _hivemindsSub = null;
      _remindersSub?.cancel();
      _remindersSub = null;
      _currentHivemindIds = [];
      _isListening = false;
      _initialLoadDone = false;
    } catch (e) {
      debugPrint('Error stopping RealtimeReminderService: $e');
    }
  }
}
