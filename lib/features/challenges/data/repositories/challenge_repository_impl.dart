import '../../domain/entities/challenge.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../datasources/firestore_challenge_data_source.dart';
import '../models/challenge_model.dart';

class ChallengeRepositoryImpl implements ChallengeRepository {
  const ChallengeRepositoryImpl(this._dataSource);

  final FirestoreChallengeDataSource _dataSource;

  @override
  Stream<List<Challenge>> watchOpenChallenges() {
    return _dataSource.watchOpenChallenges().map(
      (models) => models.map((model) => model.toEntity()).toList(),
    );
  }

  @override
  Stream<Challenge?> watchChallengeById(String challengeId) {
    return _dataSource
        .watchChallengeById(challengeId)
        .map((model) => model?.toEntity());
  }

  @override
  Stream<List<Challenge>> watchCompanyChallenges(String companyId) {
    return _dataSource
        .watchCompanyChallenges(companyId)
        .map((models) => models.map((model) => model.toEntity()).toList());
  }

  @override
  Future<String> createChallenge(Challenge challenge) {
    return _dataSource.createChallenge(ChallengeModel.fromEntity(challenge));
  }

  @override
  Future<void> updateChallenge(Challenge challenge) {
    return _dataSource.updateChallenge(ChallengeModel.fromEntity(challenge));
  }

  @override
  Future<void> deleteChallenge({
    required String challengeId,
    required String companyId,
  }) {
    return _dataSource.deleteChallenge(
      challengeId: challengeId,
      companyId: companyId,
    );
  }
}
