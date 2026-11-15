import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/challenge.dart';
import '../../providers/challenge_provider.dart';
import '../../widgets/challenge_card.dart';
import 'create_challenge_page.dart';

class ManageChallengesPage extends ConsumerWidget {
  const ManageChallengesPage({required this.companyId, super.key});

  final String companyId;

  Future<void> _edit(BuildContext context, Challenge challenge) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            CreateChallengePage(companyId: companyId, challenge: challenge),
      ),
    );
  }

  Future<void> _changeStatus(
    BuildContext context,
    WidgetRef ref,
    Challenge challenge,
  ) async {
    final nextStatus = challenge.isOpen
        ? ChallengeStatus.closed
        : ChallengeStatus.open;

    if (nextStatus == ChallengeStatus.open && challenge.isPastDeadline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Update the deadline before reopening this challenge.'),
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          challenge.isOpen ? 'Close challenge?' : 'Reopen challenge?',
        ),
        content: Text(
          challenge.isOpen
              ? 'Talent will no longer be able to submit solutions to this challenge.'
              : 'Talent will be able to see and submit solutions to this challenge again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(challenge.isOpen ? 'Close challenge' : 'Reopen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(challengeActionsProvider.notifier)
          .updateChallenge(challenge.copyWith(status: nextStatus));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            challenge.isOpen ? 'Challenge closed.' : 'Challenge reopened.',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update the challenge.')),
      );
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Challenge challenge,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete challenge?'),
        content: const Text(
          'This permanently deletes the challenge. Challenges that already have submissions cannot be deleted; close those challenges instead.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref
          .read(challengeActionsProvider.notifier)
          .deleteChallenge(challengeId: challenge.id, companyId: companyId);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Challenge deleted.')));
    } catch (error) {
      if (!context.mounted) return;
      final message = error.toString().contains('already has submissions')
          ? 'This challenge has submissions. Close it instead of deleting it.'
          : 'Could not delete the challenge. Please try again.';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(companyChallengesProvider(companyId));

    return Scaffold(
      appBar: AppBar(title: const Text('Manage challenges')),
      body: challengesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Could not load your challenges.'),
              TextButton(
                onPressed: () =>
                    ref.invalidate(companyChallengesProvider(companyId)),
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
        data: (challenges) {
          if (challenges.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: Text(
                  'You have not published any challenges yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(companyChallengesProvider(companyId)),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: challenges.length,
              itemBuilder: (context, index) {
                final challenge = challenges[index];
                return ChallengeCard(
                  challenge: challenge,
                  trailing: PopupMenuButton<String>(
                    tooltip: 'Challenge actions',
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _edit(context, challenge);
                          break;
                        case 'toggle':
                          _changeStatus(context, ref, challenge);
                          break;
                        case 'delete':
                          _delete(context, ref, challenge);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(challenge.isOpen ? 'Close' : 'Reopen'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
