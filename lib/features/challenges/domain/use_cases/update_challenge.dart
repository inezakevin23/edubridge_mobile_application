import '../entities/challenge.dart';
import '../repositories/challenge_repository.dart';

class UpdateChallenge {
  const UpdateChallenge(this._repository);

  final ChallengeRepository _repository;

  Future<void> call(Challenge challenge) =>
      _repository.updateChallenge(challenge);
}
