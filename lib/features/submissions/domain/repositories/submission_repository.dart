import '../entities/submission.dart';

abstract class SubmissionRepository {
  Stream<Submission?> watchSubmissionById(String submissionId);

  Stream<Submission?> watchSubmissionForChallengeAndTalent({
    required String challengeId,
    required String talentId,
  });

  Stream<List<Submission>> watchTalentSubmissions(String talentId);

  Stream<List<Submission>> watchCompanySubmissions(String companyId);

  Future<String> createSubmission(Submission submission);

  /// A Talent may edit their solution only while its status is `submitted`.
  Future<void> updateTalentSubmission(Submission submission);

  /// Company review actions may change status and shortlist state, never the
  /// Talent's submitted solution text or attachment URLs.
  Future<void> updateCompanyReview({
    required String submissionId,
    required String companyId,
    required SubmissionStatus status,
    required bool isShortlisted,
  });

  Future<void> deleteSubmission({
    required String submissionId,
    required String talentId,
  });
}
