import '../entities/challenge.dart';
import '../repositories/challenge_repository.dart';

class WatchCompanyChallenges {
  const WatchCompanyChallenges(this._repository);

  final ChallengeRepository _repository;

  Stream<List<Challenge>> call(String companyId) =>
      _repository.watchCompanyChallenges(companyId);
}
