import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/challenge_provider.dart';

class ChallengeDetailPage extends ConsumerWidget {
  const ChallengeDetailPage({required this.challengeId, super.key});

  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(challengeByIdProvider(challengeId));

    return Scaffold(
      appBar: AppBar(title: const Text('Challenge details')),
      body: challengeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _MessageState(
          icon: Icons.error_outline,
          message: 'Unable to load this challenge. Please try again.',
          action: TextButton(
            onPressed: () => ref.invalidate(challengeByIdProvider(challengeId)),
            child: const Text('Retry'),
          ),
        ),
        data: (challenge) {
          if (challenge == null) {
            return const _MessageState(
              icon: Icons.search_off,
              message: 'This challenge could not be found.',
            );
          }

          final deadline = MaterialLocalizations.of(context)
              .formatMediumDate(challenge.deadline.toLocal());
          final canApply = challenge.isOpen && !challenge.isPastDeadline;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                challenge.title,
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(challenge.category)),
                  Chip(label: Text(challenge.status.name.toUpperCase())),
                  Chip(label: Text('Deadline: $deadline')),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'About this challenge',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(challenge.description),
              const SizedBox(height: 24),
              Text(
                'Requirements',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...challenge.requirements.map(
                (requirement) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle_outline, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(requirement)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),
              FilledButton.icon(
                onPressed: canApply
                    ? () => context.push('/talent/solution/${challenge.id}')
                    : null,
                icon: const Icon(Icons.send_outlined),
                label: Text(
                  canApply ? 'Submit a solution' : 'Challenge unavailable',
                ),
              ),
              if (challenge.isOpen && challenge.isPastDeadline) ...[
                const SizedBox(height: 8),
                const Text(
                  'The submission deadline has passed.',
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          ?action,
        ],
      ),
    ),
  );
}
