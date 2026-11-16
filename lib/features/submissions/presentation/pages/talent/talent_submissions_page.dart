import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../challenges/presentation/providers/challenge_provider.dart';
import '../../../domain/entities/submission.dart';
import '../../providers/submission_provider.dart';
import '../../widgets/submission_card.dart';

class TalentSubmissionsPage extends ConsumerWidget {
  const TalentSubmissionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(submissionAuthStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My submissions')),
      body: authAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const _SubmissionsMessage(
          message: 'Unable to verify your account. Please try again.',
        ),
        data: (user) {
          if (user == null) {
            return const _SubmissionsMessage(message: 'Please sign in to view your submissions.');
          }
          final submissionsAsync = ref.watch(talentSubmissionsProvider(user.uid));
          return submissionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => _SubmissionsMessage(
              message: 'Unable to load your submissions.',
              onRetry: () => ref.invalidate(talentSubmissionsProvider(user.uid)),
            ),
            data: (submissions) {
              if (submissions.isEmpty) {
                return const _SubmissionsMessage(
                  icon: Icons.assignment_outlined,
                  message: 'You have not submitted any solutions yet. Explore challenges and submit your first solution.',
                );
              }
              return RefreshIndicator(
                onRefresh: () async => ref.invalidate(talentSubmissionsProvider(user.uid)),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: submissions.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) => _TalentSubmissionTile(
                    submission: submissions[index],
                    onTap: () => context.push('/submissions/${submissions[index].id}'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _TalentSubmissionTile extends ConsumerWidget {
  const _TalentSubmissionTile({required this.submission, required this.onTap});

  final Submission submission;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(challengeByIdProvider(submission.challengeId));
    final title = challengeAsync.maybeWhen(data: (challenge) => challenge?.title, orElse: () => null) ?? 'Challenge submission';
    return SubmissionCard(
      submission: submission,
      challengeTitle: title,
      onTap: onTap,
    );
  }
}

class _SubmissionsMessage extends StatelessWidget {
  const _SubmissionsMessage({
    required this.message,
    this.icon = Icons.info_outline,
    this.onRetry,
  });

  final String message;
  final IconData icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 44, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              if (onRetry != null)
                TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      );
}
