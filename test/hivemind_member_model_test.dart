import 'package:flutter_test/flutter_test.dart';
import 'package:hivemind/features/hiveminds/domain/hivemind_member_model.dart';

void main() {
  group('HivemindMember Model Tests', () {
    test('fromJson parses member and joined profile data correctly', () {
      final json = {
        'user_id': 'usr-123',
        'hivemind_id': 'hive-456',
        'role': 'owner',
        'joined_at': '2026-09-20T12:00:00.000Z',
        'profiles': {
          'id': 'usr-123',
          'display_name': 'Max',
          'avatar_url': 'https://example.com/avatar.png',
        },
      };

      final member = HivemindMember.fromJson(json);
      expect(member.userId, 'usr-123');
      expect(member.hivemindId, 'hive-456');
      expect(member.role, 'owner');
      expect(member.displayName, 'Max');
      expect(member.avatarUrl, 'https://example.com/avatar.png');

      final serialized = member.toJson();
      expect(serialized['user_id'], 'usr-123');
      expect(serialized['display_name'], 'Max');
    });

    test('fromJson handles missing profiles gracefully', () {
      final json = {
        'user_id': 'usr-999',
        'hivemind_id': 'hive-456',
      };

      final member = HivemindMember.fromJson(json);
      expect(member.userId, 'usr-999');
      expect(member.displayName, 'Member');
      expect(member.avatarUrl, isNull);
      expect(member.role, 'member');
    });
  });
}
