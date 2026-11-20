import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/firestore_profile_data_source.dart';
import '../models/profile_model.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  const ProfileRepositoryImpl(this.dataSource);
  final FirestoreProfileDataSource dataSource;

  @override
  Future<UserProfile?> getProfile(String userId) =>
      dataSource.getProfile(userId);

  @override
  Stream<UserProfile?> watchProfile(String userId) =>
      dataSource.watchProfile(userId);

  @override
  Future<void> createOrUpdateProfile(UserProfile profile) =>
      dataSource.createOrUpdateProfile(
        ProfileModel(
          userId: profile.userId,
          role: profile.role,
          displayName: profile.displayName,
          photoUrl: profile.photoUrl,
          bio: profile.bio,
          headline: profile.headline,
          location: profile.location,
          education: profile.education,
          companyDescription: profile.companyDescription,
          industry: profile.industry,
          website: profile.website,
          createdAt: profile.createdAt,
          updatedAt: profile.updatedAt,
        ),
      );
}
