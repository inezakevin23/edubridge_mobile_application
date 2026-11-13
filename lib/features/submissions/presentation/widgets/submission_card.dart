import 'package:flutter/material.dart';
import '../../domain/entities/submission.dart';

class SubmissionCard extends StatelessWidget {
  final Submission submission;
  final VoidCallback? onTap;
  final bool showTalentInfo;

  static const Color cardColor = Color(0xFF1E2235);
  static const Color borderColor = Color(0xFF2A2F45);
  static const Color primaryPurple = Color(0xFF7C3BED);
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color textSecondary = Color(0xFF94A3B8);

  const SubmissionCard({
    super.key,
    required this.submission,
    this.onTap,
    this.showTalentInfo = false,
  });

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'shortlisted':
        return accentGold;
      case 'reviewed':
      case 'accepted':
        return const Color(0xFF10B981); // Emerald Green
      case 'under_review':
        return const Color(0xFF3B82F6); // Blue
      case 'rejected':
        return const Color(0xFFEF4444); // Red
      case 'pending':
      default:
        return const Color(0xFFF59E0B); // Amber
    }
  }

  String _formatStatus(String status) {
    switch (status.toLowerCase()) {
      case 'under_review':
        return 'Under Review';
      case 'shortlisted':
        return 'Shortlisted';
      case 'reviewed':
        return 'Reviewed';
      case 'rejected':
        return 'Rejected';
      case 'submitted':
      case 'pending':
      default:
        return 'Submitted';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(submission.status);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: submission.isShortlisted ? accentGold : borderColor,
          width: submission.isShortlisted ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header: Challenge Title + Shortlist Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        submission.challengeTitle.isNotEmpty
                            ? submission.challengeTitle
                            : 'Challenge #${submission.challengeId.length > 6 ? submission.challengeId.substring(0, 6) : submission.challengeId}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (submission.isShortlisted) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accentGold.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: accentGold),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star, size: 13, color: accentGold),
                            SizedBox(width: 4),
                            Text(
                              'Shortlisted',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: accentGold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),

                // Talent Info (For Company Reviewers)
                if (showTalentInfo && submission.talentName.isNotEmpty) ...[
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12,
                        backgroundColor: primaryPurple.withOpacity(0.25),
                        child: Text(
                          submission.talentName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: primaryPurple,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        submission.talentName,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      if (submission.talentEmail.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Text(
                          '(${submission.talentEmail})',
                          style: const TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                ],

                // Solution Description Excerpt
                Text(
                  submission.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),

                // Bottom row: Status chip, Deliverable icons, Date
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withOpacity(0.5)),
                      ),
                      child: Text(
                        _formatStatus(submission.status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (submission.githubUrl != null &&
                        submission.githubUrl!.isNotEmpty) ...[
                      const Icon(Icons.code, size: 16, color: primaryPurple),
                      const SizedBox(width: 8),
                    ],
                    if (submission.liveDemoUrl != null &&
                        submission.liveDemoUrl!.isNotEmpty) ...[
                      const Icon(Icons.link, size: 16, color: primaryPurple),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      _formatDate(submission.submittedAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary.withOpacity(0.8),
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
