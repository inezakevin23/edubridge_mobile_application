import 'package:edubridge_mobile_application/config/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../challenges/domain/entities/challenge.dart';
import '../../../../challenges/presentation/providers/challenge_provider.dart';
import '../../../../dashboards/presentation/widgets/dashboard_header.dart';
import '../../../../dashboards/presentation/widgets/dashboard_navigation.dart';
import '../../../../notifications/presentation/providers/notification_providers.dart';
import '../../../../profiles/domain/entities/user_profile.dart';
import '../../../../profiles/presentation/providers/profile_provider.dart';
import '../../../domain/entities/submission.dart';
import '../../providers/submission_provider.dart';

class CompanySubmissionsPage extends ConsumerStatefulWidget {
  const CompanySubmissionsPage({super.key});

  @override
  ConsumerState<CompanySubmissionsPage> createState() =>
      _CompanySubmissionsPageState();
}

class _CompanySubmissionsPageState
    extends ConsumerState<CompanySubmissionsPage> {
  final _searchController = TextEditingController();
  String? _challengeFilter;
  String _statusFilter = 'All statuses';
  bool _sortByScore = false;
  bool _isNotifyingShortlisted = false;
  int _pageIndex = 0;

  static const _pageSize = 2;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(submissionAuthStateProvider);
    return Scaffold(
      appBar: DashboardHeader(
        notificationUserId: authAsync.asData?.value?.uid,
        trailingLabel: 'Post Challenge',
        onTrailingTap: () => context.go('/company/challenges/create'),
      ),
      bottomNavigationBar: DashboardNavigation(
        currentIndex: 2,
        isCompany: true,
        onIndexChanged: (index) => _navigate(context, index),
      ),
      body: authAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const _Message(
          message: 'Unable to verify your account. Please try again.',
        ),
        data: (user) {
          if (user == null) {
            return const _Message(
              message: 'Please sign in to view submissions.',
            );
          }
          final submissionsAsync = ref.watch(
            companySubmissionsProvider(user.uid),
          );
          final challengesAsync = ref.watch(
            companyChallengesProvider(user.uid),
          );
          return submissionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => _Message(
              message: 'Unable to load submissions for your challenges.',
              onRetry: () =>
                  ref.invalidate(companySubmissionsProvider(user.uid)),
            ),
            data: (submissions) => challengesAsync.when(
              loading: () => _buildReview(context, submissions, const []),
              error: (error, stackTrace) =>
                  _buildReview(context, submissions, const []),
              data: (challenges) =>
                  _buildReview(context, submissions, challenges),
            ),
          );
        },
      ),
    );
  }

  Widget _buildReview(
    BuildContext context,
    List<Submission> submissions,
    List<Challenge> challenges,
  ) {
    final challengeMap = {
      for (final challenge in challenges) challenge.id: challenge,
    };
    final shortlisted = submissions
        .where((item) => item.isShortlisted)
        .toList();
    final reviewed = submissions
        .where((item) => item.status == SubmissionStatus.reviewed)
        .length;
    final activeChallenges = challenges
        .where((item) => item.status == ChallengeStatus.open)
        .length;
    final search = _searchController.text.trim().toLowerCase();
    final profiles = <String, UserProfile?>{};
    for (final submission in submissions) {
      profiles[submission.talentId] = ref
          .watch(profileByIdProvider(submission.talentId))
          .asData
          ?.value;
    }

    var visible = submissions.where((submission) {
      final profile = profiles[submission.talentId];
      final challenge = challengeMap[submission.challengeId];
      final searchText = [
        profile?.displayName ?? '',
        profile?.registrationDetails['institution'] ?? '',
        profile?.registrationDetails['university'] ?? '',
        if (profile?.registrationDetails['skills'] case final List skills)
          skills.join(' '),
        challenge?.title ?? '',
        submission.solutionText,
      ].join(' ').toLowerCase();
      final matchesSearch = search.isEmpty || searchText.contains(search);
      final matchesChallenge =
          _challengeFilter == null ||
          submission.challengeId == _challengeFilter;
      final matchesStatus = switch (_statusFilter) {
        'Needs review' => submission.status != SubmissionStatus.reviewed,
        'Reviewed' => submission.status == SubmissionStatus.reviewed,
        'Shortlisted' => submission.isShortlisted,
        _ => true,
      };
      return matchesSearch && matchesChallenge && matchesStatus;
    }).toList();
    if (_sortByScore) {
      visible.sort(
        (a, b) => (profiles[b.talentId]?.scorePoints ?? 0).compareTo(
          profiles[a.talentId]?.scorePoints ?? 0,
        ),
      );
    } else {
      visible.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
    }
    final pageCount = visible.isEmpty
        ? 1
        : (visible.length + _pageSize - 1) ~/ _pageSize;
    final pageIndex = _pageIndex.clamp(0, pageCount - 1).toInt();
    final pageSubmissions = visible
        .skip(pageIndex * _pageSize)
        .take(_pageSize)
        .toList();
    final firstVisible = visible.isEmpty ? 0 : pageIndex * _pageSize + 1;
    final lastVisible = (pageIndex * _pageSize + pageSubmissions.length);
    final scale = _responsiveScale(context);
    final actionMaxWidth = (MediaQuery.sizeOf(context).width * 0.46)
        .clamp(110.0, 170.0)
        .toDouble();

    return RefreshIndicator(
      onRefresh: () async {
        final user = ref.read(submissionAuthStateProvider).asData?.value;
        if (user != null) {
          ref.invalidate(companySubmissionsProvider(user.uid));
          ref.invalidate(companyChallengesProvider(user.uid));
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 18),
        children: [
          Text(
            'Submissions / All challenges',
            style: TextStyle(
              color: const Color(0xFFB69BEE),
              fontSize: AppTypography.micro * scale,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Review Submissions',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: AppTypography.title * scale,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Evaluate, score, and shortlist top participants for this challenge.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF9296A6),
                        fontSize: AppTypography.micro * scale,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: actionMaxWidth),
                child: FilledButton.icon(
                  onPressed: (shortlisted.isEmpty || _isNotifyingShortlisted)
                      ? null
                      : () => _notifyShortlisted(shortlisted),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA800),
                    foregroundColor: const Color(0xFF171923),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 9,
                    ),
                    textStyle: TextStyle(
                      fontSize: AppTypography.micro * scale,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  icon: _isNotifyingShortlisted
                      ? const SizedBox(
                          width: 11,
                          height: 11,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        )
                      : const Icon(
                          Icons.notifications_active_outlined,
                          size: 11,
                        ),
                  label: const Text(
                    'Notify Shortlisted',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 7,
            mainAxisSpacing: 7,
            childAspectRatio: 2.18,
            children: [
              _StatCard(
                label: 'Total Submissions',
                value: '${submissions.length}',
              ),
              _StatCard(label: 'Reviewed Submissions', value: '$reviewed'),
              _StatCard(label: 'Shortlisted', value: '${shortlisted.length}'),
              _StatCard(label: 'Active Challenges', value: '$activeChallenges'),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() => _pageIndex = 0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppTypography.micro,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search by student name, university, skill...',
                    hintStyle: TextStyle(
                      color: const Color(0xFF828697),
                      fontSize: AppTypography.micro * scale,
                    ),
                    prefixIcon: const Icon(Icons.search, size: 14),
                    filled: true,
                    fillColor: const Color(0xFF202434),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              _FilterMenu<String?>(
                label: _challengeFilter == null
                    ? 'All\nChallenges'
                    : challengeMap[_challengeFilter]?.title ?? 'Challenge',
                value: _challengeFilter,
                values: [null, ...challenges.map((challenge) => challenge.id)],
                labels: {
                  null: 'All Challenges',
                  for (final challenge in challenges)
                    challenge.id: challenge.title,
                },
                onSelected: (value) => setState(() {
                  _challengeFilter = value;
                  _pageIndex = 0;
                }),
              ),
              const SizedBox(width: 5),
              _FilterMenu<String>(
                label: _statusFilter.replaceAll(' ', '\n'),
                value: _statusFilter,
                values: const [
                  'All statuses',
                  'Needs review',
                  'Reviewed',
                  'Shortlisted',
                ],
                labels: const {
                  'All statuses': 'All statuses',
                  'Needs review': 'Needs review',
                  'Reviewed': 'Reviewed',
                  'Shortlisted': 'Shortlisted',
                },
                onSelected: (value) => setState(() {
                  _statusFilter = value;
                  _pageIndex = 0;
                }),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: () => setState(() {
                _sortByScore = !_sortByScore;
                _pageIndex = 0;
              }),
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _sortByScore
                      ? const Color(0xFF35215C)
                      : const Color(0xFF202434),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _sortByScore ? 'Highest score ✓' : 'Highest score',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppTypography.micro * scale,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          if (visible.isEmpty)
            const _EmptySubmissions()
          else
            ...pageSubmissions.asMap().entries.map(
              (entry) => _SubmissionReviewCard(
                index: pageIndex * _pageSize + entry.key + 1,
                submission: entry.value,
                challengeTitle:
                    challengeMap[entry.value.challengeId]?.title ??
                    'Challenge submission',
                profile: profiles[entry.value.talentId],
                onTap: () => context.push('/submissions/${entry.value.id}'),
              ),
            ),
          const SizedBox(height: 7),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Showing $firstVisible-$lastVisible of ${visible.length} submissions',
                  style: TextStyle(
                    color: const Color(0xFF818697),
                    fontSize: AppTypography.micro * scale,
                  ),
                ),
              ),
              Text(
                'Page',
                style: TextStyle(
                  color: const Color(0xFF818697),
                  fontSize: AppTypography.micro * scale,
                ),
              ),
              const SizedBox(width: 5),
              _PageButton(
                label: '${pageIndex + 1}',
                isCurrent: true,
                onPressed: null,
              ),
              const SizedBox(width: 3),
              _PageButton(
                label: '›',
                onPressed: pageIndex + 1 < pageCount
                    ? () => setState(() => _pageIndex = pageIndex + 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _notifyShortlisted(List<Submission> shortlisted) async {
    final company = ref.read(submissionAuthStateProvider).asData?.value;
    if (company == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to verify your company account. Try again.'),
        ),
      );
      return;
    }

    setState(() => _isNotifyingShortlisted = true);
    try {
      final count = await ref.read(notifyShortlistedSubmissionsProvider)(
        companyId: company.uid,
        submissions: shortlisted,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(switch (count) {
            0 => 'All shortlisted talent were already notified.',
            1 => 'Shortlist notification sent.',
            _ => '$count shortlist notifications sent.',
          }),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not notify shortlisted talent: $error')),
      );
    } finally {
      if (mounted) setState(() => _isNotifyingShortlisted = false);
    }
  }

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/company/dashboard');
      case 1:
        context.go('/company/challenges/create');
      case 2:
        context.go('/company/submissions');
      case 3:
        context.go('/company/profile');
      case 4:
        break;
    }
  }
}

double _responsiveScale(BuildContext context) {
  return (MediaQuery.sizeOf(context).width / 390).clamp(1.0, 1.1).toDouble();
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.label,
    required this.onPressed,
    this.isCurrent = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final color = isCurrent ? const Color(0xFF252A3A) : const Color(0xFF202434);
    return SizedBox(
      width: 25,
      height: 25,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledForegroundColor: Colors.white,
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
          textStyle: TextStyle(
            fontSize: AppTypography.micro * _responsiveScale(context),
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 8, 7, 7),
    decoration: BoxDecoration(
      color: const Color(0xFF202434),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0xFF2A3042)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: AppTypography.title * _responsiveScale(context),
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFF85899A),
            fontSize: AppTypography.micro * _responsiveScale(context),
          ),
        ),
      ],
    ),
  );
}

