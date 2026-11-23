import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/datasources/preferences_local_data_source.dart';
import '../../data/repositories/preferences_repository_impl.dart';
import '../../domain/entities/app_preferences.dart';
import '../../domain/repositories/preferences_repository.dart';
import '../../domain/usecases/load_preferences.dart';
import '../../domain/usecases/reset_preferences.dart';
import '../../domain/usecases/save_preferences.dart';

final sharedPreferencesAsyncProvider = Provider<SharedPreferencesAsync>((ref) {
  return SharedPreferencesAsync();
});

final preferencesLocalDataSourceProvider =
    Provider<PreferencesLocalDataSource>((ref) {
  return PreferencesLocalDataSource(ref.watch(sharedPreferencesAsyncProvider));
});

final preferencesRepositoryProvider = Provider<PreferencesRepository>((ref) {
  return PreferencesRepositoryImpl(
    ref.watch(preferencesLocalDataSourceProvider),
  );
});

final loadPreferencesUseCaseProvider = Provider<LoadPreferences>((ref) {
  return LoadPreferences(ref.watch(preferencesRepositoryProvider));
});

final savePreferencesUseCaseProvider = Provider<SavePreferences>((ref) {
  return SavePreferences(ref.watch(preferencesRepositoryProvider));
});

final resetPreferencesUseCaseProvider = Provider<ResetPreferences>((ref) {
  return ResetPreferences(ref.watch(preferencesRepositoryProvider));
});

/// Loads settings when Member 1's Firebase auth state resolves. Watching the
/// auth provider also reloads settings when another account signs in.
final preferencesControllerProvider =
    AsyncNotifierProvider<PreferencesController, AppPreferences>(
  PreferencesController.new,
);

class PreferencesController extends AsyncNotifier<AppPreferences> {
  String? _userId;

  @override
  Future<AppPreferences> build() async {
    final authState = ref.watch(authStateProvider);

    if (authState.isLoading && !authState.hasValue) {
      _userId = null;
      return AppPreferences.defaults;
    }

    if (authState.hasError) {
      Error.throwWithStackTrace(
        authState.error!,
        authState.stackTrace ?? StackTrace.current,
      );
    }

    final user = authState.value;
    if (user == null || user.requiresAccountSetup) {
      _userId = null;
      return AppPreferences.defaults;
    }

    _userId = user.id;
    final loadPreferences = ref.watch(loadPreferencesUseCaseProvider);
    return loadPreferences(user.id);
  }

  Future<void> setThemeMode(AppThemeMode themeMode) {
    return _update((current) => current.copyWith(themeMode: themeMode));
  }

  Future<void> setChallengeNotificationsEnabled(bool enabled) {
    return _update(
      (current) => current.copyWith(
        challengeNotificationsEnabled: enabled,
      ),
    );
  }

  Future<void> setEmailUpdatesEnabled(bool enabled) {
    return _update(
      (current) => current.copyWith(emailUpdatesEnabled: enabled),
    );
  }

  Future<void> resetToDefaults() async {
    final userId = _userId;
    if (userId == null) {
      state = const AsyncData(AppPreferences.defaults);
      return;
    }

    final previousState = state;
    state = const AsyncData(AppPreferences.defaults);
    try {
      await ref.read(resetPreferencesUseCaseProvider)(userId);
    } catch (error, stackTrace) {
      state = previousState;
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  Future<void> _update(
    AppPreferences Function(AppPreferences current) transform,
  ) async {
    final userId = _userId;
    if (userId == null) {
      throw StateError('Preferences can only be changed by a signed-in user.');
    }

    final previousState = state;
    final current = state.value ?? AppPreferences.defaults;
    final updated = transform(current);
    state = AsyncData(updated);

    try {
      await ref.read(savePreferencesUseCaseProvider)(userId, updated);
    } catch (error, stackTrace) {
      state = previousState;
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

/// Converts the domain enum to Flutter's Material theme setting.
ThemeMode toMaterialThemeMode(AppThemeMode mode) {
  return switch (mode) {
    AppThemeMode.system => ThemeMode.system,
    AppThemeMode.light => ThemeMode.light,
    AppThemeMode.dark => ThemeMode.dark,
  };
}
