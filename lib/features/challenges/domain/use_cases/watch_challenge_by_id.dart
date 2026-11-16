import '../entities/challenge.dart';
import '../repositories/challenge_repository.dart';

class WatchChallengeById {
  const WatchChallengeById(this._repository);

  final ChallengeRepository _repository;

  Stream<Challenge?> call(String challengeId) =>
      _repository.watchChallengeById(challengeId);
}
