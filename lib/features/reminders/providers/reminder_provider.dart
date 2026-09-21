import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/locale_provider.dart';
import '../../../core/services/firebase_service.dart';
import '../../hiveminds/providers/hivemind_provider.dart';
import '../data/reminder_repository.dart';
import '../domain/reminder_model.dart';

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  final currentLocale = ref.watch(localeProvider);
  return ReminderRepository(localeGetter: () => currentLocale);
});

class RemindersNotifier extends StateNotifier<AsyncValue<List<Reminder>>> {
  final ReminderRepository _repo;
  final String? _hivemindId;
  StreamSubscription<List<Reminder>>? _streamSub;

  // In-memory cache by hivemind ID for zero-flicker stale-while-revalidate loading
  static final Map<String, List<Reminder>> _memoryCache = {};

  RemindersNotifier(this._repo, this._hivemindId)
      : super(
          _hivemindId != null && _memoryCache.containsKey(_hivemindId)
              ? AsyncValue.data(_memoryCache[_hivemindId]!)
              : const AsyncValue.loading(),
        ) {
    _init();
  }

  Future<void> _init() async {
    if (_hivemindId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    try {
      final initialData = await _repo.getReminders(_hivemindId);
      _memoryCache[_hivemindId] = initialData;
      if (mounted) {
        state = AsyncValue.data(initialData);
      }
    } catch (e, st) {
      // Suppress index-building errors (failed-precondition) — treat as empty list
      // while Firestore finishes building the composite index.
      final isIndexBuilding = e.toString().contains('failed-precondition') ||
          e.toString().contains('requires an index');
      if (mounted) {
        if (isIndexBuilding || _memoryCache.containsKey(_hivemindId)) {
          state = AsyncValue.data(_memoryCache[_hivemindId] ?? []);
        } else {
          state = AsyncValue.error(e, st);
        }
      }
    }

    _streamSub = _repo.streamReminders(_hivemindId).listen(
      (reminders) {
        _memoryCache[_hivemindId] = reminders;
        if (mounted) {
          state = AsyncValue.data(reminders);
        }
      },
      onError: (err, st) {
        // Suppress index-building errors on the stream — data will arrive once built
        final isIndexBuilding = err.toString().contains('failed-precondition') ||
            err.toString().contains('requires an index');
        if (!isIndexBuilding && mounted && !_memoryCache.containsKey(_hivemindId)) {
          state = AsyncValue.error(err, st);
        }
      },
    );
  }

  Future<void> refresh() async {
    if (_hivemindId == null) return;
    try {
      final fresh = await _repo.getReminders(_hivemindId);
      _memoryCache[_hivemindId] = fresh;
      if (mounted) {
        state = AsyncValue.data(fresh);
      }
    } catch (e, st) {
      if (mounted && !_memoryCache.containsKey(_hivemindId)) {
        state = AsyncValue.error(e, st);
      }
    }
  }

  void removeOptimistically(List<String> ids) {
    final currentList = state.value;
    if (currentList == null) return;
    final idSet = ids.toSet();
    final updated = currentList.where((r) => !idSet.contains(r.id)).toList();
    if (_hivemindId != null) {
      _memoryCache[_hivemindId] = updated;
    }
    state = AsyncValue.data(updated);
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}

final remindersProvider = StateNotifierProvider<RemindersNotifier, AsyncValue<List<Reminder>>>((ref) {
  final activeHivemind = ref.watch(activeHivemindProvider);
  final repo = ref.watch(reminderRepositoryProvider);
  return RemindersNotifier(repo, activeHivemind?.id);
});

final remindersStreamProvider = remindersProvider;

enum ReminderSection {
  today,
  tomorrow,
  upcoming,
  recurring,
  completed,
}

final remindersGroupedProvider = Provider<Map<ReminderSection, List<Reminder>>>((ref) {
  final remindersAsync = ref.watch(remindersProvider);
  final reminders = remindersAsync.value ?? [];

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final tomorrowStart = todayStart.add(const Duration(days: 1));
  final dayAfterTomorrowStart = todayStart.add(const Duration(days: 2));

  final currentUserId = FirebaseService.currentUserId;

  final Map<ReminderSection, List<Reminder>> map = {
    ReminderSection.today: [],
    ReminderSection.tomorrow: [],
    ReminderSection.upcoming: [],
    ReminderSection.recurring: [],
    ReminderSection.completed: [],
  };

  for (final r in reminders) {
    final bool isCompletedForUser = r.isCompletedByUser(currentUserId);

    if (isCompletedForUser) {
      map[ReminderSection.completed]!.add(r);
    } else if (r.isRecurring) {
      map[ReminderSection.recurring]!.add(r);
    } else if (r.dueAt.isBefore(tomorrowStart)) {
      map[ReminderSection.today]!.add(r);
    } else if (r.dueAt.isBefore(dayAfterTomorrowStart)) {
      map[ReminderSection.tomorrow]!.add(r);
    } else {
      map[ReminderSection.upcoming]!.add(r);
    }
  }

  return map;
});
