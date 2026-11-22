import '../entities/app_preferences.dart';
import '../repositories/preferences_repository.dart';

class LoadPreferences {
  const LoadPreferences(this._repository);

  final PreferencesRepository _repository;

  Future<AppPreferences> call(String userId) => _repository.load(userId);
}
