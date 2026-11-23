import 'package:edubridge_mobile_application/features/auth/domain/entities/auth_user.dart';
import 'package:edubridge_mobile_application/features/auth/presentation/providers/auth_providers.dart';
import 'package:edubridge_mobile_application/features/challenges/domain/entities/challenge.dart';
import 'package:edubridge_mobile_application/features/challenges/presentation/providers/challenge_provider.dart';
import 'package:edubridge_mobile_application/features/profiles/domain/entities/user_profile.dart';
import 'package:edubridge_mobile_application/features/profiles/presentation/pages/company_talent_profile_page.dart';
import 'package:edubridge_mobile_application/features/profiles/presentation/providers/profile_provider.dart';
import 'package:edubridge_mobile_application/features/dashboards/presentation/pages/company_dashboard_page.dart';
import 'package:edubridge_mobile_application/features/notifications/presentation/providers/notification_providers.dart';
import 'package:edubridge_mobile_application/features/submissions/domain/entities/submission.dart';
import 'package:edubridge_mobile_application/features/submissions/presentation/providers/submission_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('company can view a shortlisted talent profile', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final now = DateTime.utc(2026, 11, 22);
    final profile = UserProfile(
      userId: 'talent-1',
      role: 'talent',
      displayName: 'Alex Njeri',
      headline: 'Junior software engineer',
      bio: 'A practical builder interested in accessible education.',
      location: 'Nairobi, Kenya',
      scorePoints: 42,
      registrationDetails: {
        'phone': '0700000000',
        'institution': 'University of Nairobi',
        'fieldOfStudy': 'Computer Science',
        'graduationYear': '2027',
        'currentStatus': 'Student',
        'yearsOfExperience': '1',
        'skills': ['Flutter', 'Dart'],
      },
    );
    final shortlistedSubmission = Submission(
      id: 'submission-1',
      challengeId: 'challenge-1',
      talentId: 'talent-1',
      companyId: 'company-1',
      solutionText: 'A complete solution.',
      attachmentUrls: const [],
      status: SubmissionStatus.reviewed,
      isShortlisted: true,
      submittedAt: now,
      updatedAt: now,
      reviewedAt: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(
              const AuthUser(
                id: 'company-1',
                email: 'company@example.com',
                role: UserRole.company,
              ),
            ),
          ),
          companySubmissionsProvider('company-1')
              .overrideWith((ref) => Stream.value([shortlistedSubmission])),
          profileByIdProvider('talent-1').overrideWith((ref) async => profile),
          unreadNotificationCountProvider.overrideWith((ref, userId) => 0),
        ],
        child: const MaterialApp(
          home: CompanyTalentProfilePage(talentId: 'talent-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Alex Njeri'), findsOneWidget);
    expect(find.text('SHORTLISTED TALENT'), findsOneWidget);
    expect(
      find.text('A practical builder interested in accessible education.'),
      findsOneWidget,
    );
    expect(find.text('University of Nairobi'), findsOneWidget);
    expect(find.text('Computer Science'), findsOneWidget);
    expect(find.text('Flutter'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('42'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('42'), findsOneWidget);
    expect(find.text('EduBridge'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('shortlisted dashboard row opens the talent profile', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 11, 22);
    final submission = Submission(
      id: 'submission-1',
      challengeId: 'challenge-1',
      talentId: 'talent-1',
      companyId: 'company-1',
      solutionText: 'A complete solution.',
      attachmentUrls: const [],
      status: SubmissionStatus.reviewed,
      isShortlisted: true,
      submittedAt: now,
      updatedAt: now,
      reviewedAt: now,
    );
    const profile = UserProfile(
      userId: 'talent-1',
      role: 'talent',
      displayName: 'Alex Njeri',
      bio: 'A dedicated student.',
    );
    final router = GoRouter(
      initialLocation: '/company/dashboard',
      routes: [
        GoRoute(
          path: '/company/dashboard',
          builder: (context, state) =>
              const CompanyDashboardPage(companyId: 'company-1'),
        ),
        GoRoute(
          path: '/company/talent/:talentId',
          builder: (context, state) => CompanyTalentProfilePage(
            talentId: state.pathParameters['talentId']!,
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(
            (ref) => Stream.value(
              const AuthUser(
                id: 'company-1',
                email: 'company@example.com',
                role: UserRole.company,
              ),
            ),
          ),
          companySubmissionsProvider('company-1')
              .overrideWith((ref) => Stream.value([submission])),
          companyChallengesProvider('company-1')
              .overrideWith((ref) => Stream.value(const <Challenge>[])),
          profileByIdProvider('talent-1').overrideWith((ref) async => profile),
          unreadNotificationCountProvider.overrideWith((ref, userId) => 0),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Shortlisted Submissions'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Shortlisted Submissions'), findsOneWidget);
    expect(find.text('Alex Njeri'), findsOneWidget);
    await tester.tap(find.text('Alex Njeri'));
    await tester.pumpAndSettle();

    expect(find.text('SHORTLISTED TALENT'), findsOneWidget);
    expect(find.text('A dedicated student.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
