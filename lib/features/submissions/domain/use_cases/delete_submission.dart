import '../repositories/submission_repository.dart';

class DeleteSubmission {
  const DeleteSubmission(this._repository);

  final SubmissionRepository _repository;

  Future<void> call({required String submissionId, required String talentId}) {
    return _repository.deleteSubmission(
      submissionId: submissionId,
      talentId: talentId,
    );
  }
}
