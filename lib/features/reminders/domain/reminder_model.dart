enum ReminderCompletionScope {
  anyone,
  assigned,
  all;

  static ReminderCompletionScope fromString(String? value) {
    switch (value) {
      case 'assigned':
        return ReminderCompletionScope.assigned;
      case 'all':
        return ReminderCompletionScope.all;
      case 'anyone':
      default:
        return ReminderCompletionScope.anyone;
    }
  }
}

class Reminder {
  final String id;
  final String hivemindId;
  final String title;
  final String? notes;
  final DateTime dueAt;
  final String? rrule;
  final bool isCompleted;
  final DateTime? completedAt;
  final String? completedBy;
  final List<String> completedByIds;
  final String? createdBy;
  final ReminderCompletionScope completionScope;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Reminder({
    required this.id,
    required this.hivemindId,
    required this.title,
    this.notes,
    required this.dueAt,
    this.rrule,
    this.isCompleted = false,
    this.completedAt,
    this.completedBy,
    this.completedByIds = const [],
    this.createdBy,
    this.completionScope = ReminderCompletionScope.anyone,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isRecurring => rrule != null && rrule!.trim().isNotEmpty;

  bool isCompletedByUser(String? userId) {
    switch (completionScope) {
      case ReminderCompletionScope.anyone:
        return isCompleted || completedByIds.isNotEmpty;
      case ReminderCompletionScope.assigned:
        if (isCompleted) return true;
        if (assignedTo != null && completedByIds.contains(assignedTo)) return true;
        if (userId != null && userId == assignedTo) {
          return completedByIds.contains(userId);
        }
        return completedByIds.isNotEmpty;
      case ReminderCompletionScope.all:
        if (userId == null) return isCompleted || completedByIds.isNotEmpty;
        return completedByIds.contains(userId) || isCompleted;
    }
  }

  bool isCompletedByAll(Iterable<String> memberUserIds) {
    if (memberUserIds.isEmpty) return isCompleted;
    final completedSet = completedByIds.toSet();
    return memberUserIds.every(completedSet.contains);
  }

  bool isFullyCompleted(Iterable<String> memberUserIds) {
    switch (completionScope) {
      case ReminderCompletionScope.anyone:
        return isCompleted || completedByIds.isNotEmpty;
      case ReminderCompletionScope.assigned:
        if (assignedTo != null && assignedTo!.isNotEmpty) {
          return isCompleted || completedByIds.contains(assignedTo);
        }
        return isCompleted || completedByIds.isNotEmpty;
      case ReminderCompletionScope.all:
        return isCompletedByAll(memberUserIds);
    }
  }

  Reminder copyWith({
    String? id,
    String? hivemindId,
    String? title,
    String? notes,
    DateTime? dueAt,
    String? rrule,
    bool? isCompleted,
    DateTime? completedAt,
    String? completedBy,
    List<String>? completedByIds,
    String? createdBy,
    ReminderCompletionScope? completionScope,
    String? assignedTo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      hivemindId: hivemindId ?? this.hivemindId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      dueAt: dueAt ?? this.dueAt,
      rrule: rrule ?? this.rrule,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
      completedBy: completedBy ?? this.completedBy,
      completedByIds: completedByIds ?? this.completedByIds,
      createdBy: createdBy ?? this.createdBy,
      completionScope: completionScope ?? this.completionScope,
      assignedTo: assignedTo ?? this.assignedTo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    List<String> completedByIds = [];
    if (json['completed_by_ids'] != null) {
      completedByIds = (json['completed_by_ids'] as List<dynamic>)
          .map((e) => e.toString())
          .toList();
    } else if (json['completed_by'] != null) {
      completedByIds = [json['completed_by'].toString()];
    }

    final scopeStr = json['completion_scope'] as String?;
    final assignedTo = json['assigned_to'] as String?;
    final ReminderCompletionScope completionScope;
    if (scopeStr != null) {
      completionScope = ReminderCompletionScope.fromString(scopeStr);
    } else if (assignedTo != null && assignedTo.isNotEmpty) {
      completionScope = ReminderCompletionScope.assigned;
    } else {
      completionScope = ReminderCompletionScope.anyone;
    }

    return Reminder(
      id: json['id'] as String,
      hivemindId: json['hivemind_id'] as String,
      title: json['title'] as String,
      notes: json['notes'] as String?,
      dueAt: DateTime.parse(json['due_at'] as String).toLocal(),
      rrule: json['rrule'] as String?,
      isCompleted: (json['is_completed'] as bool?) ?? false,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String).toLocal()
          : null,
      completedBy: json['completed_by'] as String?,
      completedByIds: completedByIds,
      createdBy: json['created_by'] as String?,
      completionScope: completionScope,
      assignedTo: assignedTo,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hivemind_id': hivemindId,
      'title': title,
      'notes': notes,
      'due_at': dueAt.toUtc().toIso8601String(),
      'rrule': rrule,
      'is_completed': isCompleted,
      'completed_at': completedAt?.toUtc().toIso8601String(),
      'completed_by': completedBy ?? (completedByIds.isNotEmpty ? completedByIds.last : null),
      'completed_by_ids': completedByIds,
      'created_by': createdBy,
      'completion_scope': completionScope.name,
      'assigned_to': assignedTo,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
