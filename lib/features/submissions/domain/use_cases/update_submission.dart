import '../entities/submission.dart';
import '../repositories/submission_repository.dart';

class UpdateSubmission {
  final SubmissionRepository repository;

  UpdateSubmission(this.repository);

  Future<void> call(Submission submission) async {
    return repository.updateSubmission(submission);
  }

  Future<void> updateStatus(
    String submissionId,
    String status, {
    bool? isShortlisted,
    String? feedback,
    double? score,
  }) async {
    return repository.updateSubmissionStatus(
      submissionId,
      status,
      isShortlisted: isShortlisted,
      feedback: feedback,
      score: score,
    );
  }
}
