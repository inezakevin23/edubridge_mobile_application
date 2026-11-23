import 'package:edubridge_mobile_application/config/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../challenges/domain/entities/challenge.dart';
import '../../../../challenges/presentation/providers/challenge_provider.dart';
import '../../../../dashboards/presentation/widgets/dashboard_header.dart';
import '../../../../dashboards/presentation/widgets/dashboard_navigation.dart';
import '../../../../feedback/domain/entities/submission_feedback.dart';
import '../../../../feedback/presentation/providers/feedback_providers.dart';
import '../../../../profiles/domain/entities/user_profile.dart';
import '../../../../profiles/presentation/providers/profile_provider.dart';
import '../../../domain/entities/submission.dart';
import '../../providers/submission_provider.dart';
import '../../widgets/submission_status_chip.dart';

class SubmissionDetailPage extends ConsumerWidget {
  const SubmissionDetailPage({required this.submissionId, super.key});

  final String submissionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(submissionAuthStateProvider);

    return authAsync.when(
      loading: () => _messageScaffold(
        'Submission details',
        const Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => _messageScaffold(
        'Submission details',
        const _DetailMessage(
          message: 'Unable to verify your account. Please try again.',
        ),
      ),
      data: (user) {
        if (user == null) {
          return _messageScaffold(
            'Submission details',
            const _DetailMessage(
              message: 'Please sign in to view this submission.',
            ),
          );
        }

        final submissionAsync = ref.watch(submissionByIdProvider(submissionId));
        return submissionAsync.when(
          loading: () => _messageScaffold(
            'Submission details',
            const Center(child: CircularProgressIndicator()),
          ),
          error: (error, stackTrace) => _messageScaffold(
            'Submission details',
            const _DetailMessage(message: 'Unable to load this submission.'),
          ),
          data: (submission) {
            if (submission == null) {
              return _messageScaffold(
                'Submission details',
                const _DetailMessage(
                  message: 'This submission could not be found.',
                ),
              );
            }

            final isTalent = user.uid == submission.talentId;
            final isCompany = user.uid == submission.companyId;
            if (!isTalent && !isCompany) {
              return _messageScaffold(
                'Submission details',
                const _DetailMessage(
                  message: 'You are not permitted to view this submission.',
                ),
              );
            }

            return Scaffold(
              appBar: isCompany
                  ? DashboardHeader(
                      notificationUserId: user.uid,
                      trailingLabel: 'Post Challenge',
                      onTrailingTap: () =>
                          context.go('/company/challenges/create'),
                    )
                  : AppBar(title: const Text('Submission details')),
              bottomNavigationBar: isCompany
                  ? DashboardNavigation(
                      currentIndex: 2,
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
                    )
                  : null,
              body: _SubmissionContent(
                submission: submission,
                isCompany: isCompany,
                isTalent: isTalent,
              ),
            );
          },
        );
      },
    );
  }
}

Scaffold _messageScaffold(String title, Widget body) {
  return Scaffold(
    appBar: AppBar(title: Text(title)),
    body: body,
  );
}

class _SubmissionContent extends ConsumerStatefulWidget {
  const _SubmissionContent({
    required this.submission,
    required this.isCompany,
    required this.isTalent,
  });

  final Submission submission;
  final bool isCompany;
  final bool isTalent;

  @override
  ConsumerState<_SubmissionContent> createState() => _SubmissionContentState();
}

class _SubmissionContentState extends ConsumerState<_SubmissionContent> {
  final _reviewFormKey = GlobalKey<FormState>();
  late final TextEditingController _scoreController;
  late final TextEditingController _cashPrizeController;
  late final TextEditingController _feedbackController;
  String? _initializedFeedbackFor;
  bool _isShortlisted = false;
  bool _isSavingReview = false;

  @override
  void initState() {
    super.initState();
    _scoreController = TextEditingController(text: '0');
    _cashPrizeController = TextEditingController();
    _feedbackController = TextEditingController();
    _isShortlisted = widget.submission.isShortlisted;
  }

