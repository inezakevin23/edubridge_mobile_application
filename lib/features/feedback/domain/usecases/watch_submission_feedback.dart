import 'package:edubridge_mobile_application/features/feedback/domain/entities/submission_feedback.dart';
import 'package:edubridge_mobile_application/features/feedback/domain/repositories/feedback_repository.dart';

class WatchSubmissionFeedback {
  const WatchSubmissionFeedback(this._repository);

  final FeedbackRepository _repository;

  Stream<SubmissionFeedback?> call(String submissionId) {
    return _repository.watchForSubmission(submissionId);
  }
}
