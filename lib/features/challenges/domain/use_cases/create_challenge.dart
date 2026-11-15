import '../entities/challenge.dart';
import '../repositories/challenge_repository.dart';

class CreateChallenge {
  const CreateChallenge(this._repository);

  final ChallengeRepository _repository;

  Future<String> call(Challenge challenge) =>
      _repository.createChallenge(challenge);
}
