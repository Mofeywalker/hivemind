import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/utils/recurrence_util.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/reminder_model.dart';

class ReminderRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final Locale? Function()? localeGetter;

  // In-memory cache of scheduled reminder IDs and their target timestamps
  // Prevents redundant platform-channel invocations on every list refresh or stream event
  static final Map<String, int> _scheduledReminderTimestamps = {};
  static final Set<String> _cancelledReminderIds = {};

  ReminderRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    this.localeGetter,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance;

  String _getLocalizedDueBody() {
    try {
      final preferred = localeGetter?.call();
      final locale =
          preferred ?? WidgetsBinding.instance.platformDispatcher.locale;
      final l10n = lookupAppLocalizations(locale);
      return l10n.reminderIsDue;
    } catch (_) {
      return 'Erinnerung ist fällig';
    }
  }

  Future<List<Reminder>> getReminders(String hivemindId) async {
    final snapshot = await _firestore
        .collection('reminders')
        .where('hivemind_id', isEqualTo: hivemindId)
        .orderBy('due_at', descending: false)
        .get();

    final list = snapshot.docs
        .map((doc) => Reminder.fromJson({...doc.data(), 'id': doc.id}))
        .toList();

    _syncLocalNotifications(list);
    return list;
  }

  Stream<List<Reminder>> streamReminders(String hivemindId) {
    return _firestore
        .collection('reminders')
        .where('hivemind_id', isEqualTo: hivemindId)
        .orderBy('due_at', descending: false)
        .snapshots()
        .map((snapshot) {
          final reminders = snapshot.docs
              .map((doc) => Reminder.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
          _syncLocalNotifications(reminders);
          return reminders;
        });
  }

  Future<Reminder> createReminder({
    required String hivemindId,
    required String title,
    String? notes,
    required DateTime dueAt,
    String? rrule,
    ReminderCompletionScope completionScope = ReminderCompletionScope.anyone,
    String? assignedTo,
  }) async {
    final userId = _auth.currentUser?.uid;
    final docRef = _firestore.collection('reminders').doc();
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final reminderData = {
      'id': docRef.id,
      'hivemind_id': hivemindId,
      'title': title.trim(),
      'notes': notes?.trim(),
      'due_at': dueAt.toUtc().toIso8601String(),
      'rrule': rrule,
      'is_completed': false,
      'completed_at': null,
      'completed_by': null,
      'completed_by_ids': <String>[],
      'created_by': userId,
      'completion_scope': completionScope.name,
      'assigned_to': assignedTo,
      'created_at': nowIso,
      'updated_at': nowIso,
    };

    await docRef.set(reminderData);
    final reminder = Reminder.fromJson(reminderData);

    // Schedule local notification on device
    await NotificationService.scheduleReminder(
      id: reminder.id.hashCode,
      title: reminder.title,
      body: (reminder.notes != null && reminder.notes!.trim().isNotEmpty)
          ? reminder.notes
          : _getLocalizedDueBody(),
      scheduledDate: reminder.dueAt,
      payload: reminder.id,
    );

    return reminder;
  }

  Future<Reminder> updateReminder({
    required String reminderId,
    required String title,
    String? notes,
    required DateTime dueAt,
    String? rrule,
    ReminderCompletionScope? completionScope,
    String? assignedTo,
  }) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final Map<String, dynamic> updates = {
      'title': title.trim(),
      'notes': notes?.trim(),
      'due_at': dueAt.toUtc().toIso8601String(),
      'rrule': rrule,
      'updated_at': nowIso,
    };

    if (completionScope != null) {
      updates['completion_scope'] = completionScope.name;
    }
    updates['assigned_to'] = assignedTo;

    final docRef = _firestore.collection('reminders').doc(reminderId);
    await docRef.update(updates);

    final updatedDoc = await docRef.get();
    final reminder = Reminder.fromJson({
      ...?updatedDoc.data(),
      'id': reminderId,
    });

    // Reschedule local notification
    await NotificationService.cancelReminder(reminder.id.hashCode);
    if (!reminder.isCompleted && reminder.dueAt.isAfter(DateTime.now())) {
      await NotificationService.scheduleReminder(
        id: reminder.id.hashCode,
        title: reminder.title,
        body: (reminder.notes != null && reminder.notes!.trim().isNotEmpty)
            ? reminder.notes
            : _getLocalizedDueBody(),
        scheduledDate: reminder.dueAt,
        payload: reminder.id,
      );
    }

    return reminder;
  }

  Future<void> toggleCompletion(
    Reminder reminder, {
    Iterable<String>? hiveMemberUserIds,
  }) async {
    final userId = _auth.currentUser?.uid;
    final List<String> updatedCompletedByIds = List<String>.from(
      reminder.completedByIds,
    );

    final bool allMembersCompleted;

    if (reminder.completionScope == ReminderCompletionScope.anyone) {
      final isCurrentlyCompleted =
          reminder.isCompleted || updatedCompletedByIds.isNotEmpty;
      if (isCurrentlyCompleted) {
        allMembersCompleted = false;
        updatedCompletedByIds.clear();
      } else {
        allMembersCompleted = true;
        if (userId != null) {
          updatedCompletedByIds.add(userId);
        }
      }
    } else if (reminder.completionScope == ReminderCompletionScope.assigned) {
      final assignedId = reminder.assignedTo;
      final isCurrentlyCompleted =
          reminder.isCompleted ||
          (assignedId != null && updatedCompletedByIds.contains(assignedId)) ||
          (userId != null && updatedCompletedByIds.contains(userId));

      if (isCurrentlyCompleted) {
        allMembersCompleted = false;
        if (userId != null) updatedCompletedByIds.remove(userId);
        if (assignedId != null) updatedCompletedByIds.remove(assignedId);
      } else {
        allMembersCompleted = true;
        if (userId != null && !updatedCompletedByIds.contains(userId)) {
          updatedCompletedByIds.add(userId);
        }
        if (assignedId != null && !updatedCompletedByIds.contains(assignedId)) {
          updatedCompletedByIds.add(assignedId);
        }
      }
    } else {
      // ReminderCompletionScope.all: Every member must complete
      final bool isCurrentlyCompletedByUser = userId != null
          ? updatedCompletedByIds.contains(userId)
          : reminder.isCompleted;

      if (userId != null) {
        if (isCurrentlyCompletedByUser) {
          updatedCompletedByIds.remove(userId);
        } else {
          updatedCompletedByIds.add(userId);
        }
      }

      final memberIds =
          hiveMemberUserIds?.toList() ??
          (userId != null ? [userId] : <String>[]);
      allMembersCompleted = memberIds.isNotEmpty
          ? memberIds.every(updatedCompletedByIds.contains)
          : (userId != null
                ? updatedCompletedByIds.contains(userId)
                : !reminder.isCompleted);
    }

    final docRef = _firestore.collection('reminders').doc(reminder.id);

    // Handle Recurring reminder completion
    if (allMembersCompleted && reminder.isRecurring) {
      final nextOccurrence = RecurrenceUtil.getNextOccurrence(
        rruleString: reminder.rrule,
        baseDueAt: reminder.dueAt,
        after: DateTime.now(),
      );

      if (nextOccurrence != null) {
        // Advance due date for next recurrence
        await docRef.update({
          'due_at': nextOccurrence.toUtc().toIso8601String(),
          'is_completed': false,
          'completed_at': null,
          'completed_by': null,
          'completed_by_ids': <String>[],
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });

        await NotificationService.scheduleReminder(
          id: reminder.id.hashCode,
          title: reminder.title,
          body: (reminder.notes != null && reminder.notes!.trim().isNotEmpty)
              ? reminder.notes
              : _getLocalizedDueBody(),
          scheduledDate: nextOccurrence,
          payload: reminder.id,
        );
        return;
      }
    }

    // Standard non-recurring completion
    await docRef.update({
      'is_completed': allMembersCompleted,
      'completed_at': allMembersCompleted
          ? DateTime.now().toUtc().toIso8601String()
          : null,
      'completed_by': updatedCompletedByIds.isNotEmpty
          ? updatedCompletedByIds.last
          : null,
      'completed_by_ids': updatedCompletedByIds,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    });

    if (allMembersCompleted) {
      await NotificationService.cancelReminder(reminder.id.hashCode);
    } else if (reminder.dueAt.isAfter(DateTime.now())) {
      await NotificationService.scheduleReminder(
        id: reminder.id.hashCode,
        title: reminder.title,
        body: (reminder.notes != null && reminder.notes!.trim().isNotEmpty)
            ? reminder.notes
            : _getLocalizedDueBody(),
        scheduledDate: reminder.dueAt,
        payload: reminder.id,
      );
    }
  }

  Future<void> deleteReminder(String id) async {
    await _firestore.collection('reminders').doc(id).delete();
    _scheduledReminderTimestamps.remove(id);
    _cancelledReminderIds.add(id);
    await NotificationService.cancelReminder(id.hashCode);
  }

  Future<void> deleteReminders(List<String> ids) async {
    if (ids.isEmpty) return;
    final batch = _firestore.batch();
    for (final id in ids) {
      batch.delete(_firestore.collection('reminders').doc(id));
    }
    await batch.commit();

    for (final id in ids) {
      _scheduledReminderTimestamps.remove(id);
      _cancelledReminderIds.add(id);
      await NotificationService.cancelReminder(id.hashCode);
    }
  }

  void _syncLocalNotifications(List<Reminder> reminders) {
    try {
      final defaultBody = _getLocalizedDueBody();
      final now = DateTime.now();

      for (final r in reminders) {
        final targetMs = r.dueAt.millisecondsSinceEpoch;

        if (!r.isCompleted && r.dueAt.isAfter(now)) {
          if (_scheduledReminderTimestamps[r.id] == targetMs) {
            continue;
          }

          _scheduledReminderTimestamps[r.id] = targetMs;
          _cancelledReminderIds.remove(r.id);

          NotificationService.scheduleReminder(
            id: r.id.hashCode,
            title: r.title,
            body: (r.notes != null && r.notes!.trim().isNotEmpty)
                ? r.notes
                : defaultBody,
            scheduledDate: r.dueAt,
            payload: r.id,
          );
        } else if (r.isCompleted) {
          if (_cancelledReminderIds.contains(r.id) &&
              !_scheduledReminderTimestamps.containsKey(r.id)) {
            continue;
          }

          _scheduledReminderTimestamps.remove(r.id);
          _cancelledReminderIds.add(r.id);

          NotificationService.cancelReminder(r.id.hashCode);
        }
      }
    } catch (e) {
      debugPrint('Error syncing local notifications: $e');
    }
  }
}
