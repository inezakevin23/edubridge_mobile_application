import '../../domain/entities/app_preferences.dart';
import '../../domain/repositories/preferences_repository.dart';
import '../datasources/preferences_local_data_source.dart';

class PreferencesRepositoryImpl implements PreferencesRepository {
  const PreferencesRepositoryImpl(this._localDataSource);

  final PreferencesLocalDataSource _localDataSource;

  @override
  Future<AppPreferences> load(String userId) =>
      _localDataSource.load(userId);

  @override
  Future<void> save(String userId, AppPreferences preferences) =>
      _localDataSource.save(userId, preferences);

  @override
  Future<void> reset(String userId) => _localDataSource.reset(userId);
}
