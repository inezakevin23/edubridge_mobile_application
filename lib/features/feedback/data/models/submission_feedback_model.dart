import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edubridge_mobile_application/features/feedback/domain/entities/submission_feedback.dart';

class SubmissionFeedbackModel extends SubmissionFeedback {
  const SubmissionFeedbackModel({
    required super.submissionId,
    required super.challengeId,
    required super.talentId,
    required super.companyId,
    required super.rating,
    required super.pointsAwarded,
    required super.summary,
    required super.strengths,
    required super.areasForImprovement,
    super.cashPrizeAwarded,
    super.createdAt,
    super.updatedAt,
  });

  factory SubmissionFeedbackModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw StateError('Feedback document ${document.id} has no data.');
    }

    return SubmissionFeedbackModel(
      submissionId: (data['submissionId'] as String?) ?? document.id,
      challengeId: (data['challengeId'] as String?) ?? '',
      talentId: (data['talentId'] as String?) ?? '',
      companyId: (data['companyId'] as String?) ?? '',
      rating: (data['rating'] as num?)?.toInt() ?? 0,
      pointsAwarded: (data['pointsAwarded'] as num?)?.toInt() ?? 0,
      summary: (data['summary'] as String?) ?? '',
      strengths: (data['strengths'] as String?) ?? '',
      areasForImprovement: (data['areasForImprovement'] as String?) ?? '',
      cashPrizeAwarded: (data['cashPrizeAwarded'] as num?)?.toDouble() ?? 0,
      createdAt: _readDate(data['createdAt']),
      updatedAt: _readDate(data['updatedAt']),
    );
  }

  static DateTime? _readDate(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  Map<String, dynamic> toFirestore() {
    return {
      'submissionId': submissionId,
      'challengeId': challengeId,
      'talentId': talentId,
      'companyId': companyId,
      'rating': rating,
      'pointsAwarded': pointsAwarded,
      'summary': summary.trim(),
      'strengths': strengths.trim(),
      'areasForImprovement': areasForImprovement.trim(),
      'cashPrizeAwarded': cashPrizeAwarded,
    };
  }
}
