import '../entities/app_preferences.dart';

abstract interface class PreferencesRepository {
  Future<AppPreferences> load(String userId);

  Future<void> save(String userId, AppPreferences preferences);

  Future<void> reset(String userId);
}
