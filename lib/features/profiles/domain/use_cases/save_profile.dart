import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class SaveProfile {
  const SaveProfile(this.repository);
  final ProfileRepository repository;

  Future<void> call(UserProfile profile) {
    if (profile.userId.trim().isEmpty) {
      throw ArgumentError('A profile must have a user ID.');
    }
    if (profile.role != 'talent' && profile.role != 'company') {
      throw ArgumentError('Only Talent and Company profiles can be edited.');
    }
    if (profile.displayName.trim().isEmpty) {
      throw ArgumentError('Name cannot be empty.');
    }
    if (profile.isCompany && profile.website.trim().isNotEmpty) {
      final uri = Uri.tryParse(profile.website.trim());
      if (uri == null ||
          !uri.hasScheme ||
          !['http', 'https'].contains(uri.scheme)) {
        throw ArgumentError('Website must start with https:// or http://.');
      }
    }
    return repository.createOrUpdateProfile(profile);
  }
}
