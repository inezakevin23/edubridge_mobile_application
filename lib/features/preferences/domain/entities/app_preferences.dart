/// Values that control the local EduBridge app experience.
///
/// These are non-sensitive UI preferences. Do not store credentials,
/// authentication tokens, or other critical data in SharedPreferences.
enum AppThemeMode { system, light, dark }

class AppPreferences {
  const AppPreferences({
    this.themeMode = AppThemeMode.system,
    this.challengeNotificationsEnabled = true,
    this.emailUpdatesEnabled = true,
  });

  static const defaults = AppPreferences();

  final AppThemeMode themeMode;
  final bool challengeNotificationsEnabled;
  final bool emailUpdatesEnabled;

  AppPreferences copyWith({
    AppThemeMode? themeMode,
    bool? challengeNotificationsEnabled,
    bool? emailUpdatesEnabled,
  }) {
    return AppPreferences(
      themeMode: themeMode ?? this.themeMode,
      challengeNotificationsEnabled:
          challengeNotificationsEnabled ?? this.challengeNotificationsEnabled,
      emailUpdatesEnabled: emailUpdatesEnabled ?? this.emailUpdatesEnabled,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AppPreferences &&
            other.themeMode == themeMode &&
            other.challengeNotificationsEnabled ==
                challengeNotificationsEnabled &&
            other.emailUpdatesEnabled == emailUpdatesEnabled;
  }

  @override
  int get hashCode => Object.hash(
        themeMode,
        challengeNotificationsEnabled,
        emailUpdatesEnabled,
      );
}

AppThemeMode appThemeModeFromStorage(String? value) {
  return AppThemeMode.values.firstWhere(
    (mode) => mode.name == value,
    orElse: () => AppThemeMode.system,
  );
}
