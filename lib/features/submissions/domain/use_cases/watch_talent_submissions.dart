import '../entities/submission.dart';
import '../repositories/submission_repository.dart';

class WatchTalentSubmissions {
  const WatchTalentSubmissions(this._repository);

  final SubmissionRepository _repository;

  Stream<List<Submission>> call(String talentId) =>
      _repository.watchTalentSubmissions(talentId);
}
