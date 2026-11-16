import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../challenges/domain/entities/challenge.dart';
import '../../../challenges/presentation/pages/company/create_challenge_page.dart';
import '../../../challenges/presentation/pages/company/manage_challenges_page.dart';
import '../../../challenges/presentation/providers/challenge_provider.dart';
import '../../../challenges/presentation/widgets/challenge_card.dart';

class CompanyDashboardPage extends ConsumerWidget {
  const CompanyDashboardPage({required this.companyId, super.key});

  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(companyChallengesProvider(companyId));

    return Scaffold(
      appBar: AppBar(title: const Text('Company Dashboard')),
      body: challengesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Unable to load your dashboard.'),
              TextButton(
                onPressed: () =>
                    ref.invalidate(companyChallengesProvider(companyId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (challenges) {
          final openCount = challenges
              .where((challenge) => challenge.status == ChallengeStatus.open)
              .length;
          final closedCount = challenges.length - openCount;

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(companyChallengesProvider(companyId)),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Manage your opportunities',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Publish real business challenges and review solutions from Talent.',
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _StatisticCard(
                        label: 'Total challenges',
                        value: challenges.length.toString(),
                        icon: Icons.work_outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatisticCard(
                        label: 'Open',
                        value: openCount.toString(),
                        icon: Icons.lock_open_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatisticCard(
                        label: 'Closed',
                        value: closedCount.toString(),
                        icon: Icons.lock_outline,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => CreateChallengePage(companyId: companyId),
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Create a challenge'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ManageChallengesPage(companyId: companyId),
                    ),
                  ),
                  icon: const Icon(Icons.manage_search),
                  label: const Text('Manage all challenges'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => context.push('/company/submissions'),
                  icon: const Icon(Icons.inbox_outlined),
                  label: const Text('View received submissions'),
                ),
                const SizedBox(height: 28),
                Text(
                  'Recent challenges',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (challenges.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Text(
                      'Your published challenges will appear here.',
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  ...challenges
                      .take(3)
                      .map((challenge) => ChallengeCard(challenge: challenge)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
