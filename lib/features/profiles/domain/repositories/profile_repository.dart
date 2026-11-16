import '../entities/user_profile.dart';

abstract interface class ProfileRepository {
  Future<UserProfile?> getProfile(String userId);
  Stream<UserProfile?> watchProfile(String userId);
  Future<void> createOrUpdateProfile(UserProfile profile);
}
