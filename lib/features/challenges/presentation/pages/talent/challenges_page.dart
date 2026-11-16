import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/challenge_provider.dart';
import '../../widgets/challenge_card.dart';

class ChallengesPage extends ConsumerWidget {
  const ChallengesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(openChallengesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Explore challenges')),
      body: challengesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: 'We could not load challenges. Please try again.',
          onRetry: () => ref.invalidate(openChallengesProvider),
        ),
        data: (challenges) {
          final availableChallenges = challenges
              .where((challenge) => !challenge.isPastDeadline)
              .toList(growable: false);
          if (availableChallenges.isEmpty) {
            return const _EmptyState(
              title: 'No open challenges yet',
              message: 'Check back later for opportunities to demonstrate your skills.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(openChallengesProvider),
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: availableChallenges.length,
              separatorBuilder: (_, _) => const SizedBox(height: 0),
              itemBuilder: (context, index) {
                final challenge = availableChallenges[index];
                return ChallengeCard(
                  challenge: challenge,
                  onTap: () => context.push('/challenges/${challenge.id}'),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 48),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 42),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}