class _FilterMenu<T> extends StatelessWidget {
  const _FilterMenu({
    required this.label,
    required this.value,
    required this.values,
    required this.labels,
    required this.onSelected,
  });
  final String label;
  final T value;
  final List<T> values;
  final Map<T, String> labels;
  final ValueChanged<T> onSelected;
  @override
  Widget build(BuildContext context) => PopupMenuButton<T>(
    initialValue: value,
    onSelected: onSelected,
    color: const Color(0xFF202434),
    itemBuilder: (context) => values
        .map(
          (item) => PopupMenuItem<T>(
            value: item,
            child: Text(
              labels[item] ?? '',
              style: TextStyle(
                color: Colors.white,
                fontSize: AppTypography.caption * _responsiveScale(context),
              ),
            ),
          ),
        )
        .toList(),
    child: Container(
      width: 54,
      height: 42,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF202434),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: AppTypography.micro * _responsiveScale(context),
              ),
            ),
          ),
          const Icon(
            Icons.keyboard_arrow_down,
            size: 10,
            color: Colors.white70,
          ),
        ],
      ),
    ),
  );
}

class _SubmissionReviewCard extends StatelessWidget {
  const _SubmissionReviewCard({
    required this.index,
    required this.submission,
    required this.challengeTitle,
    required this.profile,
    required this.onTap,
  });
  final int index;
  final Submission submission;
  final String challengeTitle;
  final UserProfile? profile;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final name = profile?.displayName.isNotEmpty == true
        ? profile!.displayName
        : 'Talent';
    final institution =
        profile?.registrationDetails['institution']?.toString() ?? '';
    final score = profile?.scorePoints ?? 0;
    final statusColor = submission.status == SubmissionStatus.reviewed
        ? const Color(0xFF178D6A)
        : const Color(0xFF282C37);
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF202434),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A3042)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 17,
                height: 17,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: index == 1
                      ? const Color(0xFFFFA800)
                      : const Color(0xFF303546),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: index == 1
                        ? const Color(0xFF171923)
                        : const Color(0xFFB7BAC5),
                    fontSize: AppTypography.micro * _responsiveScale(context),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  challengeTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFFC09AFF),
                    fontSize: AppTypography.micro * _responsiveScale(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              CircleAvatar(
                radius: 9,
                backgroundColor: const Color(0xFF35215C),
                child: Text(
                  _initials(name),
                  style: TextStyle(
                    color: const Color(0xFFC09AFF),
                    fontSize: AppTypography.micro * _responsiveScale(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppTypography.micro * _responsiveScale(context),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  submission.status.label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppTypography.micro * _responsiveScale(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            submission.solutionText,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFFD2D4DD),
              fontSize: AppTypography.micro * _responsiveScale(context),
              height: 1.4,
            ),
          ),
          if (institution.isNotEmpty || submission.isShortlisted) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: [
                if (institution.isNotEmpty) _Tag(institution),
                if (submission.isShortlisted) const _Tag('Shortlisted'),
                if (score > 0) _Tag('$score pts'),
              ],
            ),
          ],
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onTap,
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFF35215C),
                foregroundColor: const Color(0xFFC09AFF),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: TextStyle(
                  fontSize: AppTypography.micro * _responsiveScale(context),
                ),
              ),
              icon: const Icon(Icons.visibility_outlined, size: 10),
              label: const Text('View Full Solution & Review'),
            ),
          ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2);
    final result = parts.map((part) => part[0]).join().toUpperCase();
    return result.isEmpty ? 'T' : result;
  }
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
    decoration: BoxDecoration(
      color: const Color(0xFF303546),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: TextStyle(
        color: const Color(0xFF9A9EAC),
        fontSize: AppTypography.micro * _responsiveScale(context),
      ),
    ),
  );
}

class _EmptySubmissions extends StatelessWidget {
  const _EmptySubmissions();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: const Color(0xFF202434),
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Text(
      'No submissions match these filters.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Color(0xFF9296A6),
        fontSize: AppTypography.caption,
      ),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({required this.message, this.onRetry});
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
