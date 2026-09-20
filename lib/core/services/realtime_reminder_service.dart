import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../utils/reminder_time_formatter.dart';
import 'notification_service.dart';

class RealtimeReminderService {
  RealtimeReminderService._();

  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  static bool _isListening = false;
  static bool _initialLoadDone = false;
  static final Set<String> _recentlyNotifiedIds = <String>{};

  static void startListening({void Function(Map<String, dynamic> newReminder)? onNewReminder}) {
    if (_isListening) return;

    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) return;

    try {
      _initialLoadDone = false;

      _subscription = FirebaseFirestore.instance
          .collection('reminders')
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
        debugPrint('RealtimeReminderService stream error: $error');
      });

      _isListening = true;
    } catch (e) {
      debugPrint('Error starting RealtimeReminderService: $e');
    }
  }

  static void stopListening() {
    if (!_isListening) return;
    try {
      _subscription?.cancel();
      _subscription = null;
      _isListening = false;
      _initialLoadDone = false;
    } catch (e) {
      debugPrint('Error stopping RealtimeReminderService: $e');
    }
  }
}
