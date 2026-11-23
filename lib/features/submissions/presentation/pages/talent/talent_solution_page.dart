import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:edubridge_mobile_application/config/theme/app_theme.dart';

import '../../../../challenges/domain/entities/challenge.dart';
import '../../../../challenges/presentation/providers/challenge_provider.dart';
import '../../../../dashboards/presentation/widgets/dashboard_header.dart';
import '../../../../dashboards/presentation/widgets/dashboard_navigation.dart';
import '../../../../profiles/presentation/providers/profile_provider.dart';
import '../../../domain/entities/submission.dart';
import '../../providers/submission_provider.dart';

class TalentSolutionPage extends ConsumerStatefulWidget {
  const TalentSolutionPage({required this.challengeId, super.key});

  final String challengeId;

  @override
  ConsumerState<TalentSolutionPage> createState() => _TalentSolutionPageState();
}

class _TalentSolutionPageState extends ConsumerState<TalentSolutionPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _summaryController = TextEditingController();
  final Map<String, TextEditingController> _deliverableControllers = {};
  bool _initialValuesLoaded = false;

  @override
  void didUpdateWidget(covariant TalentSolutionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.challengeId != widget.challengeId) {
      _titleController.clear();
      _summaryController.clear();
      for (final controller in _deliverableControllers.values) {
        controller.dispose();
      }
      _deliverableControllers.clear();
      _initialValuesLoaded = false;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _summaryController.dispose();
    for (final controller in _deliverableControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(submissionAuthStateProvider);
    final user = authAsync.asData?.value;
    final profileAsync = user == null
        ? null
        : ref.watch(profileStreamProvider(user.uid));
    final challengeAsync = ref.watch(challengeByIdProvider(widget.challengeId));
    final submissionAsync = user == null
        ? null
        : ref.watch(
            submissionForChallengeProvider(
              SubmissionLookup(
                challengeId: widget.challengeId,
                talentId: user.uid,
              ),
            ),
          );
    final actionsAsync = ref.watch(submissionActionsProvider);
    final challenge = challengeAsync.asData?.value;
    final submission = submissionAsync?.asData?.value;
    final canEdit =
        challenge != null &&
        (submissionAsync?.hasValue ?? false) &&
        challenge.isOpen &&
        !challenge.isPastDeadline &&
        (submission == null || submission.canBeEdited);

    return Scaffold(
      appBar: DashboardHeader(
        notificationUserId: user?.uid,
        showBackButton: true,
        backFallbackPath: '/challenges/${widget.challengeId}',
        compactScore: true,
        scorePoints: user == null
            ? null
            : profileAsync?.asData?.value?.scorePoints ?? 0,
      ),
      body: authAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const _PageMessage(
          message: 'Unable to verify your account. Please try again.',
        ),
        data: (user) {
          if (user == null) {
            return const _PageMessage(
              message: 'Please sign in to submit a solution.',
            );
          }

          return challengeAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => const _PageMessage(
              message: 'Unable to load this challenge. Please try again.',
            ),
            data: (challenge) {
              if (challenge == null) {
                return const _PageMessage(
                  message: 'This challenge could not be found.',
                );
              }

              return submissionAsync!.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stackTrace) => const _PageMessage(
                  message: 'Unable to load your existing submission.',
                ),
                data: (submission) {
                  final companyName =
                      ref
                          .watch(profileStreamProvider(challenge.companyId))
                          .asData
                          ?.value
                          ?.displayName
                          .trim() ??
                      '';
                  return _buildChallengeForm(
                    context,
                    user,
                    challenge,
                    submission,
                    companyName,
                  );
                },
              );
            },
          );
        },
      ),
      bottomNavigationBar: user == null
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (challenge != null && (submissionAsync?.hasValue ?? false))
                  _SubmitBar(
                    isSaving: actionsAsync.isLoading,
                    canEdit: canEdit,
                    label: submission == null
                        ? canEdit
                              ? 'Submit Solution'
                              : 'Challenge Unavailable'
                        : canEdit
                        ? 'Update Solution'
                        : 'Submission Locked',
                    onPressed: canEdit && !actionsAsync.isLoading
                        ? () => _save(context, user, challenge, submission)
                        : null,
                  ),
                DashboardNavigation(
                  currentIndex: 1,
                  onIndexChanged: (index) {
                    switch (index) {
                      case 0:
                        context.go('/talent/dashboard');
                      case 1:
                        context.go('/challenges');
                      case 2:
                        context.go('/talent/submissions');
                      case 3:
                        context.go('/talent/profile');
                    }
                  },
                ),
              ],
            ),
    );
  }

  Widget _buildChallengeForm(
    BuildContext context,
    User user,
    Challenge challenge,
    Submission? existingSubmission,
    String companyName,
  ) {
    final formats = challenge.submissionFormats
        .map((format) => format.trim())
        .where((format) => format.isNotEmpty)
        .toList(growable: false);
    for (final format in formats) {
      _deliverableControllers.putIfAbsent(format, TextEditingController.new);
    }
    _loadInitialValues(formats, existingSubmission);

    final isChallengeAvailable = challenge.isOpen && !challenge.isPastDeadline;
    final isLocked =
        existingSubmission != null && !existingSubmission.canBeEdited;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Text(
            'Challenges  ›  ${challenge.title}  ›  Submit Solution',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFB69BEE),
              fontSize: AppTypography.caption,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          _ChallengeSummaryCard(challenge: challenge, companyName: companyName),
          const SizedBox(height: 14),
          _SubmissionChecklist(
            title: _titleController.text,
            summary: _summaryController.text,
            formats: formats,
            deliverableControllers: _deliverableControllers,
          ),
          const SizedBox(height: 14),
          _SubmissionPanel(
            icon: Icons.edit_note_rounded,
            title: 'Solution Overview',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel('Solution Title'),
                TextFormField(
                  key: const ValueKey('solution_title'),
                  controller: _titleController,
                  enabled: !isLocked && isChallengeAvailable,
                  maxLength: 120,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: _fieldDecoration(
                    hintText:
                        'e.g. Data-Driven Route Optimization via Clustering',
                    counterText: '',
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a solution title.'
                      : null,
                ),
                const SizedBox(height: 14),
                const _FieldLabel('Executive Summary'),
                const SizedBox(height: 5),
                const Text(
                  'Briefly summarize your approach, key findings, and proposed solution.',
                  style: TextStyle(
                    color: Color(0xFF85899A),
                    fontSize: AppTypography.caption,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const ValueKey('solution_summary'),
                  controller: _summaryController,
                  enabled: !isLocked && isChallengeAvailable,
                  minLines: 4,
                  maxLines: 6,
                  maxLength: 300,
                  textCapitalization: TextCapitalization.sentences,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: _fieldDecoration(
                    hintText: 'Describe your overall approach and what you discovered...',
                    counterText: '',
                  ),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return 'Enter an executive summary.';
                    if (text.length < 30) {
                      return 'Use at least 30 characters.';
                    }
                    return null;
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '${_summaryController.text.length}/300',
                    style: const TextStyle(
                      color: Color(0xFF7F8EA5),
                      fontSize: AppTypography.caption,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SubmissionPanel(
            icon: Icons.upload_file_rounded,
            title: 'Upload Deliverables',
            accent: AppTheme.accent,
            child: formats.isEmpty
                ? const Text(
                    'This challenge does not currently accept submissions.',
                    style: TextStyle(
                      color: Color(0xFFFBBF24),
                      fontSize: AppTypography.caption,
                    ),
                  )
                : Column(
                    children: [
                      for (var index = 0; index < formats.length; index++) ...[
                        if (index > 0) const SizedBox(height: 10),
                        _DeliverableInput(
                          format: formats[index],
                          controller: _deliverableControllers[formats[index]]!,
                          enabled: !isLocked && isChallengeAvailable,
                          onChanged: () => setState(() {}),
                          onUploadTap: () => _showUploadHint(context),
                        ),
                      ],
                    ],
                  ),
          ),
          if (!isChallengeAvailable || isLocked) ...[
            const SizedBox(height: 14),
            _AvailabilityNotice(
              message: isLocked
                  ? 'Your solution is no longer editable because the Company has started reviewing it.'
                  : 'This challenge is closed or its deadline has passed. New submissions and edits are unavailable.',
            ),
          ],
        ],
      ),
    );
  }

  void _loadInitialValues(
    List<String> formats,
    Submission? existingSubmission,
  ) {
    if (_initialValuesLoaded) return;

    if (existingSubmission != null) {
      final separator = existingSubmission.solutionText.indexOf('\n\n');
      if (separator > 0) {
        _titleController.text = existingSubmission.solutionText
            .substring(0, separator)
            .trim();
        _summaryController.text = existingSubmission.solutionText
            .substring(separator + 2)
            .trim();
      } else {
        _summaryController.text = existingSubmission.solutionText;
      }

      for (
        var index = 0;
        index < formats.length &&
            index < existingSubmission.attachmentUrls.length;
        index++
      ) {
        _deliverableControllers[formats[index]]!.text =
            existingSubmission.attachmentUrls[index];
      }
    }

    _initialValuesLoaded = true;
  }

  void _showUploadHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'File uploads are not configured yet. Paste a shareable link instead.',
        ),
      ),
    );
  }

  Future<void> _save(
    BuildContext context,
    User user,
    Challenge challenge,
    Submission? existingSubmission,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final summary = _summaryController.text.trim();
    if (title.isEmpty || summary.length < 30) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            title.isEmpty
                ? 'Enter a solution title.'
                : 'Use at least 30 characters in your executive summary.',
          ),
        ),
      );
      return;
    }

    final links = challenge.submissionFormats
        .map(
          (format) => _deliverableControllers[format.trim()]?.text.trim() ?? '',
        )
        .where((link) => link.isNotEmpty)
        .toList(growable: false);
    if (links.any((link) => !_isHttpLink(link))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid http or https links.')),
      );
      return;
    }
    if (links.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a link for at least one accepted deliverable.'),
        ),
      );
      return;
    }

    final solutionText = '$title\n\n$summary';

    try {
      if (existingSubmission == null) {
        await ref
            .read(submissionActionsProvider.notifier)
            .submitSolution(
              challengeId: widget.challengeId,
              talentId: user.uid,
              companyId: challenge.companyId,
              solutionText: solutionText,
              attachmentUrls: links,
            );
      } else {
        await ref
            .read(submissionActionsProvider.notifier)
            .updateTalentSubmission(
              submission: existingSubmission,
              solutionText: solutionText,
              attachmentUrls: links,
            );
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            existingSubmission == null
                ? 'Your solution was submitted.'
                : 'Your solution was updated.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('already been submitted')) {
      return 'You have already submitted a solution for this challenge.';
    }
    if (message.contains('closed') || message.contains('deadline')) {
      return 'This challenge is no longer accepting submissions.';
    }
    if (message.contains('permission-denied')) {
      return 'You are not allowed to perform this action.';
    }
    return 'We could not save your solution. Please try again.';
  }
}

