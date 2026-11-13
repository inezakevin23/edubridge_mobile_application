import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../submissions/domain/entities/submission.dart';
import '../../../submissions/presentation/pages/talent/talent_solution_page.dart';
import '../../../submissions/presentation/providers/submission_provider.dart';
import '../../../submissions/presentation/widgets/submission_card.dart';
import '../widgets/dashboard_header.dart';
import '../widgets/dashboard_navigation.dart';

class TalentDashboardPage extends ConsumerStatefulWidget {
  const TalentDashboardPage({super.key});

  @override
  ConsumerState<TalentDashboardPage> createState() =>
      _TalentDashboardPageState();
}

class _TalentDashboardPageState extends ConsumerState<TalentDashboardPage> {
  int _currentNavIndex = 0;

  static const Color bgColor = Color(0xFF0E121A);
  static const Color cardColor = Color(0xFF1E2235);
  static const Color borderColor = Color(0xFF2A2F45);
  static const Color primaryPurple = Color(0xFF7C3BED);
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color textSecondary = Color(0xFF94A3B8);

  final String _talentId = 'talent_current';
  final String _talentName = 'Sarah Jenkins';

  @override
  Widget build(BuildContext context) {
    final submissions = ref.watch(talentSubmissionsProvider(_talentId));

    return Scaffold(
      backgroundColor: bgColor,
      appBar: const DashboardHeader(title: 'EduBridge'),
      body: _buildCurrentTab(submissions),
      bottomNavigationBar: DashboardNavigation(
        currentIndex: _currentNavIndex,
        onIndexChanged: (index) {
          setState(() {
            _currentNavIndex = index;
          });
        },
      ),
      floatingActionButton: _currentNavIndex == 0 || _currentNavIndex == 2
          ? FloatingActionButton.extended(
              backgroundColor: primaryPurple,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_task),
              label: const Text('Submit Solution'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TalentSolutionPage(
                      challengeId: 'chal_001',
                      challengeTitle: 'FinTech Mobile Banking Redesign',
                    ),
                  ),
                );
              },
            )
          : null,
    );
  }

  Widget _buildCurrentTab(List<Submission> submissions) {
    switch (_currentNavIndex) {
      case 0:
        return _buildOverviewTab(submissions);
      case 1:
        return _buildChallengesTab();
      case 2:
        return _buildSubmissionsTab(submissions);
      case 3:
        return _buildProfileTab();
      default:
        return _buildOverviewTab(submissions);
    }
  }

  Widget _buildOverviewTab(List<Submission> submissions) {
    final totalCount = submissions.length;
    final shortlistedCount = submissions.where((s) => s.isShortlisted).length;
    final pendingCount = submissions
        .where((s) =>
            s.status.toLowerCase() == 'submitted' ||
            s.status.toLowerCase() == 'pending' ||
            s.status.toLowerCase() == 'under_review')
        .length;
    final reviewedCount = submissions
        .where((s) =>
            s.status.toLowerCase() == 'reviewed' ||
            s.status.toLowerCase() == 'accepted')
        .length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Greeting Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryPurple.withOpacity(0.35),
                  cardColor,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryPurple.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: primaryPurple,
                  child: Text(
                    _talentName.isNotEmpty ? _talentName[0].toUpperCase() : 'T',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, $_talentName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Track your challenge solutions & review status',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2x2 Metric Cards
          const Text(
            'Your Activity Overview',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Total Submitted',
                  value: '$totalCount',
                  icon: Icons.assignment_turned_in,
                  iconColor: primaryPurple,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Shortlisted',
                  value: '$shortlistedCount',
                  icon: Icons.star,
                  iconColor: accentGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'In Progress',
                  value: '$pendingCount',
                  icon: Icons.hourglass_top,
                  iconColor: Colors.blueAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Reviewed',
                  value: '$reviewedCount',
                  icon: Icons.check_circle,
                  iconColor: Colors.greenAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Recent Submissions Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Submissions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (submissions.isNotEmpty)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentNavIndex = 2; // Switch to submissions tab
                    });
                  },
                  child: const Text(
                    'View all',
                    style: TextStyle(color: primaryPurple),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          if (submissions.isEmpty)
            _buildEmptyState()
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: submissions.length > 4 ? 4 : submissions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final sub = submissions[index];
                return SubmissionCard(
                  submission: sub,
                  onTap: () => _showSubmissionDetailsModal(context, sub),
                );
              },
            ),
          const SizedBox(height: 70),
        ],
      ),
    );
  }

  Widget _buildSubmissionsTab(List<Submission> submissions) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            color: bgColor,
            child: const TabBar(
              indicatorColor: primaryPurple,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: textSecondary,
              isScrollable: true,
              tabs: [
                Tab(text: 'All Submissions'),
                Tab(text: 'Shortlisted'),
                Tab(text: 'In Review'),
                Tab(text: 'Reviewed'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildSubmissionsList(submissions),
                _buildSubmissionsList(
                    submissions.where((s) => s.isShortlisted).toList()),
                _buildSubmissionsList(submissions
                    .where((s) =>
                        s.status.toLowerCase() == 'pending' ||
                        s.status.toLowerCase() == 'under_review')
                    .toList()),
                _buildSubmissionsList(submissions
                    .where((s) =>
                        s.status.toLowerCase() == 'reviewed' ||
                        s.status.toLowerCase() == 'accepted')
                    .toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionsList(List<Submission> list) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.assignment_outlined,
                  size: 48, color: textSecondary.withOpacity(0.4)),
              const SizedBox(height: 12),
              const Text(
                'No submissions in this category',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      itemCount: list.length,
      itemBuilder: (context, index) {
        final sub = list[index];
        return SubmissionCard(
          submission: sub,
          onTap: () => _showSubmissionDetailsModal(context, sub),
        );
      },
    );
  }

  Widget _buildChallengesTab() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryPurple.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.military_tech,
                  size: 48, color: primaryPurple),
            ),
            const SizedBox(height: 16),
            const Text(
              'Available Challenges',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Browse real-world engineering challenges created by top companies and earn job interview shortlists.',
              textAlign: TextAlign.center,
              style: TextStyle(color: textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TalentSolutionPage(
                      challengeId: 'chal_001',
                      challengeTitle: 'FinTech Mobile Banking Redesign',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Try Submitting Solution'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: primaryPurple,
            child: Text(
              _talentName[0],
              style: const TextStyle(fontSize: 32, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _talentName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'sarah.jenkins@edubridge.io',
            style: TextStyle(color: textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor),
            ),
            child: const Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Role', style: TextStyle(color: textSecondary)),
                    Text('Talent / Candidate',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
                Divider(color: borderColor, height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Active Submissions',
                        style: TextStyle(color: textSecondary)),
                    Text('3 projects',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.folder_open,
              size: 48, color: textSecondary.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text(
            'No solutions submitted yet',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Explore company challenges and submit your solutions to get shortlisted!',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(icon, size: 20, color: iconColor),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showSubmissionDetailsModal(BuildContext context, Submission sub) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (_, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: borderColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          sub.challengeTitle.isNotEmpty
                              ? sub.challengeTitle
                              : 'Submission Details',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (sub.isShortlisted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: accentGold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: accentGold),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.star, size: 14, color: accentGold),
                              SizedBox(width: 4),
                              Text(
                                'Shortlisted',
                                style: TextStyle(
                                  color: accentGold,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Status: ${sub.status.toUpperCase()} • Submitted: ${sub.submittedAt.day}/${sub.submittedAt.month}/${sub.submittedAt.year}',
                    style: const TextStyle(fontSize: 12, color: textSecondary),
                  ),
                  const Divider(color: borderColor, height: 28),
                  const Text(
                    'Solution Description',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    sub.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (sub.githubUrl != null && sub.githubUrl!.isNotEmpty) ...[
                    const Text(
                      'GitHub Repository',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sub.githubUrl!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: primaryPurple,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (sub.liveDemoUrl != null &&
                      sub.liveDemoUrl!.isNotEmpty) ...[
                    const Text(
                      'Live Demo / Video Link',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sub.liveDemoUrl!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: primaryPurple,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  if (sub.feedback != null && sub.feedback!.isNotEmpty) ...[
                    const Divider(color: borderColor, height: 24),
                    const Text(
                      'Company Feedback',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: borderColor),
                      ),
                      child: Text(
                        sub.feedback!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                  if (sub.score != null) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text(
                          'Evaluated Score: ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${sub.score}/100',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: accentGold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
