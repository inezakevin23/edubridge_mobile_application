import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:edubridge_mobile_application/config/theme/app_theme.dart';

import '../../../../auth/domain/entities/auth_user.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../dashboards/presentation/widgets/dashboard_header.dart';
import '../../../../dashboards/presentation/widgets/dashboard_navigation.dart';
import '../../../../profiles/domain/entities/user_profile.dart';
import '../../../../profiles/presentation/providers/profile_provider.dart';
import '../../../domain/entities/challenge.dart';
import '../../providers/challenge_provider.dart';

class ChallengeDetailPage extends ConsumerWidget {
  const ChallengeDetailPage({required this.challengeId, super.key});

  final String challengeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(challengeByIdProvider(challengeId));
    final authAsync = ref.watch(authStateProvider);
    final currentUser = authAsync.asData?.value;
    final isTalent = currentUser?.role == UserRole.talent;
    final isCompany = currentUser?.role == UserRole.company;
    final showNavigation = isTalent || isCompany;
    final userProfile = currentUser == null
        ? null
        : ref.watch(profileStreamProvider(currentUser.id)).asData?.value;

    return Scaffold(
      appBar: DashboardHeader(
        notificationUserId: currentUser?.id,
        showBackButton: true,
        backFallbackPath: '/challenges',
        scorePoints: isTalent ? userProfile?.scorePoints ?? 0 : null,
        compactScore: true,
        trailingLabel: isCompany ? 'Company' : null,
      ),
      body: challengeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _MessageState(
          icon: Icons.error_outline,
          message: 'Unable to load this challenge. Please try again.',
          action: TextButton(
            onPressed: () => ref.invalidate(challengeByIdProvider(challengeId)),
            child: const Text('Retry'),
          ),
        ),
        data: (challenge) {
          if (challenge == null || challenge.isDraft) {
            return const _MessageState(
              icon: Icons.search_off,
              message: 'This challenge could not be found.',
            );
          }

          final companyProfileAsync = ref.watch(
            profileStreamProvider(challenge.companyId),
          );
          final canApply =
              challenge.isOpen &&
              !challenge.isPastDeadline &&
              (currentUser == null || isTalent);

          return _ChallengeDetailContent(
            challenge: challenge,
            companyProfileAsync: companyProfileAsync,
            canApply: canApply,
            currentUser: currentUser,
          );
        },
      ),
      bottomNavigationBar: showNavigation
          ? DashboardNavigation(
              currentIndex: 1,
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
            )
          : null,
    );
  }
}

class _ChallengeDetailContent extends StatelessWidget {
  const _ChallengeDetailContent({
    required this.challenge,
    required this.companyProfileAsync,
    required this.canApply,
    required this.currentUser,
  });

  final Challenge challenge;
  final AsyncValue<UserProfile?> companyProfileAsync;
  final bool canApply;
  final AuthUser? currentUser;

