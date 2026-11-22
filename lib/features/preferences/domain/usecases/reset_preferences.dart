import '../entities/app_preferences.dart';
import '../repositories/preferences_repository.dart';

class ResetPreferences {
  const ResetPreferences(this._repository);

  final PreferencesRepository _repository;

  Future<void> call(String userId) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'User ID cannot be empty.');
    }
    await _repository.reset(userId);
  }
}
