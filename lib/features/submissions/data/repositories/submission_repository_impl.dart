import '../../domain/entities/submission.dart';
import '../../domain/repositories/submission_repository.dart';
import '../datasources/firestore_submission_data_source.dart';
import '../models/submission_model.dart';

class SubmissionRepositoryImpl implements SubmissionRepository {
  const SubmissionRepositoryImpl(this._dataSource);

  final FirestoreSubmissionDataSource _dataSource;

  @override
  Stream<Submission?> watchSubmissionById(String submissionId) {
    return _dataSource
        .watchSubmissionById(submissionId)
        .map((model) => model?.toEntity());
  }

  @override
  Stream<Submission?> watchSubmissionForChallengeAndTalent({
    required String challengeId,
    required String talentId,
  }) {
    return _dataSource
        .watchSubmissionForChallengeAndTalent(
          challengeId: challengeId,
          talentId: talentId,
        )
        .map((model) => model?.toEntity());
  }

  @override
  Stream<List<Submission>> watchTalentSubmissions(String talentId) {
    return _dataSource.watchTalentSubmissions(talentId).map(
          (models) => models.map((model) => model.toEntity()).toList(growable: false),
        );
  }

  @override
  Stream<List<Submission>> watchCompanySubmissions(String companyId) {
    return _dataSource.watchCompanySubmissions(companyId).map(
          (models) => models.map((model) => model.toEntity()).toList(growable: false),
        );
  }

  @override
  Future<String> createSubmission(Submission submission) {
    return _dataSource.createSubmission(SubmissionModel.fromEntity(submission));
  }

  @override
  Future<void> updateTalentSubmission(Submission submission) {
    return _dataSource.updateTalentSubmission(SubmissionModel.fromEntity(submission));
  }

  @override
  Future<void> updateCompanyReview({
    required String submissionId,
    required String companyId,
    required SubmissionStatus status,
    required bool isShortlisted,
  }) {
    return _dataSource.updateCompanyReview(
      submissionId: submissionId,
      companyId: companyId,
      status: status.value,
      isShortlisted: isShortlisted,
    );
  }

  @override
  Future<void> deleteSubmission({
    required String submissionId,
    required String talentId,
  }) {
    return _dataSource.deleteSubmission(
      submissionId: submissionId,
      talentId: talentId,
    );
  }
}
