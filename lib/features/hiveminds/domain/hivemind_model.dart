class Hivemind {
  final String id;
  final String name;
  final String? description;
  final String icon;
  final String inviteCode;
  final String? createdBy;
  final DateTime createdAt;

  const Hivemind({
    required this.id,
    required this.name,
    this.description,
    this.icon = '🐝',
    required this.inviteCode,
    this.createdBy,
    required this.createdAt,
  });

  factory Hivemind.fromJson(Map<String, dynamic> json) {
    return Hivemind(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      icon: (json['icon'] as String?) ?? '🐝',
      inviteCode: json['invite_code'] as String,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'invite_code': inviteCode,
      'created_by': createdBy,
      'created_at': createdAt.toUtc().toIso8601String(),
    };
  }
}
