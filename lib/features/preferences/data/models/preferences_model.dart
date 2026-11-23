import '../../domain/entities/app_preferences.dart';

/// Serialization boundary kept separate from the domain entity.
class PreferencesModel {
  const PreferencesModel({
    required this.themeMode,
    required this.challengeNotificationsEnabled,
    required this.emailUpdatesEnabled,
  });

  final String themeMode;
  final bool challengeNotificationsEnabled;
  final bool emailUpdatesEnabled;

  factory PreferencesModel.fromEntity(AppPreferences preferences) {
    return PreferencesModel(
      themeMode: preferences.themeMode.name,
      challengeNotificationsEnabled: preferences.challengeNotificationsEnabled,
      emailUpdatesEnabled: preferences.emailUpdatesEnabled,
    );
  }

  AppPreferences toEntity() {
    return AppPreferences(
      themeMode: appThemeModeFromStorage(themeMode),
      challengeNotificationsEnabled: challengeNotificationsEnabled,
      emailUpdatesEnabled: emailUpdatesEnabled,
    );
  }
}
