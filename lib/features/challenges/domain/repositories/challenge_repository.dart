import '../entities/challenge.dart';

abstract class ChallengeRepository {
  Stream<List<Challenge>> watchOpenChallenges();

  Stream<Challenge?> watchChallengeById(String challengeId);

  Stream<List<Challenge>> watchCompanyChallenges(String companyId);

  Future<String> createChallenge(Challenge challenge);

  Future<void> updateChallenge(Challenge challenge);

  /// Deletes a challenge only when it has no submissions.
  Future<void> deleteChallenge({
    required String challengeId,
    required String companyId,
  });
}
