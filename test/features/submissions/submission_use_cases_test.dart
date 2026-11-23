import 'package:flutter_test/flutter_test.dart';

import 'package:edubridge_mobile_application/features/submissions/domain/entities/submission.dart';
import 'package:edubridge_mobile_application/features/submissions/domain/repositories/submission_repository.dart';
import 'package:edubridge_mobile_application/features/submissions/domain/use_cases/delete_submission.dart';
import 'package:edubridge_mobile_application/features/submissions/domain/use_cases/submit_solution.dart';
import 'package:edubridge_mobile_application/features/submissions/domain/use_cases/update_submission_review.dart';
import 'package:edubridge_mobile_application/features/submissions/domain/use_cases/update_talent_submission.dart';
import 'package:edubridge_mobile_application/features/submissions/domain/use_cases/watch_company_submissions.dart';
import 'package:edubridge_mobile_application/features/submissions/domain/use_cases/watch_submission.dart';
import 'package:edubridge_mobile_application/features/submissions/domain/use_cases/watch_talent_submissions.dart';

class FakeSubmissionRepository implements SubmissionRepository {
  final List<Submission> storedSubmissions = [];
  bool wasCreateCalled = false;
  bool wasUpdateTalentCalled = false;
  bool wasUpdateReviewCalled = false;
  bool wasDeleteCalled = false;

  @override
  Future<String> createSubmission(Submission submission) async {
    wasCreateCalled = true;
    final created = submission.copyWith(id: 'generated_id_123');
    storedSubmissions.add(created);
    return created.id;
  }

  @override
  Future<void> updateTalentSubmission(Submission submission) async {
    wasUpdateTalentCalled = true;
    final index = storedSubmissions.indexWhere((s) => s.id == submission.id);
    if (index >= 0) {
      storedSubmissions[index] = submission;
    }
  }

  @override
  Future<void> updateCompanyReview({
    required String submissionId,
    required String companyId,
    required SubmissionStatus status,
    required bool isShortlisted,
  }) async {
    wasUpdateReviewCalled = true;
    final index = storedSubmissions.indexWhere((s) => s.id == submissionId);
    if (index >= 0) {
      storedSubmissions[index] = storedSubmissions[index].copyWith(
        status: status,
        isShortlisted: isShortlisted,
      );
    }
  }

  @override
  Future<void> deleteSubmission({
    required String submissionId,
    required String talentId,
  }) async {
    wasDeleteCalled = true;
    storedSubmissions.removeWhere(
      (s) => s.id == submissionId && s.talentId == talentId,
    );
  }

  @override
  Stream<Submission?> watchSubmissionById(String submissionId) {
    return Stream.value(
      storedSubmissions.cast<Submission?>().firstWhere(
        (s) => s?.id == submissionId,
        orElse: () => null,
      ),
    );
  }

  @override
  Stream<Submission?> watchSubmissionForChallengeAndTalent({
    required String challengeId,
    required String talentId,
  }) {
    return Stream.value(
      storedSubmissions.cast<Submission?>().firstWhere(
        (s) => s?.challengeId == challengeId && s?.talentId == talentId,
        orElse: () => null,
      ),
    );
  }

  @override
  Stream<List<Submission>> watchTalentSubmissions(String talentId) {
    return Stream.value(
      storedSubmissions.where((s) => s.talentId == talentId).toList(),
    );
  }

  @override
  Stream<List<Submission>> watchCompanySubmissions(String companyId) {
    return Stream.value(
      storedSubmissions.where((s) => s.companyId == companyId).toList(),
    );
  }
}

void main() {
  late FakeSubmissionRepository repository;

  setUp(() {
    repository = FakeSubmissionRepository();
  });

  final testSubmission = Submission(
    id: 'sub123',
    challengeId: 'ch123',
    talentId: 'talent456',
    companyId: 'comp789',
    solutionText: 'This is a valid solution that meets all requirements.',
    attachmentUrls: const ['https://github.com/example/repo'],
    status: SubmissionStatus.submitted,
    isShortlisted: false,
    submittedAt: DateTime.utc(2026, 11, 1),
    updatedAt: DateTime.utc(2026, 11, 1),
  );

  group('Member 3 Domain Use Cases', () {
    test('SubmitSolution delegates to repository.createSubmission', () async {
      final useCase = SubmitSolution(repository);
      final id = await useCase(testSubmission);

      expect(id, 'generated_id_123');
      expect(repository.wasCreateCalled, isTrue);
      expect(repository.storedSubmissions.length, 1);
    });

    test('UpdateTalentSubmission updates the solution in repository', () async {
      await repository.createSubmission(testSubmission);
      final useCase = UpdateTalentSubmission(repository);

      final updatedSubmission = testSubmission.copyWith(
        id: 'generated_id_123',
        solutionText: 'Updated solution with more detailed architecture.',
      );

      await useCase(updatedSubmission);

      expect(repository.wasUpdateTalentCalled, isTrue);
      expect(
        repository.storedSubmissions.first.solutionText,
        'Updated solution with more detailed architecture.',
      );
    });

    test('UpdateSubmissionReview transitions status and shortlists', () async {
      await repository.createSubmission(testSubmission);
      final useCase = UpdateSubmissionReview(repository);

      await useCase(
        submissionId: 'generated_id_123',
        companyId: 'comp789',
        status: SubmissionStatus.reviewed,
        isShortlisted: true,
      );

      expect(repository.wasUpdateReviewCalled, isTrue);
      final saved = repository.storedSubmissions.first;
      expect(saved.status, SubmissionStatus.reviewed);
      expect(saved.isShortlisted, isTrue);
    });

    test(
      'DeleteSubmission removes submission for the specified talent',
      () async {
        await repository.createSubmission(testSubmission);
        expect(repository.storedSubmissions.length, 1);

        final useCase = DeleteSubmission(repository);
        await useCase(submissionId: 'generated_id_123', talentId: 'talent456');

        expect(repository.wasDeleteCalled, isTrue);
        expect(repository.storedSubmissions.isEmpty, isTrue);
      },
    );

    test('WatchTalentSubmissions returns talent-filtered stream', () async {
      await repository.createSubmission(testSubmission);
      final useCase = WatchTalentSubmissions(repository);

      final streamResult = await useCase('talent456').first;
      expect(streamResult.length, 1);
      expect(streamResult.first.talentId, 'talent456');

      final emptyResult = await useCase('otherTalent').first;
      expect(emptyResult.isEmpty, isTrue);
    });

    test('WatchCompanySubmissions returns company-filtered stream', () async {
      await repository.createSubmission(testSubmission);
      final useCase = WatchCompanySubmissions(repository);

      final streamResult = await useCase('comp789').first;
      expect(streamResult.length, 1);
      expect(streamResult.first.companyId, 'comp789');
    });

    test('WatchSubmission returns single submission by ID', () async {
      await repository.createSubmission(testSubmission);
      final useCase = WatchSubmission(repository);

      final streamResult = await useCase('generated_id_123').first;
      expect(streamResult, isNotNull);
      expect(streamResult!.id, 'generated_id_123');
    });
  });
}
