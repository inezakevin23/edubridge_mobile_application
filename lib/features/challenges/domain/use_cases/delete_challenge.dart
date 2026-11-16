import '../repositories/challenge_repository.dart';

class DeleteChallenge {
  const DeleteChallenge(this._repository);

  final ChallengeRepository _repository;

  Future<void> call({required String challengeId, required String companyId}) =>
      _repository.deleteChallenge(
        challengeId: challengeId,
        companyId: companyId,
      );
}
