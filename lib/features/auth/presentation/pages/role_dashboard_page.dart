import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/auth_user.dart';
import '../providers/auth_providers.dart';

/// Temporary role-aware landing page. Member 1 owns the route contract;
/// replace its body with Member 2/3 dashboard widgets during integration.
class RoleDashboardPage extends ConsumerWidget {
  const RoleDashboardPage({super.key, required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final title = switch (role) {
      UserRole.talent => 'Talent dashboard',
      UserRole.company => 'Company dashboard',
      UserRole.admin => 'Admin dashboard',
    };
    final description = switch (role) {
      UserRole.talent => 'Browse real-world challenges, submit solutions, and track feedback.',
      UserRole.company => 'Publish business challenges and review talent submissions.',
      UserRole.admin => 'Administration tools will be connected by the project team.',
    };

    final welcomeName = user == null || user.displayName.isEmpty
        ? ''
        : ', ${user.displayName}';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.account_circle_outlined),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await ref.read(authControllerProvider).signOut();
              if (context.mounted) context.go('/sign-in');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Welcome$welcomeName',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(description),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: () => context.go('/profile'),
                  icon: const Icon(Icons.person_outline),
                  label: const Text('Manage profile'),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Integration note: connect this route to the dashboard owned by '
                  'the relevant feature member. See docs/member1/router_integration.md.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
