import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/submission.dart';
import '../../providers/submission_provider.dart';

class SubmissionDetailPage extends ConsumerStatefulWidget {
  final Submission submission;

  const SubmissionDetailPage({
    super.key,
    required this.submission,
  });

  @override
  ConsumerState<SubmissionDetailPage> createState() =>
      _SubmissionDetailPageState();
}

class _SubmissionDetailPageState extends ConsumerState<SubmissionDetailPage> {
  late String _currentStatus;
  late bool _isShortlisted;
  late TextEditingController _feedbackController;
  late TextEditingController _scoreController;

  static const Color bgColor = Color(0xFF0E121A);
  static const Color cardColor = Color(0xFF1E2235);
  static const Color borderColor = Color(0xFF2A2F45);
  static const Color primaryPurple = Color(0xFF7C3BED);
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color textSecondary = Color(0xFF94A3B8);

  final List<String> _statusOptions = [
    'submitted',
    'under_review',
    'reviewed',
  ];

  @override
  void initState() {
    super.initState();
    _currentStatus = widget.submission.status;
    _isShortlisted = widget.submission.isShortlisted;
    _feedbackController =
        TextEditingController(text: widget.submission.feedback ?? '');
    _scoreController = TextEditingController(
      text: widget.submission.pointsAwarded != null
          ? widget.submission.pointsAwarded.toString()
          : (widget.submission.score != null
              ? widget.submission.score!.toInt().toString()
              : ''),
    );
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    _scoreController.dispose();
    super.dispose();
  }

  Future<void> _saveReview() async {
    final points = int.tryParse(_scoreController.text.trim());
    final feedback = _feedbackController.text.trim();

    final success = await ref
        .read(submissionControllerProvider.notifier)
        .updateStatus(
          widget.submission.id,
          _currentStatus,
          isShortlisted: _isShortlisted,
          feedback: feedback.isNotEmpty ? feedback : null,
          pointsAwarded: points,
        );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Review & evaluation saved successfully!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
      } else {
        final error = ref.read(submissionControllerProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to update review'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: const Duration(seconds: 2),
      ),
    );
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

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(submissionControllerProvider);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text(
          'Candidate Submission',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            tooltip:
                _isShortlisted ? 'Remove from shortlist' : 'Shortlist talent',
            icon: Icon(
              _isShortlisted ? Icons.star : Icons.star_border,
              color: _isShortlisted ? accentGold : textSecondary,
            ),
            onPressed: () {
              setState(() {
                _isShortlisted = !_isShortlisted;
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Candidate & Challenge Overview Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isShortlisted ? accentGold : borderColor,
                  width: _isShortlisted ? 1.5 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: primaryPurple.withOpacity(0.2),
                        child: Text(
                          widget.submission.talentName.isNotEmpty
                              ? widget.submission.talentName[0].toUpperCase()
                              : 'T',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: primaryPurple,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.submission.talentName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.submission.talentEmail,
                              style: const TextStyle(
                                fontSize: 13,
                                color: textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_isShortlisted)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: accentGold.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: accentGold),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.star, size: 14, color: accentGold),
                              SizedBox(width: 4),
                              Text(
                                'Shortlisted',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: accentGold,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const Divider(color: borderColor, height: 28),
                  Row(
                    children: [
                      const Icon(Icons.assignment_outlined,
                          size: 18, color: primaryPurple),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.submission.challengeTitle.isNotEmpty
                              ? widget.submission.challengeTitle
                              : 'Challenge ID: ${widget.submission.challengeId}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Submitted on: ${widget.submission.submittedAt.day}/${widget.submission.submittedAt.month}/${widget.submission.submittedAt.year}',
                    style: const TextStyle(fontSize: 12, color: textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Solution Description Card
            const Text(
              'Solution Approach & Details',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                widget.submission.description,
                style: const TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Deliverables & Links
            const Text(
              'Project Links',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            if (widget.submission.githubUrl != null &&
                widget.submission.githubUrl!.isNotEmpty)
              _buildLinkCard(
                icon: Icons.code,
                title: 'GitHub Repository',
                url: widget.submission.githubUrl!,
              ),
            if (widget.submission.liveDemoUrl != null &&
                widget.submission.liveDemoUrl!.isNotEmpty)
              _buildLinkCard(
                icon: Icons.link,
                title: 'Live Demo / Preview',
                url: widget.submission.liveDemoUrl!,
              ),
            const SizedBox(height: 24),

            // Evaluation & Decision Section
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Evaluation & Review Decision',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status Selector
                  DropdownButtonFormField<String>(
                    value: _currentStatus,
                    dropdownColor: cardColor,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Review Status',
                      labelStyle: const TextStyle(color: textSecondary),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryPurple),
                      ),
                    ),
                    items: _statusOptions.map((status) {
                      return DropdownMenuItem(
                        value: status,
                        child: Text(
                          _formatStatus(status),
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _currentStatus = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Score / Grade Field
                  TextFormField(
                    controller: _scoreController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Score / Points (out of 100)',
                      labelStyle: const TextStyle(color: textSecondary),
                      hintText: 'e.g. 95.0',
                      hintStyle:
                          TextStyle(color: textSecondary.withOpacity(0.5)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryPurple),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Feedback Field
                  TextFormField(
                    controller: _feedbackController,
                    maxLines: 4,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Feedback & Notes for Candidate',
                      labelStyle: const TextStyle(color: textSecondary),
                      hintText:
                          'Share constructive feedback, strengths, or interview notes...',
                      hintStyle:
                          TextStyle(color: textSecondary.withOpacity(0.5)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: primaryPurple),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Shortlist Checkbox Tile
                  Container(
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isShortlisted ? accentGold : borderColor,
                      ),
                    ),
                    child: CheckboxListTile(
                      title: const Text(
                        'Shortlist this Candidate',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: const Text(
                        'Mark candidate for priority interview or fast-track hiring',
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                      value: _isShortlisted,
                      activeColor: accentGold,
                      checkColor: Colors.black,
                      onChanged: (val) {
                        setState(() {
                          _isShortlisted = val ?? false;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save Review Button
                  ElevatedButton(
                    onPressed: actionState.isLoading ? null : _saveReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryPurple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: actionState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Save Decision & Review',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkCard({
    required IconData icon,
    required String title,
    required String url,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryPurple.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryPurple, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          url,
          style: const TextStyle(color: textSecondary, fontSize: 12),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.copy, size: 18, color: textSecondary),
          onPressed: () => _copyToClipboard(url, title),
        ),
      ),
    );
  }
}
