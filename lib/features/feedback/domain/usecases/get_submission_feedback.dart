import 'package:edubridge_mobile_application/features/feedback/domain/entities/submission_feedback.dart';
import 'package:edubridge_mobile_application/features/feedback/domain/repositories/feedback_repository.dart';

class GetSubmissionFeedback {
  const GetSubmissionFeedback(this._repository);

  final FeedbackRepository _repository;

  Future<SubmissionFeedback?> call(String submissionId) {
    return _repository.getForSubmission(submissionId);
  }
}
