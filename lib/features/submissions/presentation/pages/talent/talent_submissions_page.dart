import 'package:edubridge_mobile_application/config/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../auth/domain/entities/auth_user.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../challenges/presentation/providers/challenge_provider.dart';
import '../../../../dashboards/presentation/widgets/dashboard_header.dart';
import '../../../../dashboards/presentation/widgets/dashboard_navigation.dart';
import '../../../../feedback/domain/entities/submission_feedback.dart';
import '../../../../feedback/presentation/providers/feedback_providers.dart';
import '../../../../profiles/presentation/providers/profile_provider.dart';
import '../../../domain/entities/submission.dart';
import '../../providers/submission_provider.dart';

class TalentSubmissionsPage extends ConsumerWidget {
  const TalentSubmissionsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final user = authAsync.asData?.value;
    final profileAsync = user == null
        ? null
        : ref.watch(profileStreamProvider(user.id));
    final scorePoints = profileAsync?.asData?.value?.scorePoints ?? 0;
    final isTalent = user?.role == UserRole.talent;
    final isCompany = user?.role == UserRole.company;

    return Scaffold(
      appBar: DashboardHeader(
        notificationUserId: user?.id,
        scorePoints: isTalent ? scorePoints : null,
        trailingLabel: isCompany ? 'Company' : null,
      ),
      bottomNavigationBar: user == null
          ? null
          : DashboardNavigation(
              currentIndex: 2,
              isCompany: isCompany,
              onIndexChanged: (index) {
                switch (index) {
                  case 0:
                    context.go(
                      isCompany ? '/company/dashboard' : '/talent/dashboard',
                    );
                  case 1:
                    context.go(
                      isCompany ? '/company/challenges/manage' : '/challenges',
                    );
                  case 2:
                    context.go(
                      isCompany
                          ? '/company/submissions'
                          : '/talent/submissions',
                    );
                  case 3:
                    context.go(
                      isCompany ? '/company/profile' : '/talent/profile',
                    );
                }
              },
            ),
      body: authAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const _FeedbackMessage(
          message: 'Unable to verify your account. Please try again.',
        ),
        data: (user) {
          if (user == null) {
            return const _FeedbackMessage(
              message: 'Please sign in to view your feedback.',
            );
          }
          if (user.role != UserRole.talent) {
            return const _FeedbackMessage(
              message: 'Feedback is available to Talent accounts.',
            );
          }
          return _TalentFeedbackList(
            userId: user.id,
            scorePoints: scorePoints,
            scoreLoadFailed: profileAsync?.hasError ?? false,
          );
        },
      ),
    );
  }
}

class _TalentFeedbackList extends ConsumerWidget {
  const _TalentFeedbackList({
    required this.userId,
    required this.scorePoints,
    required this.scoreLoadFailed,
  });

