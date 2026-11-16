import 'package:flutter/material.dart';
import 'package:edubridge_mobile/features/feedback/domain/entities/submission_feedback.dart';

class FeedbackDetailsCard extends StatelessWidget {
  const FeedbackDetailsCard({
    required this.feedback,
    super.key,
  });

  final SubmissionFeedback feedback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Overall rating: '),
                Text(
                  '${feedback.rating < 1 ? 1 : (feedback.rating > 5 ? 5 : feedback.rating)} / 5',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.stars_outlined),
                const SizedBox(width: 8),
                Text(
                  '${feedback.pointsAwarded} points awarded',
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _FeedbackSection(
              title: 'Overall feedback',
              content: feedback.summary,
            ),
            if (feedback.strengths.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _FeedbackSection(
                title: 'Strengths',
                content: feedback.strengths,
              ),
            ],
            if (feedback.areasForImprovement.trim().isNotEmpty) ...[
              const SizedBox(height: 16),
              _FeedbackSection(
                title: 'Areas to improve',
                content: feedback.areasForImprovement,
              ),
            ],
            if (feedback.updatedAt != null) ...[
              const SizedBox(height: 16),
              Text(
                'Last updated: ${_formatDate(feedback.updatedAt!)}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final localDate = date.toLocal();
    final day = localDate.day.toString().padLeft(2, '0');
    final month = localDate.month.toString().padLeft(2, '0');
    return '$day/$month/${localDate.year}';
  }
}

class _FeedbackSection extends StatelessWidget {
  const _FeedbackSection({
    required this.title,
    required this.content,
  });

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 6),
        Text(content),
      ],
    );
  }
}
