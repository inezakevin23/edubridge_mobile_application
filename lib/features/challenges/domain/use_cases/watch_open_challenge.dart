import '../entities/challenge.dart';
import '../repositories/challenge_repository.dart';

class WatchOpenChallenges {
  const WatchOpenChallenges(this._repository);

  final ChallengeRepository _repository;

  Stream<List<Challenge>> call() => _repository.watchOpenChallenges();
}
