import 'package:edubridge_mobile_application/features/feedback/domain/entities/submission_feedback.dart';
import 'package:edubridge_mobile_application/features/feedback/domain/repositories/feedback_repository.dart';

class SaveSubmissionFeedback {
  const SaveSubmissionFeedback(this._repository);

  final FeedbackRepository _repository;

  Future<void> call(SubmissionFeedback feedback) async {
    final validationMessage = feedback.validate();
    if (validationMessage != null) {
      throw ArgumentError(validationMessage);
    }
    await _repository.save(feedback);
  }
}
