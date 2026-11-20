import '../entities/submission.dart';
import '../repositories/submission_repository.dart';

class UpdateTalentSubmission {
  const UpdateTalentSubmission(this._repository);

  final SubmissionRepository _repository;

  Future<void> call(Submission submission) =>
      _repository.updateTalentSubmission(submission);
}
