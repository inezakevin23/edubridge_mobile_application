import 'package:edubridge_mobile_application/features/profiles/domain/use_cases/get_profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/firestore_profile_data_source.dart';
import '../../data/repositories/profile_repository_impl.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../../domain/use_cases/save_profile.dart';
import '../../domain/use_cases/watch_profile.dart';

final profileDataSourceProvider = Provider<FirestoreProfileDataSource>((ref) {
  return FirestoreProfileDataSource(ref.watch(firestoreProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepositoryImpl(ref.watch(profileDataSourceProvider));
});

final getProfileUseCaseProvider = Provider<GetProfile>((ref) {
  return GetProfile(ref.watch(profileRepositoryProvider));
});

final watchProfileUseCaseProvider = Provider<WatchProfile>((ref) {
  return WatchProfile(ref.watch(profileRepositoryProvider));
});

final saveProfileUseCaseProvider = Provider<SaveProfile>((ref) {
  return SaveProfile(ref.watch(profileRepositoryProvider));
});

final profileByIdProvider = FutureProvider.family<UserProfile?, String>((
  ref,
  userId,
) {
  return ref.watch(getProfileUseCaseProvider)(userId);
});

final profileStreamProvider = StreamProvider.autoDispose
    .family<UserProfile?, String>((ref, userId) {
      return ref.watch(watchProfileUseCaseProvider)(userId);
    });
