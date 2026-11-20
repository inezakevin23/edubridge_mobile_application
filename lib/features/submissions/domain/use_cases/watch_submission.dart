import '../entities/submission.dart';
import '../repositories/submission_repository.dart';

class WatchSubmission {
  const WatchSubmission(this._repository);

  final SubmissionRepository _repository;

  Stream<Submission?> call(String submissionId) =>
      _repository.watchSubmissionById(submissionId);
}

class WatchSubmissionForChallengeAndTalent {
  const WatchSubmissionForChallengeAndTalent(this._repository);

  final SubmissionRepository _repository;

  Stream<Submission?> call({
    required String challengeId,
    required String talentId,
  }) {
    return _repository.watchSubmissionForChallengeAndTalent(
      challengeId: challengeId,
      talentId: talentId,
    );
  }
}
