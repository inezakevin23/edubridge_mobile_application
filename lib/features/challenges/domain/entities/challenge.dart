enum ChallengeStatus { draft, open, closed }

extension ChallengeStatusX on ChallengeStatus {
  String get value => name;

  static ChallengeStatus fromValue(Object? value) {
    switch (value) {
      case 'open':
      case 'published':
        return ChallengeStatus.open;
      case 'draft':
        return ChallengeStatus.draft;
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
    this.shortDescription = '',
    required this.description,
    required this.category,
    this.estimatedDuration = '',
    this.requiredSkills = const [],
    this.difficulty = '',
    this.submissionFormats = const [],
    this.maxTeamSize = 1,
    this.participantStatus = '',
    this.accessType = 'open',
    this.cashPrize = '',
    required this.requirements,
    this.eligibility = '',
    this.reward = '',
    required this.deadline,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestore document ID. It is empty before a new document is created.
  final String id;
  final String companyId;
  final String title;
  final String shortDescription;
  final String description;
  final String category;
  final String estimatedDuration;
  final List<String> requiredSkills;
  final String difficulty;
  final List<String> submissionFormats;
  final int maxTeamSize;
  final String participantStatus;
  final String accessType;
  final String cashPrize;
  final List<String> requirements;
  final String eligibility;
  final String reward;
  final DateTime deadline;
  final ChallengeStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOpen => status == ChallengeStatus.open;
  bool get isDraft => status == ChallengeStatus.draft;
  bool get isPastDeadline => deadline.isBefore(DateTime.now());

  Challenge copyWith({
    String? id,
    String? companyId,
    String? title,
    String? shortDescription,
    String? description,
    String? category,
    String? estimatedDuration,
    List<String>? requiredSkills,
    String? difficulty,
    List<String>? submissionFormats,
    int? maxTeamSize,
    String? participantStatus,
    String? accessType,
    String? cashPrize,
    List<String>? requirements,
    String? eligibility,
    String? reward,
    DateTime? deadline,
    ChallengeStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Challenge(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      title: title ?? this.title,
      shortDescription: shortDescription ?? this.shortDescription,
      description: description ?? this.description,
      category: category ?? this.category,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      difficulty: difficulty ?? this.difficulty,
      submissionFormats: submissionFormats ?? this.submissionFormats,
      maxTeamSize: maxTeamSize ?? this.maxTeamSize,
      participantStatus: participantStatus ?? this.participantStatus,
      accessType: accessType ?? this.accessType,
      cashPrize: cashPrize ?? this.cashPrize,
      requirements: requirements ?? this.requirements,
      eligibility: eligibility ?? this.eligibility,
      reward: reward ?? this.reward,
      deadline: deadline ?? this.deadline,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
