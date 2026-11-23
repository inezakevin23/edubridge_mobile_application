import 'package:edubridge_mobile_application/config/theme/app_theme.dart';
import 'package:edubridge_mobile_application/features/challenges/domain/entities/challenge.dart';
import 'package:edubridge_mobile_application/features/challenges/presentation/providers/challenge_provider.dart';
import 'package:edubridge_mobile_application/features/feedback/presentation/providers/feedback_providers.dart';
import 'package:edubridge_mobile_application/features/profiles/domain/entities/user_profile.dart';
import 'package:edubridge_mobile_application/features/profiles/presentation/providers/profile_provider.dart';
import 'package:edubridge_mobile_application/features/submissions/domain/entities/submission.dart';
import 'package:edubridge_mobile_application/features/submissions/presentation/pages/company/submission_detail_page.dart';
import 'package:edubridge_mobile_application/features/submissions/presentation/providers/submission_provider.dart';
import 'package:edubridge_mobile_application/features/notifications/presentation/providers/notification_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('company submission detail shows review and solution sections', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.utc(2025, 5, 1);
    final submission = Submission(
      id: 'submission-1',
      challengeId: 'challenge-1',
      talentId: 'talent-1',
      companyId: 'company-1',
      solutionText: 'A practical solution for the challenge.',
      attachmentUrls: const ['https://example.com/solution.pdf'],
      status: SubmissionStatus.submitted,
      isShortlisted: false,
      submittedAt: now,
      updatedAt: now,
    );
    final challenge = Challenge(
      id: 'challenge-1',
      companyId: 'company-1',
      title: 'Water access mapping',
      description: 'Map water access.',
      category: 'Technology',
      cashPrize: '500',
      requirements: const [],
      deadline: now.add(const Duration(days: 14)),
      status: ChallengeStatus.open,
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          submissionAuthStateProvider.overrideWith(
            (ref) => Stream.value(_TestUser()),
          ),
          submissionByIdProvider('submission-1')
              .overrideWith((ref) => Stream.value(submission)),
          challengeByIdProvider('challenge-1')
              .overrideWith((ref) => Stream.value(challenge)),
          profileByIdProvider('talent-1').overrideWith(
            (ref) async => const UserProfile(
              userId: 'talent-1',
              role: 'talent',
              displayName: 'Alex Talent',
            ),
          ),
          submissionFeedbackProvider('submission-1')
              .overrideWith((ref) => Stream.value(null)),
          unreadNotificationCountProvider.overrideWith((ref, userId) => 0),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const SubmissionDetailPage(submissionId: 'submission-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Water access mapping'), findsOneWidget);
    expect(find.text('Submitted by Alex Talent'), findsOneWidget);
    expect(find.text('Solution overview'), findsOneWidget);
    expect(
      find.text('A practical solution for the challenge.'),
      findsOneWidget,
    );
    expect(find.text('Submission files'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Review & Score'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Review & Score'), findsOneWidget);
    expect(find.text('Score (0-100)'), findsOneWidget);
    expect(find.text('Cash prize awarded (optional)'), findsOneWidget);
    expect(find.text('Feedback'), findsOneWidget);
    expect(find.text('Save & Notify'), findsOneWidget);
    expect(find.text('Submissions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _TestUser implements User {
  @override
  String get uid => 'company-1';

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
