import 'package:edubridge_mobile_application/config/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../challenges/domain/entities/challenge.dart';
import '../../../../challenges/presentation/providers/challenge_provider.dart';
import '../../../../profiles/domain/entities/user_profile.dart';
import '../../../../profiles/presentation/providers/profile_provider.dart';
import '../../../../submissions/domain/entities/submission.dart';
import '../../../../submissions/presentation/providers/submission_provider.dart';
import '../../widgets/dashboard_header.dart';
import '../../widgets/dashboard_navigation.dart';

class TalentDashboardPage extends ConsumerWidget {
  const TalentDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);

    return authAsync.when(
      loading: () => _shell(
        context,
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => _shell(
        context,
        body: _DashboardMessage(
          message: 'Unable to verify your account. Please try again.',
        ),
      ),
      data: (user) {
        if (user == null) {
          return _shell(
            context,
            body: const _DashboardMessage(
              message: 'Please sign in to continue.',
            ),
          );
        }

        final submissionsAsync = ref.watch(talentSubmissionsProvider(user.id));
        final profileAsync = ref.watch(profileStreamProvider(user.id));
        final challengesAsync = ref.watch(openChallengesProvider);
        final profile = profileAsync.asData?.value;
        final scorePoints = profileAsync.hasError
            ? null
            : profileAsync.hasValue
            ? profile?.scorePoints ?? 0
            : null;

        return _shell(
          context,
          scorePoints: scorePoints,
          notificationUserId: user.id,
          body: submissionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => _DashboardMessage(
              message: 'Unable to load your dashboard.',
              onRetry: () =>
                  ref.invalidate(talentSubmissionsProvider(user.id)),
            ),
            data: (submissions) => _buildDashboard(
              context,
              ref,
              user.id,
              submissions,
              profileAsync,
              challengesAsync,
            ),
          ),
        );
      },
    );
  }

  Widget _shell(
    BuildContext context, {
    required Widget body,
    int? scorePoints,
    String? notificationUserId,
  }) {
    return Scaffold(
      appBar: DashboardHeader(
        notificationUserId: notificationUserId,
        scorePoints: scorePoints,
        compactScore: true,
      ),
      bottomNavigationBar: DashboardNavigation(
        currentIndex: 0,
        onIndexChanged: (index) {
          switch (index) {
            case 0:
              context.go('/talent/dashboard');
            case 1:
              context.go('/challenges');
            case 2:
              context.go('/talent/submissions');
            case 3:
              context.go('/talent/profile');
          }
        },
      ),
      body: body,
    );
  }

  Widget _buildDashboard(
    BuildContext context,
    WidgetRef ref,
    String talentId,
    List<Submission> submissions,
    AsyncValue<UserProfile?> profileAsync,
    AsyncValue<List<Challenge>> challengesAsync,
  ) {
    final activeChallenges = submissions
        .where((submission) => submission.status != SubmissionStatus.reviewed)
        .length;
    final shortlisted = submissions
        .where((submission) => submission.isShortlisted)
        .length;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(talentSubmissionsProvider(talentId));
        ref.invalidate(profileStreamProvider(talentId));
        ref.invalidate(openChallengesProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
        children: [
          if (profileAsync.hasError)
            _DashboardMessage(
              message: 'Unable to load your score points.',
              onRetry: () => ref.invalidate(profileStreamProvider(talentId)),
            ),
          GridView.count(
            crossAxisCount: isLandscape ? 4 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.15,
            children: [
              _DashboardStat(label: 'My Submissions', value: submissions.length),
              _DashboardStat(
                label: 'Score Points',
                value: profileAsync.hasValue
                    ? profileAsync.asData?.value?.scorePoints ?? 0
                    : null,
              ),
              _DashboardStat(
                label: 'Active Challenges',
                value: activeChallenges,
              ),
              _DashboardStat(label: 'Shortlisted', value: shortlisted),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Latest Challenges',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/challenges'),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  minimumSize: const Size(0, 30),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'View all →',
                  style: TextStyle(fontSize: AppTypography.caption, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          challengesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => _DashboardMessage(
              message: 'Unable to load latest challenges.',
              onRetry: () => ref.invalidate(openChallengesProvider),
            ),
            data: (challenges) {
              final latest = challenges
                  .where((challenge) => !challenge.isPastDeadline)
                  .take(4)
                  .toList(growable: false);
              if (latest.isEmpty) {
                return const _DashboardMessage(
                  message: 'No open challenges are available right now.',
                );
              }
              return Column(
                children: latest
                    .map(
                      (challenge) => _LatestChallengeCard(
                        challenge: challenge,
                        onTap: () =>
                            context.push('/challenges/${challenge.id}'),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _DashboardStat extends StatelessWidget {
  const _DashboardStat({required this.label, required this.value});

  final String label;
  final int? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 9, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xFF202434),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF282E40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value?.toString() ?? '—',
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppTypography.heading,
              fontWeight: FontWeight.w700,
              height: 1,
            ),
          ),
          const SizedBox(height: 5),
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
}

class _LatestChallengeCard extends StatelessWidget {
  const _LatestChallengeCard({required this.challenge, required this.onTap});

  final Challenge challenge;
  final VoidCallback onTap;

  String get _categoryMark {
    final words = challenge.category
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .take(2);
    final mark = words.map((word) => word[0]).join().toUpperCase();
    return mark.isEmpty ? 'EB' : mark;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final deadline = localizations.formatShortDate(challenge.deadline.toLocal());
    final prize = challenge.cashPrize.isEmpty
        ? 'No cash prize'
        : '\$${challenge.cashPrize} prize';

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF202434),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF2A3042)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 31,
                      height: 31,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: const Color(0xFF332061),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        _categoryMark,
                        style: const TextStyle(
                          color: Color(0xFFB894FF),
                          fontSize: AppTypography.micro,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            challenge.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: AppTypography.caption,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'Company challenge',
                            style: TextStyle(
                              color: Color(0xFF85899A),
                              fontSize: AppTypography.micro,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2F3F),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    challenge.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8A8E9D),
                      fontSize: AppTypography.micro,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.workspace_premium_outlined,
                      size: 11,
                      color: const Color(0xFFFFB423),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        prize,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFFFB423),
                          fontSize: AppTypography.micro,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.schedule_rounded,
                      size: 10,
                      color: Color(0xFF85899A),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      deadline,
                      style: const TextStyle(
                        color: Color(0xFF85899A),
                        fontSize: AppTypography.micro,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
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
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFF9A9BAD), fontSize: AppTypography.caption),
        ),
        if (onRetry != null)
          TextButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    ),
  );
}
