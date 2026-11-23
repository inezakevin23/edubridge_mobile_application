import 'package:edubridge_mobile_application/config/theme/app_theme.dart';
import 'package:edubridge_mobile_application/features/auth/domain/entities/auth_user.dart';
import 'package:edubridge_mobile_application/features/auth/presentation/providers/auth_providers.dart';
import 'package:edubridge_mobile_application/features/challenges/domain/entities/challenge.dart';
import 'package:edubridge_mobile_application/features/challenges/presentation/providers/challenge_provider.dart';
import 'package:edubridge_mobile_application/features/dashboards/presentation/pages/talent/talent_dashboard_page.dart';
import 'package:edubridge_mobile_application/features/notifications/presentation/providers/notification_providers.dart';
import 'package:edubridge_mobile_application/features/profiles/domain/entities/user_profile.dart';
import 'package:edubridge_mobile_application/features/profiles/presentation/providers/profile_provider.dart';
import 'package:edubridge_mobile_application/features/submissions/domain/entities/submission.dart';
import 'package:edubridge_mobile_application/features/submissions/presentation/providers/submission_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('talent dashboard shows mobile stats and latest challenges', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.now();
    final challenge = Challenge(
      id: 'challenge-1',
      companyId: 'company-1',
      title: 'Open Source Contribution Platform',
      description: 'Improve an open source platform.',
      category: 'Technology & Software',
      cashPrize: '500',
      requirements: const [],
      deadline: now.add(const Duration(days: 14)),
      status: ChallengeStatus.open,
      createdAt: now,
      updatedAt: now,
    );
    final submission = Submission(
      id: 'submission-1',
      challengeId: challenge.id,
      talentId: 'talent-1',
      companyId: challenge.companyId,
      solutionText: 'A completed solution.',
      attachmentUrls: const [],
      status: SubmissionStatus.submitted,
      isShortlisted: true,
      submittedAt: now,
      updatedAt: now,
    );
    final profile = UserProfile(
      userId: 'talent-1',
      role: 'talent',
      displayName: 'Jane Awino',
      scorePoints: 92,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(
              const AuthUser(
                id: 'talent-1',
                email: 'jane@example.com',
                role: UserRole.talent,
              ),
            ),
          ),
          talentSubmissionsProvider(
            'talent-1',
          ).overrideWith((ref) => Stream.value([submission])),
          profileStreamProvider(
            'talent-1',
          ).overrideWith((ref) => Stream.value(profile)),
          openChallengesProvider.overrideWith(
            (ref) => Stream.value([challenge]),
          ),
          unreadNotificationCountProvider.overrideWith(
            (ref, userId) => 0,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const TalentDashboardPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Latest Challenges'), findsOneWidget);
    expect(find.text('Open Source Contribution Platform'), findsOneWidget);
    expect(find.text('My Submissions'), findsOneWidget);
    expect(find.text('92 pts'), findsOneWidget);
    expect(find.text('Feedback'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
