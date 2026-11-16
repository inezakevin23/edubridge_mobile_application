import 'package:edubridge_mobile_application/features/profiles/presentation/providers/profile_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../widgets/profile_editor.dart';

class TalentProfilePage extends ConsumerWidget {
  const TalentProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () => const _LoadingPage(),
      error: (error, _) =>
          _MessagePage(message: 'Could not load your account: $error'),
      data: (user) {
        if (user == null) {
          return const _MessagePage(
            message: 'Please sign in to view your profile.',
          );
        }
        if (user.requiresAccountSetup) {
          return const _MessagePage(
            message: 'Complete account setup before editing your profile.',
          );
        }
        if (user.role != UserRole.talent) {
          return const _MessagePage(
            message: 'This page is only available to Talent accounts.',
          );
        }
        final profile = ref.watch(profileStreamProvider(user.id));
        return profile.when(
          loading: () => const _LoadingPage(),
          error: (error, _) =>
              _MessagePage(message: 'Could not load your profile: $error'),
          data: (value) => ProfileEditor(
            userId: user.id,
            role: 'talent',
            email: user.email,
            initialName: user.displayName,
            profile: value,
            isCompany: false,
          ),
        );
      },
    );
  }
}

class _LoadingPage extends StatelessWidget {
  const _LoadingPage();
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

class _MessagePage extends StatelessWidget {
  const _MessagePage({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    ),
  );
}
