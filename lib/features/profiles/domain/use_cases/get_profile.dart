import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class GetProfile {
  const GetProfile(this.repository);
  final ProfileRepository repository;

  Future<UserProfile?> call(String userId) => repository.getProfile(userId);
}
