import 'package:edubridge_mobile_application/features/feedback/domain/entities/submission_feedback.dart';

abstract class FeedbackRepository {
  Stream<SubmissionFeedback?> watchForSubmission(String submissionId);

  Future<SubmissionFeedback?> getForSubmission(String submissionId);

  Future<void> save(SubmissionFeedback feedback);
}
