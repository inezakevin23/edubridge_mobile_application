import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/submission.dart';
import '../../providers/submission_provider.dart';

class TalentSolutionPage extends ConsumerStatefulWidget {
  final String challengeId;
  final String challengeTitle;
  final String companyId;
  final Submission? initialSubmission;

  const TalentSolutionPage({
    super.key,
    required this.challengeId,
    required this.challengeTitle,
    this.companyId = 'company_uid_101',
    this.initialSubmission,
  });

  @override
  ConsumerState<TalentSolutionPage> createState() => _TalentSolutionPageState();
}

class _TalentSolutionPageState extends ConsumerState<TalentSolutionPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _descriptionController;
  late TextEditingController _githubUrlController;
  late TextEditingController _liveDemoUrlController;

  static const Color bgColor = Color(0xFF0E121A);
  static const Color cardColor = Color(0xFF1E2235);
  static const Color borderColor = Color(0xFF2A2F45);
  static const Color primaryPurple = Color(0xFF7C3BED);
  static const Color textSecondary = Color(0xFF94A3B8);

  @override
  void initState() {
    super.initState();
    _descriptionController = TextEditingController(
      text: widget.initialSubmission?.description ?? '',
    );
    _githubUrlController = TextEditingController(
      text: widget.initialSubmission?.githubUrl ?? '',
    );
    _liveDemoUrlController = TextEditingController(
      text: widget.initialSubmission?.liveDemoUrl ?? '',
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _githubUrlController.dispose();
    _liveDemoUrlController.dispose();
    super.dispose();
  }

  String? _validateUrl(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      if (required) return 'This field is required';
      return null;
    }
    final trimmed = value.trim();
    final uri = Uri.tryParse(trimmed);
    if (uri == null || (!uri.isScheme('http') && !uri.isScheme('https'))) {
      return 'Please enter a valid URL (e.g. https://github.com/...)';
    }
    return null;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    // Use current talent info or mock defaults
    final talentId =
        widget.initialSubmission?.talentId ?? 'talent_current';
    final talentName =
        widget.initialSubmission?.talentName ?? 'Sarah Jenkins';
    final talentEmail =
        widget.initialSubmission?.talentEmail ?? 'sarah.jenkins@edubridge.io';

    final attachments = <String>[];
    if (_githubUrlController.text.trim().isNotEmpty) {
      attachments.add(_githubUrlController.text.trim());
    }
    if (_liveDemoUrlController.text.trim().isNotEmpty) {
      attachments.add(_liveDemoUrlController.text.trim());
    }

    final submission = Submission(
      id: widget.initialSubmission?.id ??
          Submission.generateId(widget.challengeId, talentId),
      challengeId: widget.challengeId,
      challengeTitle: widget.challengeTitle,
      companyId: widget.initialSubmission?.companyId ?? widget.companyId,
      talentId: talentId,
      talentName: talentName,
      talentEmail: talentEmail,
      solutionText: _descriptionController.text.trim(),
      attachmentUrls: attachments,
      status: widget.initialSubmission?.status ?? 'submitted',
      isShortlisted: widget.initialSubmission?.isShortlisted ?? false,
      submittedAt: widget.initialSubmission?.submittedAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      feedback: widget.initialSubmission?.feedback,
      pointsAwarded: widget.initialSubmission?.pointsAwarded,
    );

    final success = await ref
        .read(submissionControllerProvider.notifier)
        .submit(submission);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.initialSubmission == null
                ? 'Solution submitted successfully!'
                : 'Solution updated successfully!'),
            backgroundColor: Colors.green.shade700,
          ),
        );
        Navigator.pop(context);
      } else {
        final error = ref.read(submissionControllerProvider).errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to submit solution'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionState = ref.watch(submissionControllerProvider);
    final isEditing = widget.initialSubmission != null;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          isEditing ? 'Edit Solution' : 'Submit Solution',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Challenge Context Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: primaryPurple.withOpacity(0.4)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.stars, color: primaryPurple, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'Target Challenge',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: primaryPurple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.challengeTitle.isNotEmpty
                            ? widget.challengeTitle
                            : 'Challenge #${widget.challengeId}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Description Field
                const Text(
                  'Solution Description & Approach *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText:
                        'Detail your technical approach, architecture decisions, tools used, and how you met the challenge criteria...',
                    hintStyle:
                        TextStyle(color: textSecondary.withOpacity(0.5)),
                    filled: true,
                    fillColor: cardColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryPurple),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please provide a description of your solution';
                    }
                    if (value.trim().length < 20) {
                      return 'Description must be at least 20 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // GitHub Repo URL Field
                const Text(
                  'GitHub Repository URL *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _githubUrlController,
                  keyboardType: TextInputType.url,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon:
                        const Icon(Icons.code, color: primaryPurple, size: 20),
                    hintText: 'https://github.com/username/project',
                    hintStyle:
                        TextStyle(color: textSecondary.withOpacity(0.5)),
                    filled: true,
                    fillColor: cardColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryPurple),
                    ),
                  ),
                  validator: (val) => _validateUrl(val, required: true),
                ),
                const SizedBox(height: 20),

                // Live Demo URL Field
                const Text(
                  'Live Demo / Video Link (Optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _liveDemoUrlController,
                  keyboardType: TextInputType.url,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon:
                        const Icon(Icons.link, color: primaryPurple, size: 20),
                    hintText: 'https://my-demo-app.web.app or Loom video URL',
                    hintStyle:
                        TextStyle(color: textSecondary.withOpacity(0.5)),
                    filled: true,
                    fillColor: cardColor,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: borderColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: primaryPurple),
                    ),
                  ),
                  validator: (val) => _validateUrl(val, required: false),
                ),
                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: actionState.isLoading ? null : _handleSubmit,
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
                      : Text(
                          isEditing ? 'Update Solution' : 'Submit Solution',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
