import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/firestore_submission_data_source.dart';
import '../../data/repositories/submission_repository_impl.dart';
import '../../domain/entities/submission.dart';
import '../../domain/repositories/submission_repository.dart';
import '../../domain/use_cases/delete_submission.dart';
import '../../domain/use_cases/submit_solution.dart';
import '../../domain/use_cases/update_submission_review.dart';
import '../../domain/use_cases/update_talent_submission.dart';
import '../../domain/use_cases/watch_company_submissions.dart';
import '../../domain/use_cases/watch_submission.dart';
import '../../domain/use_cases/watch_talent_submissions.dart';

final submissionFirestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final submissionFirebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);

/// Exposes authentication changes to submission screens without depending on
/// Member 1's not-yet-fixed auth provider name.
final submissionAuthStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(submissionFirebaseAuthProvider).authStateChanges(),
);

final firestoreSubmissionDataSourceProvider =
    Provider<FirestoreSubmissionDataSource>(
      (ref) =>
          FirestoreSubmissionDataSource(ref.watch(submissionFirestoreProvider)),
    );

final submissionRepositoryProvider = Provider<SubmissionRepository>(
  (ref) => SubmissionRepositoryImpl(
    ref.watch(firestoreSubmissionDataSourceProvider),
  ),
);

final submitSolutionUseCaseProvider = Provider<SubmitSolution>(
  (ref) => SubmitSolution(ref.watch(submissionRepositoryProvider)),
);

final watchSubmissionUseCaseProvider = Provider<WatchSubmission>(
  (ref) => WatchSubmission(ref.watch(submissionRepositoryProvider)),
);

final watchSubmissionForChallengeUseCaseProvider =
    Provider<WatchSubmissionForChallengeAndTalent>(
      (ref) => WatchSubmissionForChallengeAndTalent(
        ref.watch(submissionRepositoryProvider),
      ),
    );

final watchTalentSubmissionsUseCaseProvider = Provider<WatchTalentSubmissions>(
  (ref) => WatchTalentSubmissions(ref.watch(submissionRepositoryProvider)),
);

final watchCompanySubmissionsUseCaseProvider =
    Provider<WatchCompanySubmissions>(
      (ref) => WatchCompanySubmissions(ref.watch(submissionRepositoryProvider)),
    );

final updateTalentSubmissionUseCaseProvider = Provider<UpdateTalentSubmission>(
  (ref) => UpdateTalentSubmission(ref.watch(submissionRepositoryProvider)),
);

final updateSubmissionReviewUseCaseProvider = Provider<UpdateSubmissionReview>(
  (ref) => UpdateSubmissionReview(ref.watch(submissionRepositoryProvider)),
);

final deleteSubmissionUseCaseProvider = Provider<DeleteSubmission>(
  (ref) => DeleteSubmission(ref.watch(submissionRepositoryProvider)),
);

final submissionByIdProvider = StreamProvider.autoDispose
    .family<Submission?, String>(
      (ref, submissionId) =>
          ref.watch(watchSubmissionUseCaseProvider)(submissionId),
    );

class SubmissionLookup {
  const SubmissionLookup({required this.challengeId, required this.talentId});

  final String challengeId;
  final String talentId;

  @override
  bool operator ==(Object other) =>
      other is SubmissionLookup &&
      other.challengeId == challengeId &&
      other.talentId == talentId;

  @override
  int get hashCode => Object.hash(challengeId, talentId);
}

final submissionForChallengeProvider = StreamProvider.autoDispose
    .family<Submission?, SubmissionLookup>(
      (ref, lookup) => ref.watch(watchSubmissionForChallengeUseCaseProvider)(
        challengeId: lookup.challengeId,
        talentId: lookup.talentId,
      ),
    );

final talentSubmissionsProvider = StreamProvider.autoDispose
    .family<List<Submission>, String>(
      (ref, talentId) =>
          ref.watch(watchTalentSubmissionsUseCaseProvider)(talentId),
    );

final companySubmissionsProvider = StreamProvider.autoDispose
    .family<List<Submission>, String>(
      (ref, companyId) =>
          ref.watch(watchCompanySubmissionsUseCaseProvider)(companyId),
    );

/// Centralizes submission write operations and exposes a shared loading/error
/// state to the Talent and Company pages.
class SubmissionActions extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<String> submitSolution({
    required String challengeId,
    required String talentId,
    required String companyId,
    required String solutionText,
    required List<String> attachmentUrls,
  }) async {
    state = const AsyncLoading();
    try {
      final now = DateTime.now();
      final submission = Submission(
        id: '',
        challengeId: challengeId,
        talentId: talentId,
        companyId: companyId,
        solutionText: solutionText.trim(),
        attachmentUrls: List.unmodifiable(attachmentUrls),
        status: SubmissionStatus.submitted,
        isShortlisted: false,
        submittedAt: now,
        updatedAt: now,
      );
      final id = await ref.read(submitSolutionUseCaseProvider)(submission);
      state = const AsyncData(null);
      ref.invalidate(submissionByIdProvider(id));
      ref.invalidate(
        submissionForChallengeProvider(
          SubmissionLookup(challengeId: challengeId, talentId: talentId),
        ),
      );
      ref.invalidate(talentSubmissionsProvider(talentId));
      ref.invalidate(companySubmissionsProvider(companyId));
      return id;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateTalentSubmission({
    required Submission submission,
    required String solutionText,
    required List<String> attachmentUrls,
  }) async {
    state = const AsyncLoading();
    try {
      final updated = submission.copyWith(
        solutionText: solutionText.trim(),
        attachmentUrls: List.unmodifiable(attachmentUrls),
        updatedAt: DateTime.now(),
      );
      await ref.read(updateTalentSubmissionUseCaseProvider)(updated);
      state = const AsyncData(null);
      ref.invalidate(submissionByIdProvider(submission.id));
      ref.invalidate(
        submissionForChallengeProvider(
          SubmissionLookup(
            challengeId: submission.challengeId,
            talentId: submission.talentId,
          ),
        ),
      );
      ref.invalidate(talentSubmissionsProvider(submission.talentId));
      ref.invalidate(companySubmissionsProvider(submission.companyId));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateCompanyReview({
    required Submission submission,
    required SubmissionStatus status,
    required bool isShortlisted,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(updateSubmissionReviewUseCaseProvider)(
        submissionId: submission.id,
        companyId: submission.companyId,
        status: status,
        isShortlisted: isShortlisted,
      );
      state = const AsyncData(null);
      ref.invalidate(submissionByIdProvider(submission.id));
      ref.invalidate(companySubmissionsProvider(submission.companyId));
      ref.invalidate(talentSubmissionsProvider(submission.talentId));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteSubmission(Submission submission) async {
    state = const AsyncLoading();
    try {
      await ref.read(deleteSubmissionUseCaseProvider)(
        submissionId: submission.id,
        talentId: submission.talentId,
      );
      state = const AsyncData(null);
      ref.invalidate(submissionByIdProvider(submission.id));
      ref.invalidate(
        submissionForChallengeProvider(
          SubmissionLookup(
            challengeId: submission.challengeId,
            talentId: submission.talentId,
          ),
        ),
      );
      ref.invalidate(talentSubmissionsProvider(submission.talentId));
      ref.invalidate(companySubmissionsProvider(submission.companyId));
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final submissionActionsProvider =
    AsyncNotifierProvider<SubmissionActions, void>(SubmissionActions.new);
