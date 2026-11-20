import 'package:flutter/material.dart';

import '../../domain/entities/submission.dart';
import 'submission_status_chip.dart';

class SubmissionCard extends StatelessWidget {
  const SubmissionCard({
    required this.submission,
    required this.onTap,
    this.challengeTitle,
    super.key,
  });

  final Submission submission;
  final VoidCallback onTap;
  final String? challengeTitle;

  @override
  Widget build(BuildContext context) {
    final date = MaterialLocalizations.of(context).formatMediumDate(
      submission.submittedAt.toLocal(),
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      challengeTitle ?? 'Challenge submission',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                submission.solutionText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SubmissionStatusChip(status: submission.status),
                  if (submission.isShortlisted)
                    const Chip(
                      visualDensity: VisualDensity.compact,
                      avatar: Icon(Icons.star, size: 16),
                      label: Text('Shortlisted'),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Submitted $date',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
