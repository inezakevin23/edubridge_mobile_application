import '../repositories/submission_repository.dart';

class DeleteSubmission {
  final SubmissionRepository repository;

  DeleteSubmission(this.repository);

  Future<void> call(String submissionId) async {
    return repository.deleteSubmission(submissionId);
  }
}
