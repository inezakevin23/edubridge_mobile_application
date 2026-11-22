import 'package:edubridge_mobile_application/config/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../dashboards/presentation/widgets/dashboard_header.dart';
import '../../../dashboards/presentation/widgets/dashboard_navigation.dart';
import '../../../submissions/presentation/providers/submission_provider.dart';
import '../../domain/entities/user_profile.dart';
import '../providers/profile_provider.dart';

class CompanyTalentProfilePage extends ConsumerWidget {
  const CompanyTalentProfilePage({required this.talentId, super.key});

  final String talentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    return auth.when(
      loading: () =>
          _shell(context, const Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => _shell(
        context,
        const _ProfileMessage(
          message: 'Unable to verify your account. Please try again.',
        ),
      ),
      data: (user) {
        if (user == null || user.requiresAccountSetup) {
          return _shell(
            context,
            const _ProfileMessage(
              message: 'Sign in with a complete Company account to continue.',
            ),
          );
        }
        if (user.role != UserRole.company) {
          return _shell(
            context,
            const _ProfileMessage(
              message:
                  'Talent profiles are available only to Company accounts.',
            ),
          );
        }

        final submissions = ref.watch(companySubmissionsProvider(user.id));
        return submissions.when(
          loading: () => _shell(
            context,
            const Center(child: CircularProgressIndicator()),
            notificationUserId: user.id,
          ),
          error: (error, stackTrace) => _shell(
            context,
            const _ProfileMessage(
              message: 'Unable to verify this shortlisted submission.',
            ),
            notificationUserId: user.id,
          ),
          data: (items) {
            final hasShortlistedSubmission = items.any(
              (submission) =>
                  submission.talentId == talentId && submission.isShortlisted,
            );
            if (!hasShortlistedSubmission) {
              return _shell(
                context,
                const _ProfileMessage(
                  message:
                      'You can only view profiles of talent you shortlisted.',
                ),
                notificationUserId: user.id,
              );
            }

            return ref
                .watch(profileByIdProvider(talentId))
                .when(
                  loading: () => _shell(
                    context,
                    const Center(child: CircularProgressIndicator()),
                    notificationUserId: user.id,
                  ),
                  error: (error, stackTrace) => _shell(
                    context,
                    const _ProfileMessage(
                      message: 'Unable to load this talent profile.',
                    ),
                    notificationUserId: user.id,
                  ),
                  data: (profile) {
                    if (profile == null || !profile.isTalent) {
                      return _shell(
                        context,
                        const _ProfileMessage(
                          message: 'This talent profile could not be found.',
                        ),
                        notificationUserId: user.id,
                      );
                    }
                    return _shell(
                      context,
                      _TalentProfileContent(profile: profile),
                      notificationUserId: user.id,
                    );
                  },
                );
          },
        );
      },
    );
  }

  Widget _shell(
    BuildContext context,
    Widget body, {
    String? notificationUserId,
  }) {
    return Scaffold(
      appBar: DashboardHeader(
        notificationUserId: notificationUserId,
        trailingLabel: 'Post Challenge',
        onTrailingTap: () => context.go('/company/challenges/create'),
        showBackButton: true,
        backFallbackPath: '/company/dashboard',
      ),
      bottomNavigationBar: DashboardNavigation(
        currentIndex: 0,
        isCompany: true,
        onIndexChanged: (index) {
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
        },
      ),
      body: body,
    );
  }
}

