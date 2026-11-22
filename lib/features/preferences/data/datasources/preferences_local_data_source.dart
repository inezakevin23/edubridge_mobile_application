import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/app_preferences.dart';

/// Persists simple, non-critical preferences on this device.
///
/// Keys are namespaced by Firebase UID so that two people sharing a device do
/// not inherit one another's appearance or notification settings.
class PreferencesLocalDataSource {
  PreferencesLocalDataSource(this._preferences);

  final SharedPreferencesAsync _preferences;

  String _key(String userId, String name) =>
      'edubridge.preferences.$userId.$name';

  Future<AppPreferences> load(String userId) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'User ID cannot be empty.');
    }

    final values = await Future.wait<Object?>([
      _preferences.getString(_key(userId, 'theme_mode')),
      _preferences.getBool(_key(userId, 'challenge_notifications_enabled')),
      _preferences.getBool(_key(userId, 'email_updates_enabled')),
    ]);

    return AppPreferences(
      themeMode: appThemeModeFromStorage(values[0] as String?),
      challengeNotificationsEnabled: values[1] as bool? ?? true,
      emailUpdatesEnabled: values[2] as bool? ?? true,
    );
  }

  Future<void> save(String userId, AppPreferences preferences) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'User ID cannot be empty.');
    }

    await Future.wait<void>([
      _preferences.setString(
        _key(userId, 'theme_mode'),
        preferences.themeMode.name,
      ),
      _preferences.setBool(
        _key(userId, 'challenge_notifications_enabled'),
        preferences.challengeNotificationsEnabled,
      ),
      _preferences.setBool(
        _key(userId, 'email_updates_enabled'),
        preferences.emailUpdatesEnabled,
      ),
    ]);
  }

  Future<void> reset(String userId) async {
    if (userId.trim().isEmpty) {
      throw ArgumentError.value(userId, 'userId', 'User ID cannot be empty.');
    }

    await Future.wait<void>([
      _preferences.remove(_key(userId, 'theme_mode')),
      _preferences.remove(_key(userId, 'challenge_notifications_enabled')),
      _preferences.remove(_key(userId, 'email_updates_enabled')),
    ]);
  }
}
