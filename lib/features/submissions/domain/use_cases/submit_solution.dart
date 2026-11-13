import '../entities/submission.dart';
import '../repositories/submission_repository.dart';

class SubmitSolution {
  final SubmissionRepository repository;

  SubmitSolution(this.repository);

  Future<void> call(Submission submission) async {
    return repository.submitSolution(submission);
  }
}
