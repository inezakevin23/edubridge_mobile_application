import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/challenge.dart';
import '../../providers/challenge_provider.dart';

class CreateChallengePage extends ConsumerStatefulWidget {
  const CreateChallengePage({
    required this.companyId,
    this.challenge,
    super.key,
  });

  final String companyId;
  final Challenge? challenge;

  @override
  ConsumerState<CreateChallengePage> createState() =>
      _CreateChallengePageState();
}

class _CreateChallengePageState extends ConsumerState<CreateChallengePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _requirementsController;
  late DateTime _deadline;

  bool get _isEditing => widget.challenge != null;

  @override
  void initState() {
    super.initState();
    final challenge = widget.challenge;
    _titleController = TextEditingController(text: challenge?.title ?? '');
    _descriptionController = TextEditingController(
      text: challenge?.description ?? '',
    );
    _categoryController = TextEditingController(
      text: challenge?.category ?? '',
    );
    _requirementsController = TextEditingController(
      text: challenge?.requirements.join('\n') ?? '',
    );
    _deadline =
        challenge?.deadline ?? DateTime.now().add(const Duration(days: 14));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  Future<void> _chooseDeadline() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline.isBefore(now)
          ? now.add(const Duration(days: 1))
          : _deadline,
      firstDate: now,
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null && mounted) {
      setState(
        () => _deadline = DateTime(
          picked.year,
          picked.month,
          picked.day,
          23,
          59,
          59,
        ),
      );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final requirements = _requirementsController.text
        .split('\n')
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();

    if (requirements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one requirement.')),
      );
      return;
    }
    if (requirements.length > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can add up to 20 requirements.')),
      );
      return;
    }
    final mustHaveFutureDeadline = !_isEditing || widget.challenge!.isOpen;
    if (mustHaveFutureDeadline && !_deadline.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a future submission deadline.')),
      );
      return;
    }

    try {
      final actions = ref.read(challengeActionsProvider.notifier);
      if (_isEditing) {
        final existing = widget.challenge!;
        await actions.updateChallenge(
          existing.copyWith(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _categoryController.text.trim(),
            requirements: requirements,
            deadline: _deadline,
          ),
        );
      } else {
        await actions.createChallenge(
          companyId: widget.companyId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _categoryController.text.trim(),
          requirements: requirements,
          deadline: _deadline,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Challenge updated successfully.'
                : 'Challenge published successfully.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_friendlyError(error))));
    }
  }

  String _friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('permission-denied')) {
      return 'You do not have permission to perform this action.';
    }
    if (text.contains('network')) {
      return 'Network error. Check your connection and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(challengeActionsProvider).isLoading;
    final formattedDeadline = MaterialLocalizations.of(context)
        .formatMediumDate(_deadline.toLocal());

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit challenge' : 'Create a challenge'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Describe a real problem your company wants Talent to solve.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Challenge title',
                hintText: 'e.g. Improve customer feedback management',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Enter a title.';
                }
                if (value.trim().length < 5) {
                  return 'Title must be at least 5 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              textCapitalization: TextCapitalization.sentences,
              minLines: 4,
              maxLines: 7,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Problem description',
                hintText: 'Explain the problem and the outcome you expect...',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Describe the challenge.';
                }
                if (value.trim().length < 20) {
                  return 'Description must be at least 20 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _categoryController,
              textCapitalization: TextCapitalization.words,
              maxLength: 60,
              decoration: const InputDecoration(
                labelText: 'Category',
                hintText: 'e.g. Software Development, Marketing, Design',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Enter a category.'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _requirementsController,
              textCapitalization: TextCapitalization.sentences,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Requirements',
                hintText: 'Enter one requirement per line',
                helperText: 'For example: Understand the problem\nPropose a practical solution',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: isSaving ? null : _chooseDeadline,
              icon: const Icon(Icons.calendar_month_outlined),
              label: Text('Submission deadline: $formattedDeadline'),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: isSaving ? null : _save,
              child: isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEditing ? 'Save changes' : 'Publish challenge'),
            ),
          ],
        ),
      ),
    );
  }
}