  @override
  Widget build(BuildContext context) {
    final deadline = challenge.deadline.toLocal();
    final deadlineText =
        '${MaterialLocalizations.of(context).formatMediumDate(deadline)} at '
        '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(deadline))}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
      children: [
        Text(
          'Challenges  ›  ${challenge.title}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFB69BEE),
            fontSize: AppTypography.caption,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        _ChallengeHero(challenge: challenge, profileAsync: companyProfileAsync),
        const SizedBox(height: 12),
        _ReadyToCompeteCard(
          challenge: challenge,
          deadlineText: deadlineText,
          canApply: canApply,
          currentUser: currentUser,
        ),
        const SizedBox(height: 12),
        _DetailPanel(
          icon: Icons.description_outlined,
          title: 'Challenge Description',
          child: Text(
            challenge.description,
            style: const TextStyle(
              color: Color(0xFFAAB4C3),
              fontSize: AppTypography.body,
              height: 1.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        _RequirementsPanel(challenge: challenge),
        const SizedBox(height: 8),
        _CompanyInfoSection(profileAsync: companyProfileAsync),
      ],
    );
  }
}

class _ChallengeHero extends StatelessWidget {
  const _ChallengeHero({required this.challenge, required this.profileAsync});

  final Challenge challenge;
  final AsyncValue<UserProfile?> profileAsync;

  @override
  Widget build(BuildContext context) {
    final companyName = profileAsync.asData?.value?.displayName.trim() ?? '';
    final tags = <String>[
      if (challenge.category.trim().isNotEmpty) challenge.category.trim(),
      if (challenge.difficulty.trim().isNotEmpty) challenge.difficulty.trim(),
      if (challenge.estimatedDuration.trim().isNotEmpty)
        challenge.estimatedDuration.trim(),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF141D30), Color(0xFF171B3A)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF332B55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF35266A),
                child: Text(
                  _initials(challenge.title),
                  style: const TextStyle(
                    color: Color(0xFFC4A3FF),
                    fontSize: AppTypography.caption,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Posted by ${companyName.isEmpty ? 'EduBridge Africa' : companyName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF9AA7BA),
                        fontSize: AppTypography.caption,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      challenge.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppTypography.heading,
                        height: 1.22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (tags.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: tags
                            .map((tag) => _HeroTag(label: tag))
                            .toList(growable: false),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (challenge.shortDescription.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              challenge.shortDescription.trim(),
              style: const TextStyle(
                color: Color(0xFFAAB4C3),
                fontSize: AppTypography.caption,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFB9C1D0),
          fontSize: AppTypography.caption,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ReadyToCompeteCard extends StatelessWidget {
  const _ReadyToCompeteCard({
    required this.challenge,
    required this.deadlineText,
    required this.canApply,
    required this.currentUser,
  });

  final Challenge challenge;
  final String deadlineText;
  final bool canApply;
  final AuthUser? currentUser;

  @override
  Widget build(BuildContext context) {
    final reward = challenge.cashPrize.trim().isEmpty
        ? 'No cash prize'
        : '\$${challenge.cashPrize.trim()}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF292F42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ready to Compete?',
            style: TextStyle(
              color: Colors.white,
              fontSize: AppTypography.title,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          _InfoRow(
            icon: Icons.emoji_events_outlined,
            label: 'Reward',
            value: reward,
            valueColor: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 9),
          _InfoRow(
            icon: Icons.calendar_month_outlined,
            label: 'Deadline',
            value: deadlineText,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.icon(
              onPressed: canApply
                  ? () => context.push('/talent/solution/${challenge.id}')
                  : null,
              icon: const Icon(Icons.send_rounded, size: 16),
              label: Text(
                canApply
                    ? 'Submit a Solution'
                    : currentUser?.role != null &&
                          currentUser?.role != UserRole.talent
                    ? 'Talent accounts only'
                    : 'Challenge unavailable',
                style: const TextStyle(
                  fontSize: AppTypography.caption,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
          if (!canApply) ...[
            const SizedBox(height: 8),
            Text(
              challenge.isPastDeadline
                  ? 'The submission deadline has passed.'
                  : currentUser?.role != null &&
                        currentUser?.role != UserRole.talent
                  ? 'Only Talent accounts can submit a solution.'
                  : 'This challenge is closed and is no longer accepting submissions.',
              style: const TextStyle(
                color: Color(0xFFFFB423),
                fontSize: AppTypography.caption,
                height: 1.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor = Colors.white,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF8994A8)),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8994A8),
            fontSize: AppTypography.caption,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: valueColor,
              fontSize: AppTypography.caption,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailPanel extends StatelessWidget {
  const _DetailPanel({
    required this.icon,
    required this.title,
    required this.child,
    this.accent = AppTheme.primary,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF292F42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Icon(icon, size: 17, color: accent),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppTypography.title,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _RequirementsPanel extends StatelessWidget {
  const _RequirementsPanel({required this.challenge});

  final Challenge challenge;

  @override
  Widget build(BuildContext context) {
    return _DetailPanel(
      icon: Icons.checklist_rounded,
      title: 'Requirements',
      accent: AppTheme.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (challenge.requirements.isEmpty)
            const Text(
              'No specific requirements have been listed.',
              style: TextStyle(
                color: Color(0xFFAAB4C3),
                fontSize: AppTypography.caption,
                height: 1.4,
              ),
            )
          else
            for (var index = 0; index < challenge.requirements.length; index++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1626),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Color(0xFF30204E),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Color(0xFFC4A3FF),
                            fontSize: AppTypography.caption,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          challenge.requirements[index],
                          style: const TextStyle(
                            color: Color(0xFFAAB4C3),
                            fontSize: AppTypography.caption,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (challenge.requiredSkills.isNotEmpty) ...[
            const SizedBox(height: 8),
            const _SubsectionLabel('Skills required'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: challenge.requiredSkills
                  .map((skill) => _DetailTag(label: skill))
                  .toList(growable: false),
            ),
          ],
          if (challenge.submissionFormats.isNotEmpty) ...[
            const SizedBox(height: 10),
            const _SubsectionLabel('Accepted submission formats'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: challenge.submissionFormats
                  .map((format) => _DetailTag(label: format))
                  .toList(growable: false),
            ),
          ],
          if (challenge.eligibility.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Eligibility: ${challenge.eligibility.trim()}',
              style: const TextStyle(
                color: Color(0xFF8994A8),
                fontSize: AppTypography.caption,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SubsectionLabel extends StatelessWidget {
  const _SubsectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: Color(0xFFD6DEEA),
      fontSize: AppTypography.caption,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _DetailTag extends StatelessWidget {
  const _DetailTag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF9AA7BA),
          fontSize: AppTypography.caption,
        ),
      ),
    );
  }
}

class _CompanyInfoSection extends StatelessWidget {
  const _CompanyInfoSection({required this.profileAsync});

  final AsyncValue<UserProfile?> profileAsync;

  @override
  Widget build(BuildContext context) {
    return profileAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const _CompanyInfoCard(
        name: 'Company profile unavailable',
        description: 'Company information could not be loaded.',
      ),
      data: (profile) {
        if (profile == null) {
          return const _CompanyInfoCard(
            name: 'Company',
            description: 'Company profile information is not available.',
          );
        }
        return _CompanyInfoCard(
          name: profile.displayName.trim().isEmpty
              ? 'Company'
              : profile.displayName.trim(),
          industry: profile.industry,
          description: profile.companyDescription,
        );
      },
    );
  }
}

class _CompanyInfoCard extends StatelessWidget {
  const _CompanyInfoCard({
    required this.name,
    required this.description,
    this.industry = '',
  });

  final String name;
  final String industry;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF292F42)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About the Company',
            style: TextStyle(
              color: Colors.white,
              fontSize: AppTypography.title,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF0F172A),
                child: Text(
                  _initials(name),
                  style: const TextStyle(
                    color: Color(0xFFC4A3FF),
                    fontSize: AppTypography.caption,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE7E9F0),
                        fontSize: AppTypography.caption,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (industry.trim().isNotEmpty)
                      Text(
                        industry.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF8994A8),
                          fontSize: AppTypography.caption,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (description.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              description.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF8994A8),
                fontSize: AppTypography.caption,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({required this.icon, required this.message, this.action});

  final IconData icon;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 44),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          ?action,
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
  if (words.isEmpty) return 'EB';
  final initials = words.take(2).map((word) => word[0]).join();
  return initials.toUpperCase();
}
