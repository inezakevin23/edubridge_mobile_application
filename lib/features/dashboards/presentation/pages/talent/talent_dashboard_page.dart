import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../submissions/domain/entities/submission.dart';
import '../../../../submissions/presentation/providers/submission_provider.dart';
import '../../../../submissions/presentation/widgets/submission_card.dart';

class TalentDashboardPage extends ConsumerWidget {
  const TalentDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(submissionAuthStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Talent Dashboard')),
      body: authAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const _DashboardMessage(
          message: 'Unable to verify your account. Please try again.',
        ),
        data: (user) {
          if (user == null) {
            return const _DashboardMessage(message: 'Please sign in to continue.');
          }
          final submissionsAsync = ref.watch(talentSubmissionsProvider(user.uid));
          return submissionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => _DashboardMessage(
              message: 'Unable to load your dashboard.',
              onRetry: () => ref.invalidate(talentSubmissionsProvider(user.uid)),
            ),
            data: (submissions) => _buildDashboard(context, ref, user.uid, submissions),
          );
        },
      ),
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    String talentId,
    List<Submission> submissions,
  ) {
    final submitted = submissions
        .where((item) => item.status == SubmissionStatus.submitted)
        .length;
    final inReview = submissions
        .where((item) => item.status == SubmissionStatus.underReview)
        .length;
    final reviewed = submissions
        .where((item) => item.status == SubmissionStatus.reviewed)
        .length;
    final shortlisted = submissions.where((item) => item.isShortlisted).length;

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(talentSubmissionsProvider(talentId)),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Turn your skills into practical experience.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explore real-world challenges, submit solutions and track feedback from companies.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () => context.push('/challenges'),
            icon: const Icon(Icons.search),
            label: const Text('Explore challenges'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => context.push('/talent/submissions'),
            icon: const Icon(Icons.assignment_outlined),
            label: const Text('View all my submissions'),
          ),
          const SizedBox(height: 24),
          Text('Your progress', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.9,
            children: [
              _ProgressCard(label: 'Submitted', value: submitted, icon: Icons.send_outlined),
              _ProgressCard(label: 'Under review', value: inReview, icon: Icons.rate_review_outlined),
              _ProgressCard(label: 'Reviewed', value: reviewed, icon: Icons.done_all),
              _ProgressCard(label: 'Shortlisted', value: shortlisted, icon: Icons.star_outline),
            ],
          ),
          const SizedBox(height: 24),
          Text('Recent submissions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (submissions.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Your submissions will appear here after you complete a challenge.',
                textAlign: TextAlign.center,
              ),
            )
          else
            ...submissions.take(3).map(
                  (submission) => SubmissionCard(
                    submission: submission,
                    onTap: () => context.push('/submissions/${submission.id}'),
                  ),
                ),
        ],
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value.toString(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardMessage extends StatelessWidget {
  const _DashboardMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              if (onRetry != null)
                TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ),
        ),
      );
}