class _TalentProfileContent extends StatelessWidget {
  const _TalentProfileContent({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final details = profile.registrationDetails;
    final location = _location(profile, details);
    final education = [
      (
        'Institution',
        _firstValue([
          _value(details, 'institution'),
          _value(details, 'university'),
          profile.education,
        ]),
      ),
      ('Field of study', _value(details, 'fieldOfStudy')),
      ('Graduation year', _value(details, 'graduationYear')),
      ('Current status', _value(details, 'currentStatus')),
    ];
    final skills = _skills(details);
    final experience = _value(details, 'yearsOfExperience');
    final subtitle = _firstValue([
      profile.headline,
      _value(details, 'currentStatus'),
    ]);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            Row(
              children: [
                _TalentAvatar(profile: profile, radius: 34),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF30204E),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'SHORTLISTED TALENT',
                          style: TextStyle(
                            color: Color(0xFFC09AFF),
                            fontSize: AppTypography.caption,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        profile.displayName.isEmpty
                            ? 'Talent'
                            : profile.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: AppTypography.heading,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFB4C0D1),
                            fontSize: AppTypography.body,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (location.isNotEmpty || _value(details, 'phone').isNotEmpty) ...[
              _ProfileSection(
                title: 'Contact & Location',
                rows: [
                  ('Location', location),
                  ('Phone', _value(details, 'phone')),
                ],
              ),
              const SizedBox(height: 14),
            ],
            _ProfileSection(
              title: 'About',
              child: Text(
                _firstValue([
                  profile.bio,
                  'This talent has not added an introduction yet.',
                ]),
                style: const TextStyle(
                  color: Color(0xFFB4C0D1),
                  fontSize: AppTypography.body,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 14),
            _ProfileSection(title: 'Education & Work', rows: education),
            const SizedBox(height: 14),
            if (skills.isNotEmpty) ...[
              _ProfileSection(
                title: 'Skills',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: skills
                      .map((skill) => _SkillChip(label: skill))
                      .toList(growable: false),
                ),
              ),
              const SizedBox(height: 14),
            ],
            _ProfileSection(
              title: 'Recognition',
              rows: [
                ('Score points', profile.scorePoints.toString()),
                if (experience.isNotEmpty) ('Experience', '$experience years'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TalentAvatar extends StatelessWidget {
  const _TalentAvatar({required this.profile, required this.radius});

  final UserProfile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final name = profile.displayName.trim();
    final initials = name.isEmpty
        ? 'T'
        : name
              .split(RegExp(r'\s+'))
              .where((part) => part.isNotEmpty)
              .take(2)
              .map((part) => part[0].toUpperCase())
              .join();
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFF35215C),
      child: Text(
        initials,
        style: TextStyle(
          color: const Color(0xFFC49CFF),
          fontWeight: FontWeight.w800,
          fontSize: radius * 0.5,
        ),
      ),
    );

    if (profile.photoUrl.trim().isEmpty) return fallback;
    return ClipOval(
      child: Image.network(
        profile.photoUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  const _ProfileSection({required this.title, this.rows, this.child});

  final String title;
  final List<(String, String)>? rows;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF202434),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A3042)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ?child,
          if (rows != null)
            LayoutBuilder(
              builder: (context, constraints) {
                final width = (constraints.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 14,
                  children: rows!
                      .map(
                        (row) => SizedBox(
                          width: width,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                row.$1.toUpperCase(),
                                style: const TextStyle(
                                  color: Color(0xFF818697),
                                  fontSize: AppTypography.caption,
                                  letterSpacing: 0.4,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                row.$2.isEmpty ? 'Not provided' : row.$2,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFFE0E2E9),
                                  fontSize: AppTypography.body,
                                ),
                              ),
                            ],
                          ),
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

class _SkillChip extends StatelessWidget {
  const _SkillChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF30204E),
        border: Border.all(color: const Color(0xFF7244C2)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFFC09AFF),
          fontSize: AppTypography.caption,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ProfileMessage extends StatelessWidget {
  const _ProfileMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}

String _value(Map<String, Object?> details, String key) {
  final value = details[key];
  if (value is String) return value.trim();
  if (value is num) return value.toString();
  return '';
}

String _firstValue(Iterable<String> values) {
  for (final value in values) {
    if (value.trim().isNotEmpty) return value.trim();
  }
  return '';
}

String _location(UserProfile profile, Map<String, Object?> details) {
  return _firstValue([
    profile.location,
    [
      _value(details, 'city'),
      _value(details, 'country'),
    ].where((part) => part.isNotEmpty).join(', '),
  ]);
}

List<String> _skills(Map<String, Object?> details) {
  final skills = details['skills'];
  if (skills is! List) return const [];
  return skills
      .whereType<String>()
      .map((skill) => skill.trim())
      .where((skill) => skill.isNotEmpty)
      .toList(growable: false);
}
