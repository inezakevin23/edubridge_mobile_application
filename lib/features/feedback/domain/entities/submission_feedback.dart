class SubmissionFeedback {
  const SubmissionFeedback({
    required this.submissionId,
    required this.challengeId,
    required this.talentId,
    required this.companyId,
    required this.rating,
    required this.pointsAwarded,
    required this.summary,
    required this.strengths,
    required this.areasForImprovement,
    this.cashPrizeAwarded = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String submissionId;
  final String challengeId;
  final String talentId;
  final String companyId;
  final int rating;
  final int pointsAwarded;
  final String summary;
  final String strengths;
  final String areasForImprovement;
  final double cashPrizeAwarded;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Returns null when the feedback can be saved; otherwise returns a message.
  String? validate() {
    if (submissionId.trim().isEmpty) return 'Submission is required.';
    if (challengeId.trim().isEmpty) return 'Challenge is required.';
    if (talentId.trim().isEmpty) return 'Talent user is required.';
    if (companyId.trim().isEmpty) return 'Company user is required.';
    if (rating < 1 || rating > 5) return 'Rating must be between 1 and 5.';
    if (pointsAwarded < 0 || pointsAwarded > 100) {
      return 'Points must be between 0 and 100.';
    }
    if (!cashPrizeAwarded.isFinite || cashPrizeAwarded < 0) {
      return 'Cash prize must be a non-negative amount.';
    }
    if (summary.trim().length < 10) {
      return 'Overall feedback must contain at least 10 characters.';
    }
    return null;
  }
}
