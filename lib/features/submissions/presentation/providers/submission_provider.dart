import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/submission.dart';

/// Initial realistic mock submissions matching the official EduBridge database schema
final List<Submission> initialMockSubmissions = [
  Submission(
    id: 'chal_001_talent_current',
    challengeId: 'chal_001',
    talentId: 'talent_current',
    companyId: 'company_uid_101',
    challengeTitle: 'FinTech Mobile Banking Redesign',
    talentName: 'Sarah Jenkins',
    talentEmail: 'sarah.jenkins@edubridge.io',
    solutionText:
        'Redesigned the entire transaction and dashboard flow using Flutter with Clean Architecture and Riverpod. Implemented biometric lock and micro-animations.',
    attachmentUrls: [
      'https://github.com/sarahj/fintech-redesign',
      'https://fintech-preview.web.app',
    ],
    status: 'reviewed',
    isShortlisted: true,
    submittedAt: DateTime.now().subtract(const Duration(days: 2)),
    updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    reviewedAt: DateTime.now().subtract(const Duration(days: 1)),
    feedback:
        'Outstanding UI/UX work and clean architecture structure. Shortlisted for technical interview!',
    pointsAwarded: 96,
  ),
  Submission(
    id: 'chal_002_talent_current',
    challengeId: 'chal_002',
    talentId: 'talent_current',
    companyId: 'company_uid_102',
    challengeTitle: 'AI-Powered Resume Screener',
    talentName: 'Sarah Jenkins',
    talentEmail: 'sarah.jenkins@edubridge.io',
    solutionText:
        'Built an intelligent parsing pipeline with Gemini API that extracts candidate competencies and ranks them against job descriptions.',
    attachmentUrls: [
      'https://github.com/sarahj/ai-resume-screener',
      'https://resume-screener-demo.com',
    ],
    status: 'under_review',
    isShortlisted: false,
    submittedAt: DateTime.now().subtract(const Duration(days: 4)),
    updatedAt: DateTime.now().subtract(const Duration(days: 4)),
  ),
  Submission(
    id: 'chal_003_talent_current',
    challengeId: 'chal_003',
    talentId: 'talent_current',
    companyId: 'company_uid_103',
    challengeTitle: 'E-Commerce One-Click Checkout Flow',
    talentName: 'Sarah Jenkins',
    talentEmail: 'sarah.jenkins@edubridge.io',
    solutionText:
        'Optimized cart abandonment by simplifying the checkout stepper into a single responsive sheet with Apple Pay & Google Pay support.',
    attachmentUrls: [
      'https://github.com/sarahj/one-click-checkout',
    ],
    status: 'submitted',
    isShortlisted: false,
    submittedAt: DateTime.now().subtract(const Duration(days: 7)),
    updatedAt: DateTime.now().subtract(const Duration(days: 7)),
    feedback:
        'Very solid implementation and good test coverage. Consider caching cart states locally.',
    pointsAwarded: 88,
  ),
  Submission(
    id: 'chal_001_talent_002',
    challengeId: 'chal_001',
    talentId: 'talent_002',
    companyId: 'company_uid_101',
    challengeTitle: 'FinTech Mobile Banking Redesign',
    talentName: 'David Kim',
    talentEmail: 'david.kim@dev.io',
    solutionText:
        'Focused on accessibility and multi-currency transfers. Included dark mode and localized strings for 4 languages.',
    attachmentUrls: [
      'https://github.com/davidk/banking-app',
      'https://davidk-banking.web.app',
    ],
    status: 'submitted',
    isShortlisted: false,
    submittedAt: DateTime.now().subtract(const Duration(hours: 14)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 14)),
  ),
  Submission(
    id: 'chal_001_talent_003',
    challengeId: 'chal_001',
    talentId: 'talent_003',
    companyId: 'company_uid_101',
    challengeTitle: 'FinTech Mobile Banking Redesign',
    talentName: 'Elena Rostova',
    talentEmail: 'elena.rostova@design.co',
    solutionText:
        'Pixel-perfect Flutter implementation of high-fidelity Figma components with custom charts and graphs.',
    attachmentUrls: [
      'https://github.com/elenar/bank-ui',
      'https://elena-bank.figma.com',
    ],
    status: 'reviewed',
    isShortlisted: true,
    submittedAt: DateTime.now().subtract(const Duration(days: 3)),
    updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    reviewedAt: DateTime.now().subtract(const Duration(days: 1)),
    feedback: 'Design execution is top-tier. Candidate shortlisted.',
    pointsAwarded: 94,
  ),
];

