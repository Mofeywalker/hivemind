import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/hivemind_repository.dart';
import '../domain/hivemind_member_model.dart';
import '../domain/hivemind_model.dart';

final hivemindRepositoryProvider = Provider<HivemindRepository>((ref) {
  return HivemindRepository();
});

final joinedHivemindsProvider = FutureProvider<List<Hivemind>>((ref) async {
  final repo = ref.watch(hivemindRepositoryProvider);
  return repo.getJoinedHiveminds();
});

final activeHivemindMembersProvider = StreamProvider<List<HivemindMember>>((
  ref,
) {
  final activeHivemind = ref.watch(activeHivemindProvider);
  if (activeHivemind == null) return Stream.value([]);

  final repo = ref.watch(hivemindRepositoryProvider);
  return repo.streamHivemindMembers(activeHivemind.id);
});

final activeHivemindProvider =
    StateNotifierProvider<ActiveHivemindNotifier, Hivemind?>((ref) {
      return ActiveHivemindNotifier(ref);
    });

class ActiveHivemindNotifier extends StateNotifier<Hivemind?> {
  static const String _prefKey = 'last_active_hivemind_id';
  final Ref _ref;

  ActiveHivemindNotifier(this._ref) : super(null) {
    _initDefaultHivemind();
  }

  Future<void> _initDefaultHivemind() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastId = prefs.getString(_prefKey);
      final list = await _ref.read(joinedHivemindsProvider.future);
      if (list.isNotEmpty && state == null) {
        if (lastId != null) {
          final matched = list.where((h) => h.id == lastId);
          if (matched.isNotEmpty) {
            state = matched.first;
            return;
          }
        }
        state = list.first;
      }
    } catch (_) {
      final list = await _ref.read(joinedHivemindsProvider.future);
      if (list.isNotEmpty && state == null) {
        state = list.first;
      }
    }
  }

  void setActive(Hivemind hivemind) {
    state = hivemind;
    SharedPreferences.getInstance()
        .then((prefs) {
          prefs.setString(_prefKey, hivemind.id);
        })
        .catchError((_) {});
  }

  Future<void> refresh() async {
    _ref.invalidate(joinedHivemindsProvider);
    final list = await _ref.read(joinedHivemindsProvider.future);
    if (list.isNotEmpty) {
      if (state == null || !list.any((h) => h.id == state!.id)) {
        state = list.first;
      } else {
        state = list.firstWhere((h) => h.id == state!.id);
      }
      try {
        final prefs = await SharedPreferences.getInstance();
        if (state != null) {
          await prefs.setString(_prefKey, state!.id);
        }
      } catch (_) {}
    } else {
      state = null;
    }
  }

  /// Drops the cached selection without touching the backend. Used on sign-out
  /// so the next account never sees the previous account's active hivemind.
  void clear() {
    state = null;
    _ref.invalidate(joinedHivemindsProvider);
  }
}
