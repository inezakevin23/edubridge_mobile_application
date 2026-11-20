import '../entities/submission.dart';
import '../repositories/submission_repository.dart';

class UpdateSubmissionReview {
  const UpdateSubmissionReview(this._repository);

  final SubmissionRepository _repository;

  Future<void> call({
    required String submissionId,
    required String companyId,
    required SubmissionStatus status,
    required bool isShortlisted,
  }) {
    return _repository.updateCompanyReview(
      submissionId: submissionId,
      companyId: companyId,
      status: status,
      isShortlisted: isShortlisted,
    );
  }
}
