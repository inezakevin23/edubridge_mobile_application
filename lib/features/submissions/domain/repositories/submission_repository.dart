import '../entities/submission.dart';

abstract class SubmissionRepository {
  Future<void> submitSolution(Submission submission);

  Stream<List<Submission>> getSubmissionsByChallenge(String challengeId);

  Stream<List<Submission>> getSubmissionsByTalent(String talentId);

  Stream<List<Submission>> getSubmissionsByCompany(String companyId);

  Future<Submission?> getSubmissionById(String submissionId);

  Future<void> updateSubmission(Submission submission);

  Future<void> updateSubmissionStatus(
    String submissionId,
    String status, {
    bool? isShortlisted,
    DateTime? reviewedAt,
    String? feedback,
    int? pointsAwarded,
  });

  Future<void> deleteSubmission(String submissionId);
}
