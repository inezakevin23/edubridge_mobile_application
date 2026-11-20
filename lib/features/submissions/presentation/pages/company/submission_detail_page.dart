import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../challenges/presentation/providers/challenge_provider.dart';
import '../../../domain/entities/submission.dart';
import '../../providers/submission_provider.dart';
import '../../widgets/submission_status_chip.dart';

class SubmissionDetailPage extends ConsumerWidget {
  const SubmissionDetailPage({required this.submissionId, super.key});

  final String submissionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(submissionAuthStateProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Submission details')),
      body: authAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const _DetailMessage(
          message: 'Unable to verify your account. Please try again.',
        ),
        data: (user) {
          if (user == null) {
            return const _DetailMessage(message: 'Please sign in to view this submission.');
          }
          final submissionAsync = ref.watch(submissionByIdProvider(submissionId));
          return submissionAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => const _DetailMessage(
              message: 'Unable to load this submission.',
            ),
            data: (submission) {
              if (submission == null) {
                return const _DetailMessage(message: 'This submission could not be found.');
              }
              final isTalent = user.uid == submission.talentId;
              final isCompany = user.uid == submission.companyId;
              if (!isTalent && !isCompany) {
                return const _DetailMessage(
                  message: 'You are not permitted to view this submission.',
                );
              }
              return _SubmissionContent(
                submission: submission,
                isCompany: isCompany,
                isTalent: isTalent,
              );
            },
          );
        },
      ),
    );
  }
}

class _SubmissionContent extends ConsumerWidget {
  const _SubmissionContent({
    required this.submission,
    required this.isCompany,
    required this.isTalent,
  });

  final Submission submission;
  final bool isCompany;
  final bool isTalent;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(challengeByIdProvider(submission.challengeId));
    final actionsAsync = ref.watch(submissionActionsProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text(
          challengeAsync.maybeWhen(
            data: (challenge) => challenge?.title ?? 'Challenge submission',
            orElse: () => 'Challenge submission',
          ),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            SubmissionStatusChip(status: submission.status),
            if (submission.isShortlisted)
              const Chip(avatar: Icon(Icons.star, size: 16), label: Text('Shortlisted')),
          ],
        ),
        const SizedBox(height: 20),
        Text('Submitted solution', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SelectableText(submission.solutionText),
          ),
        ),
        if (submission.attachmentUrls.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Supporting links', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          ...submission.attachmentUrls.map(
            (url) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.link),
              title: SelectableText(url),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _MetadataRow(label: 'Talent ID', value: submission.talentId),
        _MetadataRow(label: 'Challenge ID', value: submission.challengeId),
        _MetadataRow(
          label: 'Submitted',
          value: MaterialLocalizations.of(context).formatMediumDate(
            submission.submittedAt.toLocal(),
          ),
        ),
        if (submission.reviewedAt != null)
          _MetadataRow(
            label: 'Reviewed',
            value: MaterialLocalizations.of(context).formatMediumDate(
              submission.reviewedAt!.toLocal(),
            ),
          ),
        const SizedBox(height: 24),
        if (isCompany) ...[
          Text('Review actions', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (submission.status == SubmissionStatus.submitted)
            FilledButton.icon(
              onPressed: actionsAsync.isLoading
                  ? null
                  : () => _runAction(
                        context,
                        ref,
                        status: SubmissionStatus.underReview,
                        isShortlisted: submission.isShortlisted,
                      ),
              icon: const Icon(Icons.rate_review_outlined),
              label: const Text('Start reviewing'),
            ),
          if (submission.status == SubmissionStatus.submitted ||
              submission.status == SubmissionStatus.underReview)
            OutlinedButton.icon(
              onPressed: actionsAsync.isLoading
                  ? null
                  : () => _runAction(
                        context,
                        ref,
                        status: SubmissionStatus.reviewed,
                        isShortlisted: submission.isShortlisted,
                      ),
              icon: const Icon(Icons.done_all),
              label: const Text('Mark as reviewed'),
            ),
          if (submission.status != SubmissionStatus.submitted)
            OutlinedButton.icon(
              onPressed: actionsAsync.isLoading
                  ? null
                  : () => _runAction(
                        context,
                        ref,
                        status: submission.status,
                        isShortlisted: !submission.isShortlisted,
                      ),
              icon: Icon(submission.isShortlisted ? Icons.star_border : Icons.star),
              label: Text(submission.isShortlisted ? 'Remove shortlist' : 'Shortlist talent'),
            ),
          const SizedBox(height: 8),
          const Text(
            'Use the Feedback feature to send written feedback. Review status and shortlisting are managed here.',
            style: TextStyle(fontSize: 12),
          ),
        ],
        if (isTalent) ...[
          Text('Your submission', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            submission.canBeEdited
                ? 'You can still edit or withdraw this solution while it has not entered review.'
                : 'The Company has started reviewing this solution. Editing and withdrawal are disabled.',
          ),
          if (submission.isShortlisted) ...[
            const SizedBox(height: 12),
            const ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.star, color: Colors.amber),
              title: Text('You have been shortlisted for this challenge.'),
            ),
          ],
          if (submission.canBeEdited) ...[
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.push('/talent/solution/${submission.challengeId}'),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit solution'),
            ),
            OutlinedButton.icon(
              onPressed: actionsAsync.isLoading
                  ? null
                  : () => _confirmDelete(context, ref),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Withdraw submission'),
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _runAction(
    BuildContext context,
    WidgetRef ref, {
    required SubmissionStatus status,
    required bool isShortlisted,
  }) async {
    try {
      await ref.read(submissionActionsProvider.notifier).updateCompanyReview(
            submission: submission,
            status: status,
            isShortlisted: isShortlisted,
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission review updated.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not update the review. Please try again.')),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Withdraw solution?'),
        content: const Text('This will remove your submission from the challenge. You cannot undo this action.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(submissionActionsProvider.notifier).deleteSubmission(submission);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your submission was withdrawn.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This submission can no longer be withdrawn.')),
      );
    }
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 104,
              child: Text(label, style: Theme.of(context).textTheme.labelMedium),
            ),
            Expanded(child: SelectableText(value)),
          ],
        ),
      );
}

class _DetailMessage extends StatelessWidget {
  const _DetailMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      );
}