  final String userId;
  final int scorePoints;
  final bool scoreLoadFailed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(talentSubmissionsProvider(userId));
    return submissionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => _FeedbackMessage(
        message: 'Unable to load your feedback.',
        onRetry: () => ref.invalidate(talentSubmissionsProvider(userId)),
      ),
      data: (submissions) {
        final shortlistedCount = submissions
            .where((submission) => submission.isShortlisted)
            .length;
        final pendingCount = submissions
            .where(
              (submission) => submission.status != SubmissionStatus.reviewed,
            )
            .length;

        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(talentSubmissionsProvider(userId)),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(14, 18, 14, 24),
            children: [
              const Text(
                'YOUR PROGRESS',
                style: TextStyle(
                  color: Color(0xFFC09AFF),
                  fontSize: AppTypography.micro,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'My Feedback',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppTypography.title,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Reviews and scores from companies on your submitted solutions.',
                style: TextStyle(
                  color: Color(0xFF85899A),
                  fontSize: AppTypography.micro,
                  height: 1.5,
                ),
              ),
              if (scoreLoadFailed) ...[
                const SizedBox(height: 5),
                const Text(
                  'Your score points could not be loaded.',
                  style: TextStyle(
                    color: Color(0xFFFFB423),
                    fontSize: AppTypography.micro,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _ProgressMetrics(
                totalSubmissions: submissions.length,
                scorePoints: scorePoints,
                shortlistedCount: shortlistedCount,
                pendingCount: pendingCount,
              ),
              const SizedBox(height: 12),
              if (submissions.isEmpty)
                const _FeedbackMessage(
                  icon: Icons.forum_outlined,
                  message: 'You have no feedback yet. Submit a challenge solution to get started.',
                )
              else
                ...submissions.map(
                  (submission) =>
                      _FeedbackSubmissionCard(submission: submission),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ProgressMetrics extends StatelessWidget {
  const _ProgressMetrics({
    required this.totalSubmissions,
    required this.scorePoints,
    required this.shortlistedCount,
    required this.pendingCount,
  });

  final int totalSubmissions;
  final int scorePoints;
  final int shortlistedCount;
  final int pendingCount;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Expanded(
            child: _MetricCard(
              value: '$totalSubmissions',
              label: 'Total Submissions',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MetricCard(value: '$scorePoints', label: 'Score Points'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: _MetricCard(
              value: '$shortlistedCount',
              label: 'Times Shortlisted',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _MetricCard(
              value: '$pendingCount',
              label: 'Pending Reviews',
            ),
          ),
        ],
      ),
    ],
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    height: 55,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: const Color(0xFF202434),
      border: Border.all(color: const Color(0xFF2A3042)),
      borderRadius: BorderRadius.circular(9),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: AppTypography.body,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF85899A),
            fontSize: AppTypography.micro,
          ),
        ),
      ],
    ),
  );
}

class _FeedbackSubmissionCard extends ConsumerWidget {
  const _FeedbackSubmissionCard({required this.submission});

  final Submission submission;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(
      challengeByIdProvider(submission.challengeId),
    );
    final feedbackAsync = ref.watch(submissionFeedbackProvider(submission.id));
    final companyProfileAsync = ref.watch(
      profileStreamProvider(submission.companyId),
    );
    final feedback = feedbackAsync.asData?.value;
    final challengeTitle =
        challengeAsync.asData?.value?.title ??
        (challengeAsync.hasError
            ? 'Challenge details unavailable'
            : 'Challenge');
    final companyName =
        companyProfileAsync.asData?.value?.displayName.trim() ??
        (companyProfileAsync.hasError
            ? 'Company details unavailable'
            : 'Company reviewer');
    final reviewDate =
        feedback?.updatedAt ?? feedback?.createdAt ?? submission.reviewedAt;
    final statusLabel = switch (submission.status) {
      SubmissionStatus.reviewed => 'Reviewed',
      SubmissionStatus.underReview => 'In review',
      SubmissionStatus.submitted => 'Pending review',
    };
    final statusColor = submission.status == SubmissionStatus.reviewed
        ? const Color(0xFF20C997)
        : const Color(0xFFFFB423);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFF202434),
        border: Border.all(color: const Color(0xFF2A3042)),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 11,
                backgroundColor: const Color(0xFF30204E),
                child: Text(
                  _initials(challengeTitle),
                  style: const TextStyle(
                    color: Color(0xFFC09AFF),
                    fontSize: AppTypography.micro,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challengeTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppTypography.micro,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    if (submission.isShortlisted) ...[
                      const SizedBox(height: 4),
                      const _StatusTag(
                        label: 'Shortlisted',
                        color: Color(0xFFFFB423),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (feedback != null)
                    Text(
                      '${feedback.pointsAwarded}/100',
                      style: const TextStyle(
                        color: Color(0xFFFFB423),
                        fontSize: AppTypography.micro,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  const SizedBox(height: 3),
                  _StatusTag(label: statusLabel, color: statusColor),
                ],
              ),
            ],
          ),
          const SizedBox(height: 9),
          const Divider(height: 1, color: Color(0xFF2A3042)),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 9,
                backgroundColor: const Color(0xFF30204E),
                child: Text(
                  _initials(companyName),
                  style: const TextStyle(
                    color: Color(0xFFC09AFF),
                    fontSize: AppTypography.micro,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      companyName.isEmpty ? 'Company reviewer' : companyName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE0E2E9),
                        fontSize: AppTypography.micro,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      reviewDate == null
                          ? 'Reviewer'
                          : 'Reviewer · Reviewed ${MaterialLocalizations.of(context).formatMediumDate(reviewDate.toLocal())}',
                      style: const TextStyle(
                        color: Color(0xFF85899A),
                        fontSize: AppTypography.micro,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          _FeedbackSummary(
            feedbackAsync: feedbackAsync,
            onRetry: () =>
                ref.invalidate(submissionFeedbackProvider(submission.id)),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 30,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/submissions/${submission.id}'),
              icon: const Icon(Icons.visibility_outlined, size: 12),
              label: const Text(
                'View Solution',
                style: TextStyle(
                  fontSize: AppTypography.micro,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                foregroundColor: const Color(0xFFE0E2E9),
                backgroundColor: const Color(0xFF171B29),
                side: const BorderSide(color: Color(0xFF30364A)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeedbackSummary extends StatelessWidget {
  const _FeedbackSummary({required this.feedbackAsync, required this.onRetry});

  final AsyncValue<SubmissionFeedback?> feedbackAsync;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => feedbackAsync.when(
    loading: () => const SizedBox(
      height: 30,
      child: Center(
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 1.5),
        ),
      ),
    ),
    error: (error, stackTrace) => Row(
      children: [
        const Expanded(
          child: Text(
            'Feedback could not be loaded.',
            style: TextStyle(
              color: Color(0xFFFF8B8B),
              fontSize: AppTypography.micro,
            ),
          ),
        ),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    ),
    data: (feedback) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFF11141D),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        feedback == null
            ? 'Feedback has not been provided for this submission yet.'
            : feedback.summary,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFFB8BDCB),
          fontSize: AppTypography.micro,
          height: 1.4,
        ),
      ),
    ),
  );
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.13),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: color,
        fontSize: AppTypography.micro,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _FeedbackMessage extends StatelessWidget {
  const _FeedbackMessage({
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
          Icon(icon, size: 40, color: const Color(0xFF9A72E8)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFB8BDCB),
              fontSize: AppTypography.caption,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ],
      ),
    ),
  );
}

String _initials(String value) {
  final words = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty);
  return words.take(2).map((word) => word[0]).join().toUpperCase();
}
