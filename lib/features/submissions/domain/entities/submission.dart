class Submission {
  final String id; // Document ID: {challengeId}_{talentId}
  final String challengeId;
  final String talentId;
  final String companyId;
  final String solutionText;
  final List<String> attachmentUrls;
  final String status; // 'submitted', 'under_review', 'reviewed'
  final bool isShortlisted;
  final DateTime submittedAt;
  final DateTime updatedAt;
  final DateTime? reviewedAt;

  // UI helper display fields (denormalized from challenges/profiles or feedback)
  final String? challengeTitle;
  final String? talentName;
  final String? talentEmail;
  final String? feedback;
  final int? pointsAwarded;

  const Submission({
    required this.id,
    required this.challengeId,
    required this.talentId,
    required this.companyId,
    required this.solutionText,
    this.attachmentUrls = const [],
    this.status = 'submitted',
    this.isShortlisted = false,
    required this.submittedAt,
    required this.updatedAt,
    this.reviewedAt,
    this.challengeTitle,
    this.talentName,
    this.talentEmail,
    this.feedback,
    this.pointsAwarded,
  });

  // Generates document ID per schema: {challengeId}_{talentId}
  static String generateId(String challengeId, String talentId) {
    return '${challengeId}_$talentId';
  }

  // UI convenience getters
  String get description => solutionText;
  String? get githubUrl => attachmentUrls.isNotEmpty ? attachmentUrls[0] : null;
  String? get liveDemoUrl =>
      attachmentUrls.length > 1 ? attachmentUrls[1] : null;
  double? get score => pointsAwarded?.toDouble();

  Submission copyWith({
    String? id,
    String? challengeId,
    String? talentId,
    String? companyId,
    String? solutionText,
    List<String>? attachmentUrls,
    String? status,
    bool? isShortlisted,
    DateTime? submittedAt,
    DateTime? updatedAt,
    DateTime? reviewedAt,
    String? challengeTitle,
    String? talentName,
    String? talentEmail,
    String? feedback,
    int? pointsAwarded,
  }) {
    return Submission(
      id: id ?? this.id,
      challengeId: challengeId ?? this.challengeId,
      talentId: talentId ?? this.talentId,
      companyId: companyId ?? this.companyId,
      solutionText: solutionText ?? this.solutionText,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
      status: status ?? this.status,
      isShortlisted: isShortlisted ?? this.isShortlisted,
      submittedAt: submittedAt ?? this.submittedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      challengeTitle: challengeTitle ?? this.challengeTitle,
      talentName: talentName ?? this.talentName,
      talentEmail: talentEmail ?? this.talentEmail,
      feedback: feedback ?? this.feedback,
      pointsAwarded: pointsAwarded ?? this.pointsAwarded,
    );
  }
}
