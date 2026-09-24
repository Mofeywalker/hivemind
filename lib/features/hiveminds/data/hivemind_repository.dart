import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../domain/hivemind_member_model.dart';
import '../domain/hivemind_model.dart';

/// Membership is server-authoritative. [createHivemind] and [joinByInviteCode]
/// call the Cloud Functions in functions/src/index.ts, which are the only code
/// paths permitted to write `member_ids` (firestore.rules denies every client
/// write of membership). Invite codes are generated, uniquely allocated and
/// verified server-side; they are never readable by non-members.
class HivemindRepository {
  /// Must match the `region` of the callables in functions/src/index.ts, which
  /// is colocated with the Firestore database.
  static const String functionsRegion = 'europe-west3';

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  HivemindRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _functions =
           functions ?? FirebaseFunctions.instanceFor(region: functionsRegion);

  Future<List<Hivemind>> getJoinedHiveminds() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return [];

    final snapshot = await _firestore
        .collection('hiveminds')
        .where('member_ids', arrayContains: userId)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Hivemind.fromJson({...data, 'id': doc.id});
    }).toList();
  }

  Future<Hivemind> createHivemind({
    required String name,
    String? description,
    String icon = '🐝',
  }) async {
    if (_auth.currentUser == null) {
      throw Exception('Must be logged in to create a Hivemind');
    }

    final result = await _functions.httpsCallable('createHivemind').call({
      'name': name.trim(),
      'description': description?.trim(),
      'icon': icon,
    });

    return Hivemind.fromJson(_asHivemindJson(result.data));
  }

  Future<Hivemind> joinByInviteCode(String inviteCode) async {
    if (_auth.currentUser == null) {
      throw Exception('Must be logged in to join a Hivemind');
    }

    final result = await _functions.httpsCallable('joinHivemind').call({
      'invite_code': inviteCode.trim().toUpperCase(),
    });

    return Hivemind.fromJson(_asHivemindJson(result.data));
  }

  static Map<String, dynamic> _asHivemindJson(Object? data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Unexpected response from Hivemind server');
  }

  Future<List<HivemindMember>> getHivemindMembers(String hivemindId) async {
    try {
      final snapshot = await _firestore
          .collection('hiveminds')
          .doc(hivemindId)
          .collection('members')
          .get();

      return snapshot.docs
          .map(
            (d) => HivemindMember.fromJson({
              ...d.data(),
              'user_id': d.id,
              'hivemind_id': hivemindId,
            }),
          )
          .toList();
    } catch (_) {
      return [];
    }
  }

  Stream<List<HivemindMember>> streamHivemindMembers(String hivemindId) {
    return _firestore
        .collection('hiveminds')
        .doc(hivemindId)
        .collection('members')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (d) => HivemindMember.fromJson({
                  ...d.data(),
                  'user_id': d.id,
                  'hivemind_id': hivemindId,
                }),
              )
              .toList();
        });
  }
}
