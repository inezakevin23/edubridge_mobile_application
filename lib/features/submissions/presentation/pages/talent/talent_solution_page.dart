import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../challenges/domain/entities/challenge.dart';

import '../../../../challenges/presentation/providers/challenge_provider.dart';
import '../../../domain/entities/submission.dart';
import '../../providers/submission_provider.dart';

class TalentSolutionPage extends ConsumerStatefulWidget {
  const TalentSolutionPage({required this.challengeId, super.key});

  final String challengeId;

  @override
  ConsumerState<TalentSolutionPage> createState() =>
      _TalentSolutionPageState();
}

class _TalentSolutionPageState extends ConsumerState<TalentSolutionPage> {
  final _formKey = GlobalKey<FormState>();
  final _solutionController = TextEditingController();
  final _attachmentsController = TextEditingController();
  bool _initialValuesLoaded = false;
  bool _hasUserEdited = false;

  @override
  void dispose() {
    _solutionController.dispose();
    _attachmentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authAsync = ref.watch(submissionAuthStateProvider);
    final actionsAsync = ref.watch(submissionActionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Submit your solution')),
      body: authAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => const _PageMessage(
          message: 'Unable to verify your account. Please try again.',
        ),
        data: (user) {
          if (user == null) {
            return const _PageMessage(message: 'Please sign in to submit a solution.');
          }
          return _buildChallengeForm(context, user, actionsAsync.isLoading);
        },
      ),
    );
  }

  Widget _buildChallengeForm(
    BuildContext context,
    User user,
    bool isSaving,
  ) {
    final challengeAsync = ref.watch(challengeByIdProvider(widget.challengeId));
    final submissionAsync = ref.watch(
      submissionForChallengeProvider(
        SubmissionLookup(challengeId: widget.challengeId, talentId: user.uid),
      ),
    );

    return challengeAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => const _PageMessage(
        message: 'Unable to load this challenge. Please try again.',
      ),
      data: (challenge) {
        if (challenge == null) {
          return const _PageMessage(message: 'This challenge could not be found.');
        }

        return submissionAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => const _PageMessage(
            message: 'Unable to load your existing submission.',
          ),
          data: (existingSubmission) {
            if (!_initialValuesLoaded && existingSubmission != null) {
              if (!_hasUserEdited) {
                _solutionController.text = existingSubmission.solutionText;
                _attachmentsController.text =
                    existingSubmission.attachmentUrls.join('\n');
              }
              _initialValuesLoaded = true;
            }

            final alreadyReviewed = existingSubmission != null &&
                !existingSubmission.canBeEdited;
            final challengeAvailable = challenge.isOpen &&
                !challenge.isPastDeadline;
            final canEdit = !alreadyReviewed && challengeAvailable;

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    challenge.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(challenge.description),
                  const SizedBox(height: 20),
                  if (existingSubmission != null) ...[
                    Text(
                      'Submission status: ${existingSubmission.status.label}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextFormField(
                    controller: _solutionController,
                    enabled: canEdit && !isSaving,
                    minLines: 8,
                    maxLines: 14,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Your solution',
                      hintText: 'Explain your approach and how it solves the challenge...',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      _hasUserEdited = true;
                    },
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.length < 30) {
                        return 'Please provide at least 30 characters.';
                      }
                      if (text.length > 10000) {
                        return 'Your solution must be 10,000 characters or fewer.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _attachmentsController,
                    enabled: canEdit && !isSaving,
                    minLines: 2,
                    maxLines: 5,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'Supporting links (optional)',
                      hintText: 'Add one https:// link per line',
                      helperText: 'For example, a project demo, repository or document link.',
                      alignLabelWithHint: true,
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      _hasUserEdited = true;
                    },
                    validator: _validateAttachmentLinks,
                  ),
                  const SizedBox(height: 20),
                  if (!challengeAvailable)
                    const _Notice(
                      message: 'This challenge is closed or its deadline has passed. New submissions and edits are unavailable.',
                    ),
                  if (alreadyReviewed)
                    const _Notice(
                      message: 'Your solution is no longer editable because the Company has started reviewing it.',
                    ),
                  if (canEdit)
                    FilledButton.icon(
                      onPressed: isSaving ? null : () => _save(context, user, challenge, existingSubmission),
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_outlined),
                      label: Text(existingSubmission == null ? 'Submit solution' : 'Update solution'),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String? _validateAttachmentLinks(String? value) {
    final links = (value ?? '')
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty);
    for (final link in links) {
      final uri = Uri.tryParse(link);
      if (uri == null ||
          !uri.hasAuthority ||
          uri.host.isEmpty ||
          (uri.scheme != 'https' && uri.scheme != 'http')) {
        return 'Enter valid http or https links, one per line.';
      }
    }
    return null;
  }

  Future<void> _save(
    BuildContext context,
    User user,
    Challenge challenge,
    Submission? existingSubmission,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    final links = _attachmentsController.text
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);

    try {
      if (existingSubmission == null) {
        await ref.read(submissionActionsProvider.notifier).submitSolution(
              challengeId: widget.challengeId,
              talentId: user.uid,
              companyId: challenge.companyId,
              solutionText: _solutionController.text,
              attachmentUrls: links,
            );
      } else {
        await ref.read(submissionActionsProvider.notifier).updateTalentSubmission(
              submission: existingSubmission,
              solutionText: _solutionController.text,
              attachmentUrls: links,
            );
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(existingSubmission == null
              ? 'Your solution was submitted.'
              : 'Your solution was updated.'),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(error))),
      );
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('already been submitted')) return 'You have already submitted a solution for this challenge.';
    if (message.contains('closed') || message.contains('deadline')) return 'This challenge is no longer accepting submissions.';
    if (message.contains('permission-denied')) return 'You are not allowed to perform this action.';
    return 'We could not save your solution. Please try again.';
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

class _Notice extends StatelessWidget {
  const _Notice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message),
    );
  }
}
