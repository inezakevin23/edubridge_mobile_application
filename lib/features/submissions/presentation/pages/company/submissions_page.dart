import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/submission.dart';
import '../../providers/submission_provider.dart';
import '../../widgets/submission_card.dart';
import 'submission_detail_page.dart';

class SubmissionsPage extends ConsumerStatefulWidget {
  final String challengeId;
  final String challengeTitle;

  const SubmissionsPage({
    super.key,
    this.challengeId = 'all',
    this.challengeTitle = '',
  });

  @override
  ConsumerState<SubmissionsPage> createState() => _SubmissionsPageState();
}

class _SubmissionsPageState extends ConsumerState<SubmissionsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color bgColor = Color(0xFF0E121A);
  static const Color cardColor = Color(0xFF1E2235);
  static const Color borderColor = Color(0xFF2A2F45);
  static const Color primaryPurple = Color(0xFF7C3BED);
  static const Color textSecondary = Color(0xFF94A3B8);

  final List<String> _filters = [
    'All',
    'Submitted',
    'Under Review',
    'Shortlisted',
    'Reviewed',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Submission> _filterSubmissions(
      List<Submission> submissions, int tabIndex) {
    switch (tabIndex) {
      case 1:
        return submissions
            .where((s) =>
                s.status.toLowerCase() == 'submitted' ||
                s.status.toLowerCase() == 'pending')
            .toList();
      case 2:
        return submissions
            .where((s) => s.status.toLowerCase() == 'under_review')
            .toList();
      case 3:
        return submissions
            .where((s) =>
                s.isShortlisted || s.status.toLowerCase() == 'shortlisted')
            .toList();
      case 4:
        return submissions
            .where((s) =>
                s.status.toLowerCase() == 'reviewed' ||
                s.status.toLowerCase() == 'accepted')
            .toList();
      default:
        return submissions;
    }
  }

  @override
  Widget build(BuildContext context) {
    final submissions =
        ref.watch(challengeSubmissionsProvider(widget.challengeId));
    final filtered = _filterSubmissions(submissions, _tabController.index);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Received Submissions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (widget.challengeTitle.isNotEmpty)
              Text(
                widget.challengeTitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: textSecondary,
                  fontWeight: FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: primaryPurple,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: textSecondary,
          tabs: _filters.map((f) => Tab(text: f)).toList(),
          onTap: (_) => setState(() {}),
        ),
      ),
      body: filtered.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 64,
                      color: textSecondary.withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No submissions found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _tabController.index == 0
                          ? 'Candidates will appear here when they submit solutions.'
                          : 'No candidate submissions match the "${_filters[_tabController.index]}" filter.',
                      style: const TextStyle(fontSize: 13, color: textSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final sub = filtered[index];
                return SubmissionCard(
                  submission: sub,
                  showTalentInfo: true,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SubmissionDetailPage(submission: sub),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
