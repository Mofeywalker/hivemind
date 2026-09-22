class HivemindMember {
  final String userId;
  final String hivemindId;
  final String role;
  final String displayName;
  final String? avatarUrl;
  final DateTime joinedAt;

  const HivemindMember({
    required this.userId,
    required this.hivemindId,
    required this.role,
    required this.displayName,
    this.avatarUrl,
    required this.joinedAt,
  });

  factory HivemindMember.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return HivemindMember(
      userId: (json['user_id'] ?? json['id']) as String,
      hivemindId: json['hivemind_id'] as String,
      role: (json['role'] as String?) ?? 'member',
      displayName:
          (profile?['display_name'] ?? json['display_name']) as String? ??
          'Member',
      avatarUrl: (profile?['avatar_url'] ?? json['avatar_url']) as String?,
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'] as String).toLocal()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'hivemind_id': hivemindId,
      'role': role,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'joined_at': joinedAt.toUtc().toIso8601String(),
    };
  }
}
