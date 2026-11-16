enum SubmissionStatus { submitted, underReview, reviewed }

extension SubmissionStatusX on SubmissionStatus {
  String get value {
    switch (this) {
      case SubmissionStatus.submitted:
        return 'submitted';
      case SubmissionStatus.underReview:
        return 'under_review';
      case SubmissionStatus.reviewed:
        return 'reviewed';
    }
  }

  String get label {
    switch (this) {
      case SubmissionStatus.submitted:
        return 'Submitted';
      case SubmissionStatus.underReview:
        return 'Under review';
      case SubmissionStatus.reviewed:
        return 'Reviewed';
    }
  }

  static SubmissionStatus fromValue(Object? value) {
    switch (value) {
      case 'submitted':
        return SubmissionStatus.submitted;
      case 'under_review':
        return SubmissionStatus.underReview;
      case 'reviewed':
        return SubmissionStatus.reviewed;
      default:
        throw FormatException('Unsupported submission status: $value');
    }
  }
}

/// Framework-independent representation of a Talent's response to a challenge.
class Submission {
  const Submission({
    required this.id,
    required this.challengeId,
    required this.talentId,
    required this.companyId,
    required this.solutionText,
    required this.attachmentUrls,
    required this.status,
    required this.isShortlisted,
    required this.submittedAt,
    required this.updatedAt,
    this.reviewedAt,
  });

  final String id;
  final String challengeId;
  final String talentId;
  final String companyId;
  final String solutionText;
  final List<String> attachmentUrls;
  final SubmissionStatus status;
  final bool isShortlisted;
  final DateTime submittedAt;
  final DateTime updatedAt;
  final DateTime? reviewedAt;

  bool get canBeEdited => status == SubmissionStatus.submitted;

  Submission copyWith({
    String? id,
    String? challengeId,
    String? talentId,
    String? companyId,
    String? solutionText,
    List<String>? attachmentUrls,
    SubmissionStatus? status,
    bool? isShortlisted,
    DateTime? submittedAt,
    DateTime? updatedAt,
    DateTime? reviewedAt,
    bool clearReviewedAt = false,
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
      reviewedAt: clearReviewedAt ? null : reviewedAt ?? this.reviewedAt,
    );
  }
}
