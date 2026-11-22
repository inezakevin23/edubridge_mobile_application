import '../entities/app_preferences.dart';
import '../repositories/preferences_repository.dart';

class SavePreferences {
  const SavePreferences(this._repository);

  final PreferencesRepository _repository;

  Future<void> call(String userId, AppPreferences preferences) {
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'User ID cannot be empty.');
    }
    return _repository.save(userId, preferences);
  }
}