  @override
  void didUpdateWidget(covariant _SubmissionContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.submission.id != widget.submission.id) {
      _initializedFeedbackFor = null;
      _isShortlisted = widget.submission.isShortlisted;
    }
  }

  @override
  void dispose() {
    _scoreController.dispose();
    _cashPrizeController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submission = widget.submission;
    final challengeAsync = ref.watch(
      challengeByIdProvider(submission.challengeId),
    );
    final profileAsync = ref.watch(profileByIdProvider(submission.talentId));
    final actionsAsync = ref.watch(submissionActionsProvider);
    final feedbackAsync = widget.isCompany
        ? ref.watch(submissionFeedbackProvider(submission.id))
        : null;
    final challenge = challengeAsync.asData?.value;
    final talentProfile = profileAsync.asData?.value;

    if (feedbackAsync?.hasValue ?? false) {
      _initializeReviewFields(feedbackAsync!.value);
    }

    final title = challenge?.title ?? 'Challenge submission';
    final talentName = _talentName(talentProfile);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          children: [
            if (widget.isCompany)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.go('/company/submissions'),
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back to submissions'),
                ),
              ),
            if (widget.isCompany) const SizedBox(height: 8),
            if (widget.isCompany)
              Text(
                'Submitted by $talentName',
                style: const TextStyle(
                  color: Color(0xFF9AA7BA),
                  fontSize: AppTypography.body,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 6),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SubmissionStatusChip(status: submission.status),
                if (submission.isShortlisted)
                  const Chip(
                    avatar: Icon(Icons.star, size: 16),
                    label: Text('Shortlisted'),
                  ),
                Text(
                  'Submitted ${MaterialLocalizations.of(context).formatMediumDate(submission.submittedAt.toLocal())}',
                  style: const TextStyle(
                    color: Color(0xFF9AA7BA),
                    fontSize: AppTypography.caption,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _DetailCard(
              title: 'Solution overview',
              child: SelectableText(
                submission.solutionText.trim().isEmpty
                    ? 'No solution description was provided.'
                    : submission.solutionText,
                style: const TextStyle(
                  color: Color(0xFFB4C0D1),
                  fontSize: AppTypography.body,
                  height: 1.6,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _DetailCard(
              title: 'Submission files',
              child: submission.attachmentUrls.isEmpty
                  ? const Text(
                      'No files attached to this submission.',
                      style: TextStyle(color: Color(0xFF9AA7BA)),
                    )
                  : Column(
                      children: [
                        for (
                          var index = 0;
                          index < submission.attachmentUrls.length;
                          index++
                        ) ...[
                          if (index > 0) const SizedBox(height: 10),
                          _AttachmentRow(
                            label: 'Attachment ${index + 1}',
                            url: submission.attachmentUrls[index],
                          ),
                        ],
                      ],
                    ),
            ),
            if (widget.isCompany) ...[
              const SizedBox(height: 16),
              feedbackAsync!.when(
                loading: () => const _DetailCard(
                  title: 'Review & Score',
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stackTrace) => _DetailCard(
                  title: 'Review & Score',
                  child: Text(
                    'Unable to load saved feedback: $error',
                    style: const TextStyle(color: Color(0xFFFFB4AB)),
                  ),
                ),
                data: (existingFeedback) => _reviewForm(
                  context,
                  submission: submission,
                  challenge: challenge,
                  talentName: talentName,
                  existingFeedback: existingFeedback,
                  actionsLoading: actionsAsync.isLoading,
                ),
              ),
            ],
            if (widget.isTalent) ...[
              const SizedBox(height: 16),
              _DetailCard(
                title: 'Your submission',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      submission.canBeEdited
                          ? 'You can still edit or withdraw this solution while it has not entered review.'
                          : 'The company has started reviewing this solution. Editing and withdrawal are disabled.',
                      style: const TextStyle(
                        color: Color(0xFFB4C0D1),
                        height: 1.5,
                      ),
                    ),
                    if (submission.isShortlisted) ...[
                      const SizedBox(height: 12),
                      const ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.star, color: Colors.amber),
                        title: Text(
                          'You have been shortlisted for this challenge.',
                        ),
                      ),
                    ],
                    if (submission.canBeEdited) ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => context.push(
                          '/talent/solution/${submission.challengeId}',
                        ),
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit solution'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: actionsAsync.isLoading
                            ? null
                            : () => _confirmDelete(context, submission),
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('Withdraw submission'),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _reviewForm(
    BuildContext context, {
    required Submission submission,
    required Challenge? challenge,
    required String talentName,
    required SubmissionFeedback? existingFeedback,
    required bool actionsLoading,
  }) {
    return _DetailCard(
      title: 'Review & Score',
      child: Form(
        key: _reviewFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Shortlist team members',
              style: TextStyle(
                color: Color(0xFF9AA7BA),
                fontSize: AppTypography.body,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Material(
              color: const Color(0xFF0D1626),
              borderRadius: BorderRadius.circular(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SwitchListTile(
                  value: _isShortlisted,
                  onChanged: _isSavingReview
                      ? null
                      : (value) => setState(() => _isShortlisted = value),
                  secondary: CircleAvatar(
                    backgroundColor: const Color(0xFF2B215A),
                    child: Text(
                      _initials(talentName),
                      style: const TextStyle(
                        color: Color(0xFFC5A8FF),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(
                    talentName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: const Text('Submission author'),
                  activeThumbColor: const Color(0xFF22C55E),
                ),
              ),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _scoreController,
              keyboardType: TextInputType.number,
              decoration: _reviewInputDecoration('Score (0-100)'),
              validator: (value) {
                final score = int.tryParse((value ?? '').trim());
                if (score == null || score < 0 || score > 100) {
                  return 'Enter a whole number from 0 to 100.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _cashPrizeController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: _reviewInputDecoration(
                'Cash prize awarded (optional)',
                helperText: challenge?.cashPrize.trim().isNotEmpty == true
                    ? 'Challenge prize pool: \$${challenge!.cashPrize.trim()}'
                    : null,
              ),
              validator: (value) {
                final amountText = (value ?? '').trim();
                if (amountText.isEmpty) return null;
                final amount = double.tryParse(amountText);
                if (amount == null || !amount.isFinite || amount < 0) {
                  return 'Enter a non-negative amount.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _feedbackController,
              minLines: 4,
              maxLines: 7,
              maxLength: 1000,
              decoration: _reviewInputDecoration(
                'Feedback',
                hintText: 'Write constructive feedback...',
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if ((value ?? '').trim().length < 10) {
                  return 'Enter at least 10 characters of feedback.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: _isSavingReview
                      ? null
                      : () => _resetReviewFields(existingFeedback),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: _isSavingReview || actionsLoading
                      ? null
                      : () => _saveReview(
                          context,
                          submission: submission,
                          existingFeedback: existingFeedback,
                        ),
                  icon: _isSavingReview
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send_outlined),
                  label: Text(_isSavingReview ? 'Saving...' : 'Save & Notify'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _reviewInputDecoration(
    String label, {
    String? hintText,
    String? helperText,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      helperText: helperText,
      alignLabelWithHint: alignLabelWithHint,
      border: const OutlineInputBorder(),
      filled: true,
      fillColor: const Color(0xFF0F1728),
    );
  }

  void _initializeReviewFields(SubmissionFeedback? feedback) {
    if (_initializedFeedbackFor == widget.submission.id) return;
    _initializedFeedbackFor = widget.submission.id;
    _scoreController.text = (feedback?.pointsAwarded ?? 0).toString();
    _cashPrizeController.text =
        feedback == null || feedback.cashPrizeAwarded <= 0
        ? ''
        : feedback.cashPrizeAwarded.toString();
    _feedbackController.text = feedback?.summary ?? '';
    _isShortlisted = widget.submission.isShortlisted;
  }

  void _resetReviewFields(SubmissionFeedback? feedback) {
    _scoreController.text = (feedback?.pointsAwarded ?? 0).toString();
    _cashPrizeController.text =
        feedback == null || feedback.cashPrizeAwarded <= 0
        ? ''
        : feedback.cashPrizeAwarded.toString();
    _feedbackController.text = feedback?.summary ?? '';
    setState(() => _isShortlisted = widget.submission.isShortlisted);
    _reviewFormKey.currentState?.reset();
  }

  Future<void> _saveReview(
    BuildContext context, {
    required Submission submission,
    required SubmissionFeedback? existingFeedback,
  }) async {
    if (!_reviewFormKey.currentState!.validate()) return;

    final score = int.parse(_scoreController.text.trim());
    final cashPrizeText = _cashPrizeController.text.trim();
    final cashPrize = cashPrizeText.isEmpty ? 0.0 : double.parse(cashPrizeText);
    final challenge = ref
        .read(challengeByIdProvider(submission.challengeId))
        .asData
        ?.value;
    final challengePrize = double.tryParse(challenge?.cashPrize ?? '');
    if (challengePrize != null && cashPrize > challengePrize) {
      _showMessage(
        context,
        'The cash prize cannot exceed the challenge prize pool.',
      );
      return;
    }

    final feedback = SubmissionFeedback(
      submissionId: submission.id,
      challengeId: submission.challengeId,
      talentId: submission.talentId,
      companyId: submission.companyId,
      rating: _ratingForScore(score),
      pointsAwarded: score,
      summary: _feedbackController.text.trim(),
      strengths: existingFeedback?.strengths ?? '',
      areasForImprovement: existingFeedback?.areasForImprovement ?? '',
      cashPrizeAwarded: cashPrize,
    );

    setState(() => _isSavingReview = true);
    var feedbackSaved = false;
    try {
      await ref.read(saveSubmissionFeedbackProvider).call(feedback);
      feedbackSaved = true;
      await ref
          .read(submissionActionsProvider.notifier)
          .updateCompanyReview(
            submission: submission,
            status: SubmissionStatus.reviewed,
            isShortlisted: _isShortlisted,
          );
      if (!context.mounted) return;
      _showMessage(
        context,
        'Review saved. The talent can view the feedback in their submissions.',
      );
    } catch (error) {
      if (!context.mounted) return;
      final message = feedbackSaved
          ? 'Feedback was saved, but the review status could not be updated: $error'
          : 'Could not save the review: $error';
      _showMessage(context, message);
    } finally {
      if (mounted) setState(() => _isSavingReview = false);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    Submission submission,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Withdraw solution?'),
        content: const Text(
          'This will remove your submission from the challenge. You cannot undo this action.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref
          .read(submissionActionsProvider.notifier)
          .deleteSubmission(submission);
      if (!context.mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Your submission was withdrawn.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not withdraw the submission: $error')),
      );
    }
  }

  void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF131C2E),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: AppTypography.title,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _AttachmentRow extends StatelessWidget {
  const _AttachmentRow({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1626),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.insert_drive_file_outlined,
            color: Color(0xFFA78BFA),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                SelectableText(
                  url,
                  maxLines: 2,
                  style: const TextStyle(
                    color: Color(0xFFA78BFA),
                    fontSize: AppTypography.caption,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy link',
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: url));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Attachment link copied.')),
              );
            },
            icon: const Icon(Icons.copy_outlined, size: 18),
          ),
        ],
      ),
    );
  }
}

class _DetailMessage extends StatelessWidget {
  const _DetailMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}

String _talentName(UserProfile? profile) {
  final name = profile?.displayName.trim() ?? '';
  return name.isEmpty ? 'Talent' : name;
}

String _initials(String name) {
  final words = name
      .split(RegExp(r'\s+'))
      .where((word) => word.isNotEmpty)
      .take(2)
      .map((word) => word[0].toUpperCase())
      .join();
  return words.isEmpty ? 'T' : words;
}

int _ratingForScore(int score) {
  if (score <= 0) return 1;
  return ((score + 19) ~/ 20).clamp(1, 5);
}
