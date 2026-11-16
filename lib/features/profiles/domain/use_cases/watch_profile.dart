import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class WatchProfile {
  const WatchProfile(this.repository);
  final ProfileRepository repository;

  Stream<UserProfile?> call(String userId) => repository.watchProfile(userId);
}
