import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:edubridge_mobile/features/auth/presentation/providers/auth_providers.dart';
import 'package:edubridge_mobile/features/feedback/domain/entities/submission_feedback.dart';
import 'package:edubridge_mobile/features/feedback/presentation/providers/feedback_providers.dart';
import 'package:edubridge_mobile/features/feedback/presentation/widgets/feedback_rating_input.dart';

/// Open this page from the company submission-details/review screen.
/// The IDs must come from the submission document, not from form input.
class CompanyFeedbackPage extends ConsumerWidget {
  const CompanyFeedbackPage({
    required this.submissionId,
    required this.challengeId,
    required this.talentId,
    required this.talentName,
    required this.challengeTitle,
    super.key,
  });

  final String submissionId;
  final String challengeId;
  final String talentId;
  final String talentName;
  final String challengeTitle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedbackAsync = ref.watch(submissionFeedbackProvider(submissionId));

    return Scaffold(
      appBar: AppBar(title: const Text('Give feedback')),
      body: feedbackAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _LoadError(error: error),
        data: (existingFeedback) => _CompanyFeedbackForm(
          submissionId: submissionId,
          challengeId: challengeId,
          talentId: talentId,
          talentName: talentName,
          challengeTitle: challengeTitle,
          existingFeedback: existingFeedback,
        ),
      ),
    );
  }
}

class _CompanyFeedbackForm extends ConsumerStatefulWidget {
  const _CompanyFeedbackForm({
    required this.submissionId,
    required this.challengeId,
    required this.talentId,
    required this.talentName,
    required this.challengeTitle,
    required this.existingFeedback,
  });

  final String submissionId;
  final String challengeId;
  final String talentId;
  final String talentName;
  final String challengeTitle;
  final SubmissionFeedback? existingFeedback;

  @override
  ConsumerState<_CompanyFeedbackForm> createState() =>
      _CompanyFeedbackFormState();
}

class _CompanyFeedbackFormState extends ConsumerState<_CompanyFeedbackForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _summaryController;
  late final TextEditingController _strengthsController;
  late final TextEditingController _improvementsController;
  late final TextEditingController _pointsController;
  late int _rating;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final feedback = widget.existingFeedback;
    _summaryController = TextEditingController(text: feedback?.summary ?? '');
    _strengthsController =
        TextEditingController(text: feedback?.strengths ?? '');
    _improvementsController = TextEditingController(
      text: feedback?.areasForImprovement ?? '',
    );
    _pointsController = TextEditingController(
      text: (feedback?.pointsAwarded ?? 0).toString(),
    );
    _rating = feedback?.rating ?? 3;
  }

  @override
  void dispose() {
    _summaryController.dispose();
    _strengthsController.dispose();
    _improvementsController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existingFeedback != null;

    return SafeArea(
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.challengeTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text('Reviewing ${widget.talentName}'),
            const SizedBox(height: 24),
            FeedbackRatingInput(
              rating: _rating,
              onChanged: (rating) => setState(() => _rating = rating),
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _summaryController,
              minLines: 3,
              maxLines: 5,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Overall feedback',
                hintText: 'Explain how well the solution addressed the challenge.',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              validator: (value) {
                if ((value ?? '').trim().length < 10) {
                  return 'Enter at least 10 characters of feedback.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _strengthsController,
              minLines: 2,
              maxLines: 4,
              maxLength: 600,
              decoration: const InputDecoration(
                labelText: 'Strengths (optional)',
                hintText: 'What did the talent do well?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _improvementsController,
              minLines: 2,
              maxLines: 4,
              maxLength: 600,
              decoration: const InputDecoration(
                labelText: 'Areas to improve (optional)',
                hintText: 'What could be improved in a future attempt?',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _pointsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Points awarded (0–100)',
                border: OutlineInputBorder(),
                helperText: 'Award points based on the quality of the submission.',
              ),
              validator: (value) {
                final points = int.tryParse((value ?? '').trim());
                if (points == null || points < 0 || points > 100) {
                  return 'Enter a whole number from 0 to 100.';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _saveFeedback,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(isEditing ? 'Update feedback' : 'Submit feedback'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(firebaseAuthProvider).currentUser;
    if (currentUser == null) {
      _showMessage('You must be signed in to submit feedback.');
      return;
    }

    final feedback = SubmissionFeedback(
      submissionId: widget.submissionId,
      challengeId: widget.challengeId,
      talentId: widget.talentId,
      companyId: currentUser.uid,
      rating: _rating,
      pointsAwarded: int.parse(_pointsController.text.trim()),
      summary: _summaryController.text.trim(),
      strengths: _strengthsController.text.trim(),
      areasForImprovement: _improvementsController.text.trim(),
    );

    setState(() => _isSaving = true);
    try {
      await ref.read(saveSubmissionFeedbackProvider).call(feedback);
      if (!mounted) return;
      _showMessage('Feedback saved successfully.');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Could not save feedback: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Unable to load feedback. $error'),
      ),
    );
  }
}
