import 'package:edubridge_mobile_application/config/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../domain/entities/challenge.dart';
import '../../../../dashboards/presentation/widgets/dashboard_header.dart';
import '../../../../dashboards/presentation/widgets/dashboard_navigation.dart';
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
  final List<GlobalKey> _sectionKeys = List.generate(4, (_) => GlobalKey());
  int _currentStep = 1;
  final _scrollController = ScrollController();
  late final TextEditingController _titleController;
  late final TextEditingController _shortDescriptionController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _durationController;
  late final TextEditingController _skillInputController;
  late final TextEditingController _requirementsController;
  late final TextEditingController _eligibilityController;
  late final TextEditingController _rewardController;
  late final TextEditingController _cashPrizeController;
  late final TextEditingController _teamSizeController;
  late final List<String> _requiredSkills;
  late final List<String> _submissionFormats;
  late String _difficulty;
  late String _accessType;
  late String _participantStatus;
  late DateTime _deadline;
  bool get _isEditing => widget.challenge != null;

  void _goToStep(int step) {
    final targetStep = step.clamp(1, 4).toInt();
    setState(() => _currentStep = targetStep);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final targetContext = _sectionKeys[targetStep - 1].currentContext;
      if (targetContext != null) {
        Scrollable.ensureVisible(
          targetContext,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          alignment: 0.04,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    final challenge = widget.challenge;
    _titleController = TextEditingController(text: challenge?.title ?? '');
    _shortDescriptionController = TextEditingController(
      text: challenge?.shortDescription ?? '',
    );
    _descriptionController = TextEditingController(
      text: challenge?.description ?? '',
    );
    _categoryController = TextEditingController(
      text: challenge?.category ?? '',
    );
    _durationController = TextEditingController(
      text: challenge?.estimatedDuration ?? '',
    );
    _skillInputController = TextEditingController();
    _requiredSkills = [...?challenge?.requiredSkills];
    _requirementsController = TextEditingController(
      text: challenge?.requirements.join('\n') ?? '',
    );
    _eligibilityController = TextEditingController(
      text: challenge?.eligibility ?? '',
    );
    _rewardController = TextEditingController(text: challenge?.reward ?? '');
    _cashPrizeController = TextEditingController(
      text: challenge?.cashPrize ?? '',
    );
    _teamSizeController = TextEditingController(
      text: (challenge?.maxTeamSize ?? 1).toString(),
    );
    _participantStatus = challenge?.participantStatus ?? '';
    _difficulty = challenge?.difficulty ?? 'Intermediate';
    _accessType = challenge?.accessType ?? 'open';
    _submissionFormats = challenge?.submissionFormats.isNotEmpty == true
        ? [...challenge!.submissionFormats]
        : ['Written Report', 'Design File', 'Code Repository'];
    _deadline =
        challenge?.deadline ?? DateTime.now().add(const Duration(days: 14));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _titleController.dispose();
    _shortDescriptionController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _durationController.dispose();
    _skillInputController.dispose();
    _requirementsController.dispose();
    _eligibilityController.dispose();
    _rewardController.dispose();
    _cashPrizeController.dispose();
    _teamSizeController.dispose();
    super.dispose();
  }

  List<String> get _incompleteFields => [
    if (_titleController.text.trim().isEmpty) 'Title',
    if (_categoryController.text.trim().isEmpty) 'Category',
    if (!_deadline.isAfter(DateTime.now())) 'Deadline',
  ];

  Future<void> _showPreview() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          _titleController.text.trim().isEmpty
              ? 'Untitled challenge'
              : _titleController.text.trim(),
        ),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.sizeOf(context).height * 0.62,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _shortDescriptionController.text.trim().isEmpty
                      ? _descriptionController.text.trim()
                      : _shortDescriptionController.text.trim(),
                ),
                const SizedBox(height: 16),
                _PreviewLine(
                  label: 'Category',
                  value: _categoryController.text.trim(),
                ),
                _PreviewLine(label: 'Difficulty', value: _difficulty),
                _PreviewLine(
                  label: 'Duration',
                  value: _durationController.text.trim(),
                ),
                _PreviewLine(
                  label: 'Deadline',
                  value: MaterialLocalizations.of(context)
                      .formatMediumDate(_deadline.toLocal()),
                ),
                _PreviewLine(
                  label: 'Cash prize',
                  value: _cashPrizeController.text.trim().isEmpty
                      ? 'No cash prize'
                      : '\$${_cashPrizeController.text.trim()}',
                ),
                _PreviewLine(
                  label: 'Access',
                  value: _accessType == 'open'
                      ? 'Open challenge'
                      : 'Invite only',
                ),
                _PreviewLine(
                  label: 'Team size',
                  value: _teamSizeController.text.trim(),
                ),
                _PreviewLine(
                  label: 'Participants',
                  value: _participantStatus.isEmpty
                      ? 'All levels'
                      : _participantStatus,
                ),
                _PreviewLine(
                  label: 'Reward',
                  value: _rewardController.text.trim(),
                ),
                _PreviewLine(
                  label: 'Eligibility',
                  value: _eligibilityController.text.trim(),
                ),
                if (_requiredSkills.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Required skills',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: _requiredSkills
                        .map((skill) => Chip(label: Text(skill)))
                        .toList(growable: false),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Requirements',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                ..._parseLines(_requirementsController.text)
                    .asMap()
                    .entries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('${entry.key + 1}. ${entry.value}'),
                      ),
                    ),
                const SizedBox(height: 12),
                Text(
                  'Accepted formats',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  _submissionFormats.isEmpty
                      ? 'No formats selected'
                      : _submissionFormats.join(', '),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close preview'),
          ),
        ],
      ),
    );
  }

  Widget _stepSelector() {
    const steps = [
      'Basic\nInformation',
      'Requirements &\nDeliverables',
      'Rewards &\nAccess',
      'Review &\nPublish',
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFF131C2E),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFF26334A)),
      ),
      child: Row(
        children: [
          for (var index = 0; index < steps.length; index++) ...[
            Expanded(child: _stepTile(index + 1, steps[index])),
            if (index < steps.length - 1)
              Container(width: 9, height: 1, color: const Color(0xFF46516A)),
          ],
        ],
      ),
    );
  }

  Widget _stepTile(int step, String label) {
    final theme = Theme.of(context);
    final active = _currentStep == step;
    final completed = _currentStep > step;
    final color = active
        ? theme.colorScheme.primary
        : completed
        ? theme.colorScheme.secondary
        : theme.colorScheme.onSurfaceVariant;
    return Material(
      color: active
          ? theme.colorScheme.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _goToStep(step),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 19,
                height: 19,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.65)),
                  color: active
                      ? theme.colorScheme.primary.withValues(alpha: 0.2)
                      : Colors.transparent,
                ),
                child: completed
                    ? Icon(Icons.check_rounded, size: 12, color: color)
                    : Text(
                        '$step',
                        style: TextStyle(
                          color: color,
                          fontSize: AppTypography.micro,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: color,
                  fontSize: AppTypography.micro,
                  height: 1.05,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reviewSection() {
    final incompleteFields = _incompleteFields;
    final theme = Theme.of(context);
    return _FormSection(
      icon: Icons.send_outlined,
      title: 'Review & Publish',
      subtitle: 'Review the challenge details before publishing.',
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _titleController.text.trim().isEmpty
                          ? 'Untitled challenge'
                          : _titleController.text.trim(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Chip(label: Text('Draft')),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _shortDescriptionController.text.trim().isEmpty
                    ? 'Add a short description for the challenge listing.'
                    : _shortDescriptionController.text.trim(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ReviewChip(
                    label: 'Category',
                    value: _categoryController.text.trim(),
                  ),
                  _ReviewChip(label: 'Difficulty', value: _difficulty),
                  _ReviewChip(
                    label: 'Deadline',
                    value: MaterialLocalizations.of(context)
                        .formatMediumDate(_deadline.toLocal()),
                  ),
                  _ReviewChip(
                    label: 'Cash prize',
                    value: _cashPrizeController.text.trim().isEmpty
                        ? 'None'
                        : '\$${_cashPrizeController.text.trim()}',
                  ),
                  _ReviewChip(
                    label: 'Requirements',
                    value:
                        '${_parseLines(_requirementsController.text).length} added',
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.secondary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.secondary.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            incompleteFields.isEmpty
                ? 'All required review fields are complete.'
                : '${incompleteFields.length} fields need attention: '
                      '${incompleteFields.join(', ')}. You can save this as a draft.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('challenge_preview'),
                onPressed: ref.watch(challengeActionsProvider).isLoading
                    ? null
                    : _showPreview,
                icon: const Icon(Icons.visibility_outlined, size: 16),
                label: const Text('Preview'),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('challenge_save_draft'),
                onPressed: ref.watch(challengeActionsProvider).isLoading
                    ? null
                    : () => _save(status: ChallengeStatus.draft),
                icon: const Icon(Icons.save_outlined, size: 16),
                label: const Text('Save as draft'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _publishButton(bool isSaving) {
    return FilledButton.icon(
      key: const ValueKey('challenge_publish'),
      onPressed: isSaving ? null : () => _save(status: ChallengeStatus.open),
      icon: isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.publish_rounded, size: 17),
      label: Text(_isEditing ? 'Update & publish' : 'Publish challenge'),
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFFF59E0B),
        foregroundColor: const Color(0xFF171923),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }

  bool _addSkill() {
    final skill = _skillInputController.text.trim();
    if (skill.isEmpty) return true;
    if (_requiredSkills.any(
      (existing) => existing.toLowerCase() == skill.toLowerCase(),
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('That skill has already been added.')),
      );
      _skillInputController.clear();
      return true;
    }
    if (_requiredSkills.length >= 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can add up to 12 required skills.')),
      );
      return false;
    }
    setState(() {
      _requiredSkills.add(skill);
      _skillInputController.clear();
    });
    return true;
  }

  String? _publishValidationError() {
    final title = _titleController.text.trim();
    if (title.length < 5) {
      return 'Enter a challenge title of at least 5 characters.';
    }

    final summary = _shortDescriptionController.text.trim();
    if ((!_isEditing || summary.isNotEmpty) && summary.length < 20) {
      return 'Enter a short description of at least 20 characters.';
    }

    final description = _descriptionController.text.trim();
    if (description.length < 20) {
      return 'Describe the challenge in at least 20 characters.';
    }
    if (!_isEditing && _durationController.text.trim().isEmpty) {
      return 'Enter an estimated challenge duration.';
    }
    if (_categoryController.text.trim().isEmpty) {
      return 'Choose or enter a challenge category.';
    }
    if (_requiredSkills.isEmpty) return 'Add at least one required skill.';

    final requirements = _parseLines(_requirementsController.text);
    if (requirements.isEmpty) return 'Add at least one requirement.';
    if (requirements.length > 20) {
      return 'You can add up to 20 requirements.';
    }
    if (_requiredSkills.length > 12) {
      return 'You can add up to 12 required skills.';
    }

    final prize = _cashPrizeController.text.trim();
    final parsedPrize = num.tryParse(prize);
    if (prize.isNotEmpty && (parsedPrize == null || parsedPrize < 0)) {
      return 'Enter a valid non-negative cash prize.';
    }
    final teamSize = int.tryParse(_teamSizeController.text.trim());
    if (teamSize == null || teamSize < 1 || teamSize > 20) {
      return 'Enter a maximum team size from 1 to 20.';
    }
    if (!_deadline.isAfter(DateTime.now())) {
      return 'Choose a future submission deadline.';
    }
    return null;
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

  Future<void> _save({required ChallengeStatus status}) async {
    if (!_addSkill()) return;
    if (status == ChallengeStatus.open) {
      final validationError = _publishValidationError();
      if (validationError != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(validationError)));
        return;
      }
    } else if (_titleController.text.trim().isEmpty ||
        _categoryController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a challenge title and category to save a draft.',
          ),
        ),
      );
      return;
    }

    final requirements = _parseLines(_requirementsController.text);
    final requiredSkills = List<String>.unmodifiable(_requiredSkills);

    if (status == ChallengeStatus.open && requirements.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one requirement.')),
      );
      return;
    }
    if (requiredSkills.length > 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can add up to 12 required skills.')),
      );
      return;
    }
    if (requirements.length > 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can add up to 20 requirements.')),
      );
      return;
    }
    if (status == ChallengeStatus.open && !_deadline.isAfter(DateTime.now())) {
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
            shortDescription: _shortDescriptionController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _categoryController.text.trim(),
            estimatedDuration: _durationController.text.trim(),
            requiredSkills: requiredSkills,
            difficulty: _difficulty,
            submissionFormats: _submissionFormats,
            maxTeamSize: int.parse(_teamSizeController.text.trim()),
            participantStatus: _participantStatus,
            accessType: _accessType,
            cashPrize: _cashPrizeController.text.trim(),
            requirements: requirements,
            eligibility: _eligibilityController.text.trim(),
            reward: _rewardController.text.trim(),
            deadline: _deadline,
            status: status,
          ),
        );
      } else {
        await actions.createChallenge(
          companyId: widget.companyId,
          title: _titleController.text.trim(),
          shortDescription: _shortDescriptionController.text.trim(),
          description: _descriptionController.text.trim(),
          category: _categoryController.text.trim(),
          estimatedDuration: _durationController.text.trim(),
          requiredSkills: requiredSkills,
          difficulty: _difficulty,
          submissionFormats: _submissionFormats,
          maxTeamSize: int.parse(_teamSizeController.text.trim()),
          participantStatus: _participantStatus,
          accessType: _accessType,
          cashPrize: _cashPrizeController.text.trim(),
          requirements: requirements,
          eligibility: _eligibilityController.text.trim(),
          reward: _rewardController.text.trim(),
          deadline: _deadline,
          status: status,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Challenge updated successfully.'
                : status == ChallengeStatus.draft
                ? 'Challenge saved as a draft.'
                : 'Challenge published successfully.',
          ),
        ),
      );
      context.go('/company/challenges/manage');
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

  List<String> _parseLines(String value) => value
      .split('\n')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(challengeActionsProvider).isLoading;
    final formattedDeadline = MaterialLocalizations.of(context)
        .formatMediumDate(_deadline.toLocal());
    const suggestedCategories = [
      'Software Development',
      'Design',
      'Data & AI',
      'Marketing',
    ];
    const submissionFormatOptions = [
      'Written Report',
      'Design File',
      'Code Repository',
      'Slide Deck',
      'Video Walkthrough',
      'Spreadsheet',
    ];

    final theme = Theme.of(context);
    final compactInputTheme = theme.inputDecorationTheme.copyWith(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Color(0xFF26334A)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Color(0xFF26334A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(11),
        borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.3),
      ),
    );

    return Scaffold(
      appBar: DashboardHeader(
        notificationUserId: widget.companyId,
        showBackButton: true,
        backFallbackPath: '/company/challenges/manage',
      ),
      body: Theme(
        data: theme.copyWith(inputDecorationTheme: compactInputTheme),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Challenges / Create challenge',
                    style: TextStyle(color: Color(0xFFB69BEE), fontSize: AppTypography.micro),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isEditing ? 'Edit a Challenge' : 'Create a Challenge',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontSize: AppTypography.title,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Fill in the details below to create your challenge.',
                    style: TextStyle(color: Color(0xFF9296A6), fontSize: AppTypography.caption),
                  ),
                  const SizedBox(height: 12),
                  _stepSelector(),
                  const SizedBox(height: 10),
                  KeyedSubtree(
                    key: _sectionKeys[0],
                    child: _FormSection(
                      icon: Icons.edit_note_rounded,
                      title: 'Basic Information',
                      subtitle: 'Describe the challenge and what participants need to do.',
                      children: [
                        TextFormField(
                          controller: _titleController,
                          textCapitalization: TextCapitalization.sentences,
                          maxLength: 100,
                          decoration: const InputDecoration(
                            labelText: 'Challenge Title',
                            hintText:
                                'e.g. Improve customer feedback management',
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
                        const SizedBox(height: 9),
                        TextFormField(
                          controller: _shortDescriptionController,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 2,
                          maxLines: 3,
                          maxLength: 180,
                          decoration: const InputDecoration(
                            labelText: 'Short Description',
                            hintText:
                                'A quick summary shown in challenge listings',
                            alignLabelWithHint: true,
                          ),
                          validator: (value) {
                            final text = value?.trim() ?? '';
                            if (_isEditing && text.isEmpty) return null;
                            if (text.isEmpty) {
                              return 'Enter a short description.';
                            }
                            if (text.length < 20) {
                              return 'Use at least 20 characters.';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 9),
                        TextFormField(
                          controller: _descriptionController,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 3,
                          maxLines: 6,
                          maxLength: 2000,
                          decoration: const InputDecoration(
                            labelText: 'Challenge Description',
                            hintText: 'Explain the problem, context, and expected outcome...',
                            alignLabelWithHint: true,
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
                        const SizedBox(height: 9),
                        TextFormField(
                          controller: _categoryController,
                          textCapitalization: TextCapitalization.words,
                          maxLength: 60,
                          decoration: const InputDecoration(
                            labelText: 'Category',
                            hintText: 'Choose a suggestion or enter your own',
                          ),
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Enter a category.'
                              : null,
                        ),
                        Wrap(
                          spacing: 6,
                          runSpacing: 2,
                          children: suggestedCategories
                              .map(
                                (category) => ActionChip(
                                  label: Text(category),
                                  onPressed: () => setState(
                                    () => _categoryController.text = category,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                        const SizedBox(height: 9),
                        DropdownButtonFormField<String>(
                          initialValue: _difficulty,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Difficulty Level',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Beginner',
                              child: Text('Beginner'),
                            ),
                            DropdownMenuItem(
                              value: 'Intermediate',
                              child: Text('Intermediate'),
                            ),
                            DropdownMenuItem(
                              value: 'Advanced',
                              child: Text('Advanced'),
                            ),
                          ],
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _difficulty = value);
                                  }
                                },
                        ),
                        const SizedBox(height: 9),
                        if (_requiredSkills.isNotEmpty) ...[
                          Wrap(
                            spacing: 6,
                            runSpacing: 3,
                            children: _requiredSkills
                                .map(
                                  (skill) => InputChip(
                                    label: Text(skill),
                                    onDeleted: isSaving
                                        ? null
                                        : () => setState(
                                            () => _requiredSkills.remove(skill),
                                          ),
                                  ),
                                )
                                .toList(growable: false),
                          ),
                          const SizedBox(height: 6),
                        ],
                        TextField(
                          controller: _skillInputController,
                          enabled: !isSaving,
                          textCapitalization: TextCapitalization.words,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _addSkill(),
                          decoration: InputDecoration(
                            labelText: 'Required Skills',
                            hintText: 'Add a skill',
                            helperText: 'Up to 12 skills.',
                            suffixIcon: IconButton(
                              tooltip: 'Add skill',
                              onPressed: isSaving ? null : _addSkill,
                              icon: const Icon(Icons.add_rounded),
                            ),
                          ),
                        ),
                        const SizedBox(height: 9),
                        TextFormField(
                          controller: _durationController,
                          textCapitalization: TextCapitalization.sentences,
                          maxLength: 40,
                          decoration: const InputDecoration(
                            labelText: 'Estimated Duration',
                            hintText: 'e.g. 2-3 weeks',
                          ),
                          validator: (value) {
                            if (_isEditing &&
                                (value == null || value.trim().isEmpty)) {
                              return null;
                            }
                            return value == null || value.trim().isEmpty
                                ? 'Enter an estimated duration.'
                                : null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 9),
                  KeyedSubtree(
                    key: _sectionKeys[1],
                    child: _FormSection(
                      icon: Icons.checklist_rounded,
                      title: 'Requirements & Deliverables',
                      subtitle:
                          'Specify what a complete submission should include.',
                      children: [
                        TextFormField(
                          controller: _requirementsController,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 3,
                          maxLines: 5,
                          decoration: const InputDecoration(
                            labelText: 'Requirements',
                            hintText: 'Add one requirement per line',
                            helperText: 'Add at least one, up to 20.',
                            alignLabelWithHint: true,
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Accepted Submission Formats',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: AppTypography.caption,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: submissionFormatOptions
                              .map(
                                (format) => FilterChip(
                                  label: Text(format),
                                  selected: _submissionFormats.contains(format),
                                  onSelected: isSaving
                                      ? null
                                      : (selected) {
                                          setState(() {
                                            if (selected) {
                                              _submissionFormats.add(format);
                                            } else {
                                              _submissionFormats.remove(format);
                                            }
                                          });
                                        },
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 9),
                  KeyedSubtree(
                    key: _sectionKeys[2],
                    child: _FormSection(
                      icon: Icons.verified_outlined,
                      title: 'Rewards & Access Control',
                      subtitle:
                          'Set participation, rewards, and submission timing.',
                      children: [
                        const Text(
                          'Challenge Access Type',
                          style: TextStyle(
                            color: Color(0xFFBFC4D2),
                            fontSize: AppTypography.micro,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 7,
                          children: [
                            ChoiceChip(
                              label: const Text('Open Challenge'),
                              selected: _accessType == 'open',
                              onSelected: isSaving
                                  ? null
                                  : (_) => setState(() => _accessType = 'open'),
                            ),
                            ChoiceChip(
                              label: const Text('Invite Only'),
                              selected: _accessType == 'invite-only',
                              onSelected: isSaving
                                  ? null
                                  : (_) => setState(
                                      () => _accessType = 'invite-only',
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: isSaving ? null : _chooseDeadline,
                          icon: const Icon(
                            Icons.calendar_month_outlined,
                            size: 16,
                          ),
                          label: Text(
                            'Submission Deadline   $formattedDeadline',
                          ),
                        ),
                        const SizedBox(height: 9),
                        TextFormField(
                          controller: _teamSizeController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Maximum Team Size',
                            hintText: 'e.g. 1',
                          ),
                          validator: (value) {
                            final count = int.tryParse(value?.trim() ?? '');
                            return count == null || count < 1 || count > 20
                                ? 'Enter a team size from 1 to 20.'
                                : null;
                          },
                        ),
                        const SizedBox(height: 9),
                        DropdownButtonFormField<String>(
                          initialValue: _participantStatus,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Target Participant Status',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: '',
                              child: Text('All levels'),
                            ),
                            DropdownMenuItem(
                              value: 'Students',
                              child: Text('Students'),
                            ),
                            DropdownMenuItem(
                              value: 'Graduates',
                              child: Text('Graduates'),
                            ),
                            DropdownMenuItem(
                              value: 'Top performers',
                              child: Text('Top performers'),
                            ),
                          ],
                          onChanged: isSaving
                              ? null
                              : (value) {
                                  if (value != null) {
                                    setState(() => _participantStatus = value);
                                  }
                                },
                        ),
                        const SizedBox(height: 9),
                        TextFormField(
                          controller: _cashPrizeController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Cash Prize (Optional)',
                            prefixText: '\$ ',
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return null;
                            }
                            final amount = num.tryParse(value.trim());
                            return amount == null || amount < 0
                                ? 'Enter a valid non-negative prize.'
                                : null;
                          },
                        ),
                        const SizedBox(height: 9),
                        TextFormField(
                          controller: _rewardController,
                          textCapitalization: TextCapitalization.sentences,
                          maxLength: 120,
                          decoration: const InputDecoration(
                            labelText: 'Reward or Recognition (Optional)',
                            hintText: 'e.g. Certificate, mentorship, prize',
                          ),
                        ),
                        const SizedBox(height: 9),
                        TextFormField(
                          controller: _eligibilityController,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 2,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            labelText: 'Eligibility (Optional)',
                            hintText: 'Who can participate?',
                            alignLabelWithHint: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 9),
                  KeyedSubtree(key: _sectionKeys[3], child: _reviewSection()),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
            child: SizedBox(
              width: double.infinity,
              child: _publishButton(isSaving),
            ),
          ),
          DashboardNavigation(
            currentIndex: 1,
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
          ),
        ],
      ),
    );
  }
}

class _ReviewChip extends StatelessWidget {
  const _ReviewChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: ${value.isEmpty ? 'Not set' : value}'),
      visualDensity: VisualDensity.compact,
      labelStyle: const TextStyle(fontSize: AppTypography.micro),
      padding: const EdgeInsets.symmetric(horizontal: 3),
    );
  }
}

class _PreviewLine extends StatelessWidget {
  const _PreviewLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? 'Not set' : value)),
        ],
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: AppTypography.caption,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: AppTypography.micro,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...children,
          ],
        ),
      ),
    );
  }
}
