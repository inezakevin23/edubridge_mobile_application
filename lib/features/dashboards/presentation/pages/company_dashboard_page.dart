import 'package:edubridge_mobile_application/features/profiles/presentation/providers/profile_provider.dart';
import 'package:edubridge_mobile_application/config/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../challenges/domain/entities/challenge.dart';
import '../../../challenges/presentation/providers/challenge_provider.dart';
import '../../../submissions/domain/entities/submission.dart';
import '../../../submissions/presentation/providers/submission_provider.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_navigation.dart';

class CompanyDashboardPage extends ConsumerWidget {
  const CompanyDashboardPage({required this.companyId, super.key});

  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challenges = ref.watch(companyChallengesProvider(companyId));
    final submissions = ref.watch(companySubmissionsProvider(companyId));

    return Scaffold(
      appBar: DashboardHeader(
        notificationUserId: companyId,
        trailingLabel: 'Post Challenge',
        onTrailingTap: () => context.go('/company/challenges/create'),
      ),
      bottomNavigationBar: DashboardNavigation(
        currentIndex: 0,
        isCompany: true,
        onIndexChanged: (index) => _navigate(context, index),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(companyChallengesProvider(companyId));
          ref.invalidate(companySubmissionsProvider(companyId));
          ref.invalidate(profileStreamProvider(companyId));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 22),
          children: [
            const Text(
              'Company Overview',
              style: TextStyle(
                color: Colors.white,
                fontSize: AppTypography.heading,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Manage your challenges, review submissions, and discover top African talent.',
              style: TextStyle(color: Color(0xFF9296A6), fontSize: AppTypography.caption),
            ),
            const SizedBox(height: 14),
            challenges.when(
              loading: () => const _LoadingStats(),
              error: (error, _) => _RetryMessage(
                message: 'Unable to load challenges.',
                onRetry: () =>
                    ref.invalidate(companyChallengesProvider(companyId)),
              ),
              data: (items) => submissions.when(
                loading: () => const _LoadingStats(),
                error: (error, _) => _RetryMessage(
                  message: 'Unable to load submissions.',
                  onRetry: () =>
                      ref.invalidate(companySubmissionsProvider(companyId)),
                ),
                data: (entries) {
                  final open = items
                      .where((item) => item.status == ChallengeStatus.open)
                      .length;
                  final shortlisted = entries
                      .where((item) => item.isShortlisted)
                      .length;
                  final pending = entries
                      .where((item) => item.status != SubmissionStatus.reviewed)
                      .length;
                  return GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 2.15,
                    children: [
                      _Stat(label: 'Active Challenges', value: open),
                      _Stat(label: 'Total Submissions', value: entries.length),
                      _Stat(label: 'Reviewed', value: entries.length - pending),
                      _Stat(label: 'Shortlisted', value: shortlisted),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 15),
            _SectionHeading(
              title: 'Active Challenges',
              action: 'Manage all',
              onTap: () => context.go('/company/challenges/manage'),
            ),
            const SizedBox(height: 6),
            challenges.when(
              loading: () => const _LoadingPanel(),
              error: (error, _) => const SizedBox.shrink(),
              data: (items) {
                final active = items
                    .where((item) => item.status == ChallengeStatus.open)
                    .take(4)
                    .toList();
                if (active.isEmpty) {
                  return _EmptyPanel(
                    message: 'No active challenges yet.',
                    action: 'Post a challenge',
                    onTap: () => context.go('/company/challenges/create'),
                  );
                }
                return _Panel(
                  child: Column(
                    children: [
                      ...active.map(
                        (item) => _ChallengeTile(
                          challenge: item,
                          onTap: () => context.go('/company/challenges/manage'),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              context.go('/company/challenges/create'),
                          icon: const Icon(Icons.add, size: 15),
                          label: const Text('Post a Challenge'),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 15),
            _SectionHeading(
              title: 'Shortlisted Submissions',
              action: 'View all',
              onTap: () => context.go('/company/submissions'),
            ),
            const SizedBox(height: 6),
            submissions.when(
              loading: () => const _LoadingPanel(),
              error: (error, _) => const SizedBox.shrink(),
              data: (items) {
                final selected = items
                    .where((item) => item.isShortlisted)
                    .take(2)
                    .toList();
                if (selected.isEmpty) {
                  return const _EmptyPanel(
                    message: 'Shortlisted talent will appear here.',
                  );
                }
                return _Panel(
                  child: Column(
                    children: selected.map((item) {
                      final profile = ref
                          .watch(profileByIdProvider(item.talentId))
                          .asData
                          ?.value;
                      return _SubmissionTile(
                        submission: item,
                        talentName: profile?.displayName ?? '',
                        onTap: () =>
                            context.push('/company/talent/${item.talentId}'),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/company/dashboard');
      case 1:
        context.go('/company/challenges/manage');
      case 2:
        context.go('/company/submissions');
      case 3:
        context.go('/company/profile');
    }
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final int value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(11, 9, 8, 8),
    decoration: BoxDecoration(
      color: const Color(0xFF202434),
      borderRadius: BorderRadius.circular(11),
      border: Border.all(color: const Color(0xFF282E40)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$value',
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
          style: const TextStyle(color: Color(0xFF85899A), fontSize: AppTypography.micro),
        ),
      ],
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({
    required this.title,
    required this.action,
    required this.onTap,
  });
  final String title, action;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: AppTypography.body,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          minimumSize: Size.zero,
          padding: const EdgeInsets.all(5),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(action, style: const TextStyle(fontSize: AppTypography.micro)),
      ),
    ],
  );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: const Color(0xFF202434),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: const Color(0xFF2A3042)),
    ),
    child: child,
  );
}

class _ChallengeTile extends StatelessWidget {
  const _ChallengeTile({required this.challenge, required this.onTap});
  final Challenge challenge;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: const Color(0xFF10131C),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  challenge.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppTypography.caption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right,
                size: 14,
                color: Color(0xFF8B8FA0),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            challenge.category,
            style: const TextStyle(color: Color(0xFF898D9D), fontSize: AppTypography.micro),
          ),
          const SizedBox(height: 7),
          Row(
            children: [
              const Icon(Icons.schedule, size: 10, color: Color(0xFF888C9B)),
              const SizedBox(width: 4),
              Text(
                'Due ${MaterialLocalizations.of(context).formatShortDate(challenge.deadline.toLocal())}',
                style: const TextStyle(color: Color(0xFF888C9B), fontSize: AppTypography.micro),
              ),
              const Spacer(),
              Text(
                challenge.status.value,
                style: const TextStyle(color: Color(0xFFC49CFF), fontSize: AppTypography.micro),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _SubmissionTile extends StatelessWidget {
  const _SubmissionTile({
    required this.submission,
    required this.talentName,
    required this.onTap,
  });
  final Submission submission;
  final String talentName;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 2),
      onTap: onTap,
      leading: const CircleAvatar(
        radius: 15,
        backgroundColor: Color(0xFF35215C),
        child: Icon(Icons.person_outline, size: 16, color: Color(0xFFC49CFF)),
      ),
      title: Text(
        talentName.trim().isEmpty ? 'Talent submission' : talentName.trim(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: AppTypography.caption,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        'Shortlisted · ${submission.status.label}',
        style: const TextStyle(color: Color(0xFF898D9D), fontSize: AppTypography.micro),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 11,
        color: Color(0xFF898D9D),
      ),
    ),
  );
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.message, this.action, this.onTap});
  final String message;
  final String? action;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => _Panel(
    child: Column(
      children: [
        Text(
          message,
          style: const TextStyle(color: Color(0xFF9296A6), fontSize: AppTypography.caption),
        ),
        if (action != null)
          TextButton(
            onPressed: onTap,
            child: Text(action!, style: const TextStyle(fontSize: AppTypography.caption)),
          ),
      ],
    ),
  );
}

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();
  @override
  Widget build(BuildContext context) => const _Panel(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    ),
  );
}

class _LoadingStats extends StatelessWidget {
  const _LoadingStats();
  @override
  Widget build(BuildContext context) => const SizedBox(
    height: 80,
    child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
  );
}

class _RetryMessage extends StatelessWidget {
  const _RetryMessage({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(
        message,
        style: const TextStyle(color: Color(0xFF9296A6), fontSize: AppTypography.caption),
      ),
      TextButton(onPressed: onRetry, child: const Text('Retry')),
    ],
  );
}
