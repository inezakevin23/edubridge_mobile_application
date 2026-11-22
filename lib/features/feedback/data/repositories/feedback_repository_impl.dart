import 'package:edubridge_mobile_application/features/feedback/data/datasources/firestore_feedback_data_source.dart';
import 'package:edubridge_mobile_application/features/feedback/data/models/submission_feedback_model.dart';
import 'package:edubridge_mobile_application/features/feedback/domain/entities/submission_feedback.dart';
import 'package:edubridge_mobile_application/features/feedback/domain/repositories/feedback_repository.dart';

class FeedbackRepositoryImpl implements FeedbackRepository {
  const FeedbackRepositoryImpl(this._dataSource);

  final FirestoreFeedbackDataSource _dataSource;

  @override
  Stream<SubmissionFeedback?> watchForSubmission(String submissionId) {
    return _dataSource.watchForSubmission(submissionId);
  }

  @override
  Future<SubmissionFeedback?> getForSubmission(String submissionId) {
    return _dataSource.getForSubmission(submissionId);
  }

  @override
  Future<void> save(SubmissionFeedback feedback) {
    return _dataSource.save(
      SubmissionFeedbackModel(
        submissionId: feedback.submissionId,
        challengeId: feedback.challengeId,
        talentId: feedback.talentId,
        companyId: feedback.companyId,
        rating: feedback.rating,
        pointsAwarded: feedback.pointsAwarded,
        summary: feedback.summary,
        strengths: feedback.strengths,
        areasForImprovement: feedback.areasForImprovement,
        cashPrizeAwarded: feedback.cashPrizeAwarded,
        createdAt: feedback.createdAt,
        updatedAt: feedback.updatedAt,
      ),
    );
  }
}
