import 'package:edubridge_mobile_application/config/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../auth/domain/entities/auth_user.dart';
import '../../../../auth/presentation/providers/auth_providers.dart';
import '../../../../dashboards/presentation/widgets/dashboard_navigation.dart';
import '../../../../dashboards/presentation/widgets/dashboard_header.dart';
import '../../../../profiles/presentation/providers/profile_provider.dart';
import '../../../domain/entities/challenge.dart';
import '../../providers/challenge_provider.dart';

class ChallengesPage extends ConsumerStatefulWidget {
  const ChallengesPage({super.key});

  @override
  ConsumerState<ChallengesPage> createState() => _ChallengesPageState();
}

class _ChallengesPageState extends ConsumerState<ChallengesPage> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _selectedCategory;
  String _sortBy = 'newest';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final challengesAsync = ref.watch(openChallengesProvider);
    final authAsync = ref.watch(authStateProvider);
    final currentUser = authAsync.hasValue ? authAsync.value : null;
    final isCompany = currentUser?.role == UserRole.company;
    final isTalent = currentUser?.role == UserRole.talent;
    final showNavigation =
        currentUser?.role == UserRole.company ||
        currentUser?.role == UserRole.talent;
    final userProfile = currentUser == null
        ? null
        : ref.watch(profileStreamProvider(currentUser.id)).asData?.value;

    return Scaffold(
      appBar: DashboardHeader(
        notificationUserId: currentUser?.id,
        scorePoints: isTalent ? userProfile?.scorePoints ?? 0 : null,
        compactScore: true,
        trailingLabel: isCompany ? 'Company' : null,
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
                    break;
                  case 1:
                    context.go(
                      isCompany ? '/company/challenges/manage' : '/challenges',
                    );
                    break;
                  case 2:
                    context.go(
                      isCompany
                          ? '/company/submissions'
                          : '/talent/submissions',
                    );
                    break;
                  case 3:
                    context.go(
                      isCompany ? '/company/profile' : '/talent/profile',
                    );
                    break;
                }
              },
            )
          : null,
      body: challengesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorState(
          message: 'We could not load challenges. Please try again.',
          onRetry: () => ref.invalidate(openChallengesProvider),
        ),
        data: (challenges) {
          final availableChallenges = challenges
              .where((challenge) => !challenge.isPastDeadline)
              .toList(growable: false);

          final categories =
              availableChallenges
                  .map((challenge) => challenge.category)
                  .toSet()
                  .toList()
                ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
          final categoryCounts = <String, int>{};
          final companyNames = <String, String>{};
          for (final challenge in availableChallenges) {
            categoryCounts.update(
              challenge.category,
              (count) => count + 1,
              ifAbsent: () => 1,
            );
          }
          for (final companyId
              in availableChallenges
                  .map((challenge) => challenge.companyId)
                  .toSet()) {
            final companyProfile = ref
                .watch(profileStreamProvider(companyId))
                .asData
                ?.value;
            companyNames[companyId] = companyProfile?.displayName.trim() ?? '';
          }

          final normalizedQuery = _query.trim().toLowerCase();
          final filteredChallenges = availableChallenges.where((challenge) {
            final matchesCategory =
                _selectedCategory == null ||
                challenge.category == _selectedCategory;
            if (!matchesCategory) return false;
            if (normalizedQuery.isEmpty) return true;

            final companyName = companyNames[challenge.companyId] ?? '';
            return challenge.title.toLowerCase().contains(normalizedQuery) ||
                companyName.toLowerCase().contains(normalizedQuery) ||
                challenge.companyId.toLowerCase().contains(normalizedQuery) ||
                challenge.shortDescription.toLowerCase().contains(
                  normalizedQuery,
                ) ||
                challenge.description.toLowerCase().contains(normalizedQuery) ||
                challenge.category.toLowerCase().contains(normalizedQuery) ||
                challenge.estimatedDuration.toLowerCase().contains(
                  normalizedQuery,
                ) ||
                challenge.difficulty.toLowerCase().contains(normalizedQuery) ||
                challenge.participantStatus.toLowerCase().contains(
                  normalizedQuery,
                ) ||
                challenge.eligibility.toLowerCase().contains(normalizedQuery) ||
                challenge.reward.toLowerCase().contains(normalizedQuery) ||
                challenge.cashPrize.toLowerCase().contains(normalizedQuery) ||
                challenge.submissionFormats.any(
                  (format) => format.toLowerCase().contains(normalizedQuery),
                ) ||
                challenge.requiredSkills.any(
                  (skill) => skill.toLowerCase().contains(normalizedQuery),
                ) ||
                challenge.requirements.any(
                  (requirement) =>
                      requirement.toLowerCase().contains(normalizedQuery),
                );
          }).toList();
          filteredChallenges.sort((first, second) {
            switch (_sortBy) {
              case 'oldest':
                return first.createdAt.compareTo(second.createdAt);
              case 'alphabetical':
                return first.title.toLowerCase().compareTo(
                  second.title.toLowerCase(),
                );
              case 'deadline':
                return first.deadline.compareTo(second.deadline);
              default:
                return second.createdAt.compareTo(first.createdAt);
            }
          });

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(openChallengesProvider),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
              children: [
                Text(
                  'Browse Challenges',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontSize: AppTypography.title,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Discover and solve real business problems from Africa’s top companies.',
                  style: const TextStyle(
                    color: Color(0xFF85899A),
                    fontSize: AppTypography.caption,
                    height: 1.4,
                  ),
                ),
                if (currentUser == null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () => context.go('/sign-in'),
                      child: const Text('Sign in'),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search by title, company, skill...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedCategory == null && normalizedQuery.isEmpty
                      ? 'Active filters: None'
                      : 'Active filters: ${[?_selectedCategory, if (normalizedQuery.isNotEmpty) '"$_query"'].join(' · ')}',
                  style: const TextStyle(
                    color: Color(0xFF85899A),
                    fontSize: AppTypography.micro,
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _CategoryFilterChip(
                        label: 'All',
                        count: availableChallenges.length,
                        selected: _selectedCategory == null,
                        onSelected: () =>
                            setState(() => _selectedCategory = null),
                      ),
                      ...categories.map(
                        (category) => _CategoryFilterChip(
                          label: category,
                          count: categoryCounts[category] ?? 0,
                          selected: _selectedCategory == category,
                          onSelected: () => setState(
                            () => _selectedCategory =
                                _selectedCategory == category ? null : category,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Showing ${filteredChallenges.length} of ${availableChallenges.length} challenges',
                        style: const TextStyle(
                          color: Color(0xFF85899A),
                          fontSize: AppTypography.micro,
                        ),
                      ),
                    ),
                    Container(
                      height: 26,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF202434),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortBy,
                          isDense: true,
                          borderRadius: BorderRadius.circular(12),
                          dropdownColor: const Color(0xFF202434),
                          style: const TextStyle(
                            color: Color(0xFF9A9BAD),
                            fontSize: AppTypography.micro,
                          ),
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 14,
                            color: Color(0xFF9A9BAD),
                          ),
                          onChanged: (value) {
                            if (value != null) setState(() => _sortBy = value);
                          },
                          items: const [
                            DropdownMenuItem(
                              value: 'newest',
                              child: Text('Sort by Newest'),
                            ),
                            DropdownMenuItem(
                              value: 'oldest',
                              child: Text('Sort by Oldest'),
                            ),
                            DropdownMenuItem(
                              value: 'alphabetical',
                              child: Text('Sort A-Z'),
                            ),
                            DropdownMenuItem(
                              value: 'deadline',
                              child: Text('Sort by Deadline'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (availableChallenges.isEmpty)
                  const _EmptyState(
                    title: 'No open challenges yet',
                    message: 'Check back later for opportunities to demonstrate your skills.',
                  )
                else if (filteredChallenges.isEmpty)
                  _NoResults(
                    onClear: () {
                      _searchController.clear();
                      setState(() {
                        _query = '';
                        _selectedCategory = null;
                      });
                    },
                  )
                else
                  ...filteredChallenges.map(
                    (challenge) => _BrowseChallengeCard(
                      challenge: challenge,
                      companyName:
                          companyNames[challenge.companyId]?.isNotEmpty == true
                          ? companyNames[challenge.companyId]!
                          : 'Company challenge',
                      onTap: () => context.push('/challenges/${challenge.id}'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryFilterChip extends StatelessWidget {
  const _CategoryFilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [Text(label), const SizedBox(width: 4), Text('$count')],
        ),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}

class _BrowseChallengeCard extends StatelessWidget {
  const _BrowseChallengeCard({
    required this.challenge,
    required this.companyName,
    required this.onTap,
  });

  final Challenge challenge;
  final String companyName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final deadline = MaterialLocalizations.of(context)
        .formatMediumDate(challenge.deadline.toLocal());
    final prize = challenge.cashPrize.trim().isNotEmpty
        ? '${challenge.cashPrize.trim()} cash prize'
        : challenge.reward.trim().isNotEmpty
        ? challenge.reward.trim()
        : 'No cash prize';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFF202434),
        border: Border.all(color: const Color(0xFF2A3042)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF30204E),
                child: Text(
                  _challengeInitials(challenge.title),
                  style: const TextStyle(
                    color: Color(0xFFC09AFF),
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppTypography.caption,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            companyName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF85899A),
                              fontSize: AppTypography.micro,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.check_circle,
                          size: 9,
                          color: Color(0xFF20C997),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF282D40),
              borderRadius: BorderRadius.circular(5),
            ),
            child: Text(
              challenge.category,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF85899A),
                fontSize: AppTypography.micro,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.payments_outlined,
                size: 10,
                color: Color(0xFFFFB423),
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
                Icons.access_time_rounded,
                size: 9,
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
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 32,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                foregroundColor: const Color(0xFFC09AFF),
                side: const BorderSide(color: Color(0xFF7244C2)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(9),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'View Challenge',
                    style: TextStyle(
                      fontSize: AppTypography.micro,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(width: 5),
                  Icon(Icons.arrow_forward_rounded, size: 12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _challengeInitials(String title) {
  final words = title
      .trim()
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty);
  return words.take(2).map((word) => word[0]).join().toUpperCase();
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(32),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.search_off_rounded,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        Text(message, textAlign: TextAlign.center),
      ],
    ),
  );
}

class _NoResults extends StatelessWidget {
  const _NoResults({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.manage_search_rounded,
            size: 40,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 10),
          Text(
            'No matching challenges',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Try another search or clear your filters.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 14),
          TextButton(onPressed: onClear, child: const Text('Clear filters')),
        ],
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off, size: 42),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}
