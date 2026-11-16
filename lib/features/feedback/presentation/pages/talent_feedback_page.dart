import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edubridge_mobile/features/feedback/presentation/providers/feedback_providers.dart';
import 'package:edubridge_mobile/features/feedback/presentation/widgets/feedback_details_card.dart';

/// Read-only feedback screen for the talent who owns the submission.
class TalentFeedbackPage extends ConsumerWidget {
  const TalentFeedbackPage({
    required this.submissionId,
    super.key,
  });

  final String submissionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackAsync = ref.watch(submissionFeedbackProvider(submissionId));

    return Scaffold(
      appBar: AppBar(title: const Text('My feedback')),
      body: feedbackAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('Unable to load feedback: $error'),
          ),
        ),
        data: (feedback) {
          if (feedback == null) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Feedback has not been provided for this submission yet.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [FeedbackDetailsCard(feedback: feedback)],
          );
        },
      ),
    );
  }
}
