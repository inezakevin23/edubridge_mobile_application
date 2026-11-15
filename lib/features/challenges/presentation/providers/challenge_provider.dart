import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edubridge_mobile_application/features/challenges/domain/use_cases/watch_company_challenge.dart';
import 'package:edubridge_mobile_application/features/challenges/domain/use_cases/watch_open_challenge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/firestore_challenge_data_source.dart';
import '../../data/repositories/challenge_repository_impl.dart';
import '../../domain/entities/challenge.dart';
import '../../domain/repositories/challenge_repository.dart';
import '../../domain/use_cases/create_challenge.dart';
import '../../domain/use_cases/delete_challenge.dart';
import '../../domain/use_cases/update_challenge.dart';
import '../../domain/use_cases/watch_challenge_by_id.dart';

final challengeFirestoreProvider = Provider<FirebaseFirestore>(
  (ref) => FirebaseFirestore.instance,
);

final firestoreChallengeDataSourceProvider =
    Provider<FirestoreChallengeDataSource>(
      (ref) =>
          FirestoreChallengeDataSource(ref.watch(challengeFirestoreProvider)),
    );

final challengeRepositoryProvider = Provider<ChallengeRepository>(
  (ref) =>
      ChallengeRepositoryImpl(ref.watch(firestoreChallengeDataSourceProvider)),
);

final watchOpenChallengesUseCaseProvider = Provider<WatchOpenChallenges>(
  (ref) => WatchOpenChallenges(ref.watch(challengeRepositoryProvider)),
);

final watchChallengeByIdUseCaseProvider = Provider<WatchChallengeById>(
  (ref) => WatchChallengeById(ref.watch(challengeRepositoryProvider)),
);

final watchCompanyChallengesUseCaseProvider = Provider<WatchCompanyChallenges>(
  (ref) => WatchCompanyChallenges(ref.watch(challengeRepositoryProvider)),
);

final createChallengeUseCaseProvider = Provider<CreateChallenge>(
  (ref) => CreateChallenge(ref.watch(challengeRepositoryProvider)),
);

final updateChallengeUseCaseProvider = Provider<UpdateChallenge>(
  (ref) => UpdateChallenge(ref.watch(challengeRepositoryProvider)),
);

final deleteChallengeUseCaseProvider = Provider<DeleteChallenge>(
  (ref) => DeleteChallenge(ref.watch(challengeRepositoryProvider)),
);

final openChallengesProvider = StreamProvider.autoDispose<List<Challenge>>(
  (ref) => ref.watch(watchOpenChallengesUseCaseProvider)(),
);

final challengeByIdProvider = StreamProvider.autoDispose
    .family<Challenge?, String>(
      (ref, challengeId) =>
          ref.watch(watchChallengeByIdUseCaseProvider)(challengeId),
    );

final companyChallengesProvider = StreamProvider.autoDispose
    .family<List<Challenge>, String>(
      (ref, companyId) =>
          ref.watch(watchCompanyChallengesUseCaseProvider)(companyId),
    );

/// Centralizes challenge write operations and exposes a shared loading/error
/// state for forms and company management screens.
class ChallengeActions extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<String> createChallenge({
    required String companyId,
    required String title,
    required String description,
    required String category,
    required List<String> requirements,
    required DateTime deadline,
  }) async {
    state = const AsyncLoading();
    try {
      final now = DateTime.now();
      final challenge = Challenge(
        id: '',
        companyId: companyId,
        title: title.trim(),
        description: description.trim(),
        category: category.trim(),
        requirements: requirements,
        deadline: deadline,
        status: ChallengeStatus.open,
        createdAt: now,
        updatedAt: now,
      );
      final id = await ref.read(createChallengeUseCaseProvider)(challenge);
      state = const AsyncData(null);
      return id;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> updateChallenge(Challenge challenge) async {
    state = const AsyncLoading();
    try {
      await ref.read(updateChallengeUseCaseProvider)(
        challenge.copyWith(updatedAt: DateTime.now()),
      );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }

  Future<void> deleteChallenge({
    required String challengeId,
    required String companyId,
  }) async {
    state = const AsyncLoading();
    try {
      await ref.read(deleteChallengeUseCaseProvider)(
        challengeId: challengeId,
        companyId: companyId,
      );
      state = const AsyncData(null);
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      rethrow;
    }
  }
}

final challengeActionsProvider = AsyncNotifierProvider<ChallengeActions, void>(
  ChallengeActions.new,
);