InputDecoration _fieldDecoration({
  required String hintText,
  String? counterText,
}) {
  return InputDecoration(
    hintText: hintText,
    counterText: counterText,
    filled: true,
    fillColor: const Color(0xFF0F1119),
    hintStyle: const TextStyle(
      color: Color(0xFF737C8D),
      fontSize: AppTypography.body,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF252A38)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFF252A38)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppTheme.primary, width: 1.2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFFF6B79)),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFFF6B79), width: 1.2),
    ),
  );
}

class _ChallengeSummaryCard extends StatelessWidget {
  const _ChallengeSummaryCard({
    required this.challenge,
    required this.companyName,
  });

  final Challenge challenge;
  final String companyName;

  @override
  Widget build(BuildContext context) {
    final deadline = MaterialLocalizations.of(context)
        .formatMediumDate(challenge.deadline.toLocal());
    final description = challenge.shortDescription.trim().isNotEmpty
        ? challenge.shortDescription.trim()
        : challenge.description.trim();
    final prize = challenge.cashPrize.trim().isEmpty
        ? 'No cash prize'
        : 'Cash prize: \$${challenge.cashPrize.trim()}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171D31),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF293149)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  '${challenge.title} Challenge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppTypography.title,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF352719),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Text(
                  'Submit Solution',
                  style: TextStyle(
                    color: Color(0xFFFBBF24),
                    fontSize: AppTypography.caption,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            '${companyName.isEmpty ? 'Company' : companyName}  •  Deadline: $deadline',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF85899A),
              fontSize: AppTypography.caption,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            prize,
            style: const TextStyle(
              color: Color(0xFFFBBF24),
              fontSize: AppTypography.caption,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFB2B7C5),
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

class _SubmissionChecklist extends StatelessWidget {
  const _SubmissionChecklist({
    required this.title,
    required this.summary,
    required this.formats,
    required this.deliverableControllers,
  });

  final String title;
  final String summary;
  final List<String> formats;
  final Map<String, TextEditingController> deliverableControllers;

  @override
  Widget build(BuildContext context) {
    bool hasFormat(String expected) => formats.any(
      (format) => _normalizedFormat(format) == _normalizedFormat(expected),
    );
    bool hasLink(String expected) => formats.any(
      (format) =>
          _normalizedFormat(format) == _normalizedFormat(expected) &&
          (deliverableControllers[format]?.text.trim().isNotEmpty ?? false),
    );

    final hasReport = !hasFormat('Written Report') || hasLink('Written Report');
    final hasPresentation = !hasFormat('Slide Deck') || hasLink('Slide Deck');
    final hasAnyDeliverable = deliverableControllers.values.any(
      (controller) => controller.text.trim().isNotEmpty,
    );
    final checklist = <(String, bool)>[
      ('Solution title added', title.trim().isNotEmpty),
      ('Executive summary written', summary.trim().isNotEmpty),
      (
        hasFormat('Written Report')
            ? 'Written report uploaded'
            : 'Written report not required',
        hasReport,
      ),
      (
        hasFormat('Slide Deck')
            ? 'Presentation deck uploaded'
            : 'Presentation deck not required',
        hasPresentation,
      ),
      (
        'All required fields complete',
        title.trim().isNotEmpty &&
            summary.trim().isNotEmpty &&
            hasAnyDeliverable,
      ),
    ];
    final readiness = checklist.where((item) => item.$2).length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF171D31),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF293149)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.checklist_rounded,
            title: 'Submission Checklist',
          ),
          const SizedBox(height: 12),
          for (final item in checklist)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    item.$2
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    size: 18,
                    color: item.$2
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFF3B4356),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      item.$1,
                      style: TextStyle(
                        color: item.$2
                            ? const Color(0xFFBFC4D2)
                            : const Color(0xFF697386),
                        fontSize: AppTypography.caption,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 14, color: Color(0xFF2A3042)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Readiness',
                style: TextStyle(
                  color: Color(0xFF7F8EA5),
                  fontSize: AppTypography.caption,
                ),
              ),
              Text(
                '${readiness * 20}%',
                style: const TextStyle(
                  color: Color(0xFFBFC4D2),
                  fontSize: AppTypography.caption,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 3,
              value: readiness / checklist.length,
              backgroundColor: const Color(0xFF252D40),
              valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmissionPanel extends StatelessWidget {
  const _SubmissionPanel({
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
        color: const Color(0xFF171D31),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF293149)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(icon: icon, title: title, accent: accent),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.icon,
    required this.title,
    this.accent = AppTheme.primary,
  });

  final IconData icon;
  final String title;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: accent),
        ),
        const SizedBox(width: 10),
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
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      label,
      style: const TextStyle(
        color: Color(0xFFD6DEEA),
        fontSize: AppTypography.body,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _DeliverableInput extends StatelessWidget {
  const _DeliverableInput({
    required this.format,
    required this.controller,
    required this.enabled,
    required this.onChanged,
    required this.onUploadTap,
  });

  final String format;
  final TextEditingController controller;
  final bool enabled;
  final VoidCallback onChanged;
  final VoidCallback onUploadTap;

  @override
  Widget build(BuildContext context) {
    final linkOnly = _isLinkOnlyFormat(format);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF101522),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF293149)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                linkOnly
                    ? Icons.link_rounded
                    : Icons.insert_drive_file_outlined,
                color: const Color(0xFFD6DEEA),
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _displayFormat(format),
                  style: const TextStyle(
                    color: Color(0xFFE7E9F0),
                    fontSize: AppTypography.body,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _formatDetails(format),
                style: const TextStyle(
                  color: Color(0xFF737C8D),
                  fontSize: AppTypography.caption,
                ),
              ),
            ],
          ),
          if (!linkOnly) ...[
            const SizedBox(height: 9),
            SizedBox(
              height: 40,
              child: OutlinedButton.icon(
                onPressed: enabled ? onUploadTap : null,
                icon: const Icon(Icons.upload_file_rounded, size: 16),
                label: const Text('Upload file'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFBEC4D2),
                  side: const BorderSide(color: Color(0xFF2D3446)),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: Size.zero,
                  textStyle: const TextStyle(
                    fontSize: AppTypography.caption,
                    fontWeight: FontWeight.w700,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 9),
          TextFormField(
            key: ValueKey('deliverable_$format'),
            controller: controller,
            enabled: enabled,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            decoration: _fieldDecoration(
              hintText: linkOnly ? 'Paste link' : 'Paste link (optional)',
            ),
            onChanged: (_) => onChanged(),
            validator: (value) {
              final link = value?.trim() ?? '';
              if (link.isEmpty) return null;
              final uri = Uri.tryParse(link);
              if (uri == null ||
                  !uri.hasAuthority ||
                  uri.host.isEmpty ||
                  (uri.scheme != 'https' && uri.scheme != 'http')) {
                return 'Enter a valid http or https link.';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.isSaving,
    required this.canEdit,
    required this.label,
    required this.onPressed,
  });

  final bool isSaving;
  final bool canEdit;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1020),
        border: Border(top: BorderSide(color: Color(0xFF252B38))),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton.icon(
          key: const ValueKey('submit_solution'),
          onPressed: onPressed,
          icon: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send_rounded, size: 16),
          label: Text(
            isSaving ? 'Submitting...' : label,
            style: const TextStyle(
              fontSize: AppTypography.body,
              fontWeight: FontWeight.w800,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: canEdit
                ? AppTheme.primary
                : const Color(0xFF454956),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvailabilityNotice extends StatelessWidget {
  const _AvailabilityNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF332719),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF62451F)),
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: Color(0xFFFBBF24),
          fontSize: AppTypography.caption,
          height: 1.4,
        ),
      ),
    );
  }
}

class _PageMessage extends StatelessWidget {
  const _PageMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, textAlign: TextAlign.center),
    ),
  );
}

String _normalizedFormat(String format) =>
    format.trim().toLowerCase().replaceAll('presentation deck', 'slide deck');

bool _isHttpLink(String link) {
  final uri = Uri.tryParse(link);
  return uri != null &&
      uri.hasAuthority &&
      uri.host.isNotEmpty &&
      (uri.scheme == 'https' || uri.scheme == 'http');
}

String _displayFormat(String format) =>
    _normalizedFormat(format) == 'slide deck' ? 'Presentation Deck' : format;

String _formatDetails(String format) {
  switch (_normalizedFormat(format)) {
    case 'written report':
      return 'PDF / DOCX';
    case 'design file':
      return 'Figma file or link';
    case 'code repository':
      return 'GitHub link';
    case 'slide deck':
      return 'PPT / PDF';
    case 'video walkthrough':
      return 'Video link';
    case 'spreadsheet':
      return 'Excel / CSV';
    default:
      return 'Add a shareable link';
  }
}

bool _isLinkOnlyFormat(String format) {
  final normalized = _normalizedFormat(format);
  return normalized == 'code repository' || normalized == 'video walkthrough';
}
