import '../entities/submission.dart';
import '../repositories/submission_repository.dart';

class GetSubmissions {
  final SubmissionRepository repository;

  GetSubmissions(this.repository);

  Stream<List<Submission>> byChallenge(String challengeId) {
    return repository.getSubmissionsByChallenge(challengeId);
  }

  Stream<List<Submission>> byTalent(String talentId) {
    return repository.getSubmissionsByTalent(talentId);
  }

  Future<Submission?> byId(String submissionId) {
    return repository.getSubmissionById(submissionId);
  }
}