/// Notifier representing all submissions in memory
class SubmissionsNotifier extends Notifier<List<Submission>> {
  @override
  List<Submission> build() {
    return initialMockSubmissions;
  }

  // Add or update a submission (one submission per talent per challenge: {challengeId}_{talentId})
  Future<bool> submitSolution(Submission submission) async {
    final docId = submission.id.isNotEmpty
        ? submission.id
        : Submission.generateId(submission.challengeId, submission.talentId);

    final finalSubmission = submission.copyWith(id: docId);

    final existingIndex = state.indexWhere((s) => s.id == docId);
    if (existingIndex >= 0) {
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex) finalSubmission else state[i],
      ];
    } else {
      state = [finalSubmission, ...state];
    }
    return true;
  }

  // Update submission status, feedback, points, or shortlist flag (from company review)
  Future<bool> updateStatus(
    String submissionId,
    String status, {
    bool? isShortlisted,
    DateTime? reviewedAt,
    String? feedback,
    int? pointsAwarded,
  }) async {
    state = [
      for (final s in state)
        if (s.id == submissionId)
          s.copyWith(
            status: status,
            isShortlisted: isShortlisted ?? s.isShortlisted,
            reviewedAt: reviewedAt ?? (status == 'reviewed' ? DateTime.now() : s.reviewedAt),
            feedback: feedback ?? s.feedback,
            pointsAwarded: pointsAwarded ?? s.pointsAwarded,
            updatedAt: DateTime.now(),
          )
        else
          s,
    ];
    return true;
  }

  // Delete submission
  Future<bool> delete(String submissionId) async {
    state = state.where((s) => s.id != submissionId).toList();
    return true;
  }
}

/// Main notifier provider for submissions
final submissionsNotifierProvider =
    NotifierProvider<SubmissionsNotifier, List<Submission>>(
  SubmissionsNotifier.new,
);

/// Async state for action handling
class ActionState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const ActionState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  ActionState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return ActionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class SubmissionController extends Notifier<ActionState> {
  @override
  ActionState build() {
    return const ActionState();
  }

  Future<bool> submit(Submission submission) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      await ref.read(submissionsNotifierProvider.notifier).submitSolution(submission);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateStatus(
    String submissionId,
    String status, {
    bool? isShortlisted,
    DateTime? reviewedAt,
    String? feedback,
    int? pointsAwarded,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      await Future.delayed(const Duration(milliseconds: 300));
      await ref.read(submissionsNotifierProvider.notifier).updateStatus(
            submissionId,
            status,
            isShortlisted: isShortlisted,
            reviewedAt: reviewedAt,
            feedback: feedback,
            pointsAwarded: pointsAwarded,
          );
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> delete(String submissionId) async {
    state = state.copyWith(isLoading: true, errorMessage: null, isSuccess: false);
    try {
      await ref.read(submissionsNotifierProvider.notifier).delete(submissionId);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final submissionControllerProvider =
    NotifierProvider<SubmissionController, ActionState>(
  SubmissionController.new,
);

/// Provider filtering submissions by talent ID
final talentSubmissionsProvider =
    Provider.family<List<Submission>, String>((ref, talentId) {
  final all = ref.watch(submissionsNotifierProvider);
  if (talentId.isEmpty || talentId == 'all') return all;
  return all
      .where((s) => s.talentId == talentId || s.talentId == 'talent_current')
      .toList();
});

/// Provider filtering submissions by challenge ID
final challengeSubmissionsProvider =
    Provider.family<List<Submission>, String>((ref, challengeId) {
  final all = ref.watch(submissionsNotifierProvider);
  if (challengeId.isEmpty || challengeId == 'all') return all;
  return all.where((s) => s.challengeId == challengeId).toList();
});

/// Provider filtering submissions by company ID (per schema rule)
final companySubmissionsProvider =
    Provider.family<List<Submission>, String>((ref, companyId) {
  final all = ref.watch(submissionsNotifierProvider);
  if (companyId.isEmpty || companyId == 'all') return all;
  return all.where((s) => s.companyId == companyId).toList();
});
