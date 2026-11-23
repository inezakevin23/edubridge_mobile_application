import 'package:edubridge_mobile_application/config/theme/app_theme.dart';
import 'package:edubridge_mobile_application/features/auth/domain/entities/auth_user.dart';
import 'package:edubridge_mobile_application/features/auth/presentation/providers/auth_providers.dart';
import 'package:edubridge_mobile_application/features/challenges/domain/entities/challenge.dart';
import 'package:edubridge_mobile_application/features/challenges/presentation/providers/challenge_provider.dart';
import 'package:edubridge_mobile_application/features/feedback/domain/entities/submission_feedback.dart';
import 'package:edubridge_mobile_application/features/feedback/presentation/providers/feedback_providers.dart';
import 'package:edubridge_mobile_application/features/profiles/domain/entities/user_profile.dart';
import 'package:edubridge_mobile_application/features/profiles/presentation/providers/profile_provider.dart';
import 'package:edubridge_mobile_application/features/submissions/domain/entities/submission.dart';
import 'package:edubridge_mobile_application/features/submissions/presentation/pages/talent/talent_submissions_page.dart';
import 'package:edubridge_mobile_application/features/submissions/presentation/providers/submission_provider.dart';
import 'package:edubridge_mobile_application/features/notifications/presentation/providers/notification_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('feedback tab shows progress and reviewed submissions', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final reviewedSubmission = Submission(
      id: 'submission-1',
      challengeId: 'challenge-1',
      talentId: 'talent-1',
      companyId: 'company-1',
      solutionText: 'A completed land registry solution.',
      attachmentUrls: const [],
      status: SubmissionStatus.reviewed,
      isShortlisted: true,
      submittedAt: now,
      updatedAt: now,
      reviewedAt: now,
    );
    final pendingSubmission = Submission(
      id: 'submission-2',
      challengeId: 'challenge-2',
      talentId: 'talent-1',
      companyId: 'company-1',
      solutionText: 'A payment gateway optimization.',
      attachmentUrls: const [],
      status: SubmissionStatus.submitted,
      isShortlisted: false,
      submittedAt: now,
      updatedAt: now,
    );
    final firstChallenge = Challenge(
      id: 'challenge-1',
      companyId: 'company-1',
      title: 'Blockchain-Based Land Registry System',
      description: 'Build a secure registry.',
      category: 'Technology',
      requirements: const [],
      deadline: now.add(const Duration(days: 14)),
      status: ChallengeStatus.open,
      createdAt: now,
      updatedAt: now,
    );
    final secondChallenge = Challenge(
      id: 'challenge-2',
      companyId: 'company-1',
      title: 'Pan-African Payment Gateway Optimization',
      description: 'Improve payment processing.',
      category: 'Technology',
      requirements: const [],
      deadline: now.add(const Duration(days: 21)),
      status: ChallengeStatus.open,
      createdAt: now,
      updatedAt: now,
    );
    final feedback = SubmissionFeedback(
      submissionId: reviewedSubmission.id,
      challengeId: firstChallenge.id,
      talentId: reviewedSubmission.talentId,
      companyId: reviewedSubmission.companyId,
      rating: 5,
      pointsAwarded: 87,
      summary: 'Innovative use of blockchain with clear security auditing.',
      strengths: 'Strong implementation.',
      areasForImprovement: 'Add more tests.',
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(
              const AuthUser(
                id: 'talent-1',
                email: 'talent@example.com',
                role: UserRole.talent,
              ),
            ),
          ),
          profileStreamProvider('talent-1').overrideWith(
            (ref) => Stream.value(
              const UserProfile(
                userId: 'talent-1',
                role: 'talent',
                displayName: 'Alex Talent',
                scorePoints: 179,
              ),
            ),
          ),
          profileStreamProvider('company-1').overrideWith(
            (ref) => Stream.value(
              const UserProfile(
                userId: 'company-1',
                role: 'company',
                displayName: 'EduBridge Labs Africa',
              ),
            ),
          ),
          talentSubmissionsProvider('talent-1').overrideWith(
            (ref) => Stream.value([reviewedSubmission, pendingSubmission]),
          ),
          challengeByIdProvider('challenge-1')
              .overrideWith((ref) => Stream.value(firstChallenge)),
          challengeByIdProvider('challenge-2')
              .overrideWith((ref) => Stream.value(secondChallenge)),
          submissionFeedbackProvider('submission-1')
              .overrideWith((ref) => Stream.value(feedback)),
          submissionFeedbackProvider('submission-2')
              .overrideWith((ref) => Stream.value(null)),
          unreadNotificationCountProvider.overrideWith((ref, userId) => 0),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const TalentSubmissionsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('My Feedback'), findsOneWidget);
    expect(find.text('Total Submissions'), findsOneWidget);
    expect(find.text('Score Points'), findsOneWidget);
    expect(find.text('Times Shortlisted'), findsOneWidget);
    expect(find.text('Pending Reviews'), findsOneWidget);
    expect(find.text('179'), findsOneWidget);
    expect(find.text('Blockchain-Based Land Registry System'), findsOneWidget);
    expect(find.text('87/100'), findsOneWidget);
    expect(
      find.text('Innovative use of blockchain with clear security auditing.'),
      findsOneWidget,
    );
    expect(find.text('Feedback'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
