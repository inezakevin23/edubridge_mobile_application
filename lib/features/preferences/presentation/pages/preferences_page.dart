import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/app_preferences.dart';
import '../providers/preferences_providers.dart';
import '../widgets/preference_section_card.dart';
import '../widgets/preference_switch_tile.dart';
import '../widgets/theme_mode_selector.dart';

class PreferencesPage extends ConsumerWidget {
  const PreferencesPage({super.key});

  Future<void> _runAction(
    BuildContext context,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save preference: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preferencesState = ref.watch(preferencesControllerProvider);
    final controller = ref.read(preferencesControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Preferences')),
      body: preferencesState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.settings_outlined, size: 42),
                const SizedBox(height: 12),
                const Text('Your preferences could not be loaded.'),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(preferencesControllerProvider),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (preferences) =>
            _buildPreferences(context, preferences, controller),
      ),
    );
  }

  Widget _buildPreferences(
    BuildContext context,
    AppPreferences preferences,
    PreferencesController controller,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Choose how EduBridge looks and how you receive updates.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        PreferenceSectionCard(
          title: 'Appearance',
          icon: Icons.palette_outlined,
          children: [
            ThemeModeSelector(
              value: preferences.themeMode,
              onChanged: (value) =>
                  _runAction(context, () => controller.setThemeMode(value)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        PreferenceSectionCard(
          title: 'Notifications',
          icon: Icons.notifications_outlined,
          children: [
            PreferenceSwitchTile(
              title: 'Challenge updates',
              subtitle: 'Allow the app to show updates about challenges and submissions.',
              icon: Icons.notifications_active_outlined,
              value: preferences.challengeNotificationsEnabled,
              onChanged: (value) => _runAction(
                context,
                () => controller.setChallengeNotificationsEnabled(value),
              ),
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),
            PreferenceSwitchTile(
              title: 'Email updates',
              subtitle: 'Receive relevant EduBridge updates by email.',
              icon: Icons.mail_outline,
              value: preferences.emailUpdatesEnabled,
              onChanged: (value) => _runAction(
                context,
                () => controller.setEmailUpdatesEnabled(value),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () => _runAction(context, controller.resetToDefaults),
          icon: const Icon(Icons.restart_alt),
          label: const Text('Reset preferences'),
        ),
        const SizedBox(height: 12),
        Text(
          'Your choices are saved on this device for your signed-in account '
          'and restored when you open EduBridge again.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
