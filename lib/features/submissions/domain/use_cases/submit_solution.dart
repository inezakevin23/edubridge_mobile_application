import '../entities/submission.dart';
import '../repositories/submission_repository.dart';

class SubmitSolution {
  const SubmitSolution(this._repository);

  final SubmissionRepository _repository;

  Future<String> call(Submission submission) =>
      _repository.createSubmission(submission);
}
