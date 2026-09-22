import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../domain/hivemind_member_model.dart';
import '../domain/hivemind_model.dart';

class HivemindRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  HivemindRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

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
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('Must be logged in to create a Hivemind');
    }

    final inviteCode = _generateShortCode();
    final docRef = _firestore.collection('hiveminds').doc();
    final hivemindId = docRef.id;
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final hivemindMap = {
      'id': hivemindId,
      'name': name.trim(),
      'description': description?.trim(),
      'icon': icon,
      'invite_code': inviteCode,
      'created_by': userId,
      'member_ids': [userId],
      'created_at': nowIso,
    };

    final user = _auth.currentUser;
    final memberMap = {
      'user_id': userId,
      'hivemind_id': hivemindId,
      'role': 'owner',
      'display_name':
          user?.displayName ?? user?.email?.split('@').first ?? 'Member',
      'avatar_url': user?.photoURL,
      'joined_at': nowIso,
    };

    final batch = _firestore.batch();
    batch.set(docRef, hivemindMap);
    batch.set(docRef.collection('members').doc(userId), memberMap);
    await batch.commit();

    return Hivemind.fromJson(hivemindMap);
  }

  Future<Hivemind> joinByInviteCode(String inviteCode) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('Must be logged in to join a Hivemind');

    final cleanCode = inviteCode.trim().toUpperCase();

    final query = await _firestore
        .collection('hiveminds')
        .where('invite_code', isEqualTo: cleanCode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception('Invalid invite code. No Hivemind found.');
    }

    final doc = query.docs.first;
    final hivemindId = doc.id;
    final user = _auth.currentUser;
    final nowIso = DateTime.now().toUtc().toIso8601String();

    final memberMap = {
      'user_id': userId,
      'hivemind_id': hivemindId,
      'role': 'member',
      'display_name':
          user?.displayName ?? user?.email?.split('@').first ?? 'Member',
      'avatar_url': user?.photoURL,
      'joined_at': nowIso,
    };

    final batch = _firestore.batch();
    batch.update(doc.reference, {
      'member_ids': FieldValue.arrayUnion([userId]),
    });
    batch.set(
      doc.reference.collection('members').doc(userId),
      memberMap,
      SetOptions(merge: true),
    );
    await batch.commit();

    return Hivemind.fromJson({...doc.data(), 'id': hivemindId});
  }

  String _generateShortCode() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // omit easily confused 0, O, 1, I
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
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
