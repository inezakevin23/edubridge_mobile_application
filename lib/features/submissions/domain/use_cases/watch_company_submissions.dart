import '../entities/submission.dart';
import '../repositories/submission_repository.dart';

class WatchCompanySubmissions {
  const WatchCompanySubmissions(this._repository);

  final SubmissionRepository _repository;

  Stream<List<Submission>> call(String companyId) =>
      _repository.watchCompanySubmissions(companyId);
}
