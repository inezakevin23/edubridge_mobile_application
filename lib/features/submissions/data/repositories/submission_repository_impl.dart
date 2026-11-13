import '../../domain/entities/submission.dart';
import '../../domain/repositories/submission_repository.dart';
import '../datasources/firestore_submission_data_source.dart';
import '../models/submission_model.dart';

class SubmissionRepositoryImpl implements SubmissionRepository {
  final SubmissionDataSource dataSource;

  SubmissionRepositoryImpl({required this.dataSource});

  @override
  Future<void> submitSolution(Submission submission) async {
    final model = submission is SubmissionModel
        ? submission
        : SubmissionModel.fromEntity(submission);
    return dataSource.submitSolution(model);
  }

  @override
  Stream<List<Submission>> getSubmissionsByChallenge(String challengeId) {
    return dataSource.getSubmissionsByChallenge(challengeId);
  }

  @override
  Stream<List<Submission>> getSubmissionsByTalent(String talentId) {
    return dataSource.getSubmissionsByTalent(talentId);
  }

  @override
  Stream<List<Submission>> getSubmissionsByCompany(String companyId) {
    return dataSource.getSubmissionsByCompany(companyId);
  }

  @override
  Future<Submission?> getSubmissionById(String submissionId) {
    return dataSource.getSubmissionById(submissionId);
  }

  @override
  Future<void> updateSubmission(Submission submission) async {
    final model = submission is SubmissionModel
        ? submission
        : SubmissionModel.fromEntity(submission);
    return dataSource.updateSubmission(model);
  }

  @override
  Future<void> updateSubmissionStatus(
    String submissionId,
    String status, {
    bool? isShortlisted,
    DateTime? reviewedAt,
    String? feedback,
    int? pointsAwarded,
  }) {
    return dataSource.updateSubmissionStatus(
      submissionId,
      status,
      isShortlisted: isShortlisted,
      reviewedAt: reviewedAt,
    );
  }

  @override
  Future<void> deleteSubmission(String submissionId) {
    return dataSource.deleteSubmission(submissionId);
  }
}
