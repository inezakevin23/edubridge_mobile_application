enum ChallengeStatus { open, closed }

extension ChallengeStatusX on ChallengeStatus {
  String get value => name;

  static ChallengeStatus fromValue(Object? value) {
    switch (value) {
      case 'open':
        return ChallengeStatus.open;
      case 'closed':
        return ChallengeStatus.closed;
      default:
        throw FormatException('Unsupported challenge status: $value');
    }
  }
}

/// Framework-independent representation of a company challenge.
class Challenge {
  const Challenge({
    required this.id,
    required this.companyId,
    required this.title,
    required this.description,
    required this.category,
    required this.requirements,
    required this.deadline,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestore document ID. It is empty before a new document is created.
  final String id;
  final String companyId;
  final String title;
  final String description;
  final String category;
  final List<String> requirements;
  final DateTime deadline;
  final ChallengeStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOpen => status == ChallengeStatus.open;
  bool get isPastDeadline => deadline.isBefore(DateTime.now());

  Challenge copyWith({
    String? id,
    String? companyId,
    String? title,
    String? description,
    String? category,
    List<String>? requirements,
    DateTime? deadline,
    ChallengeStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Challenge(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      requirements: requirements ?? this.requirements,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
