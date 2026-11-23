import 'package:edubridge_mobile_application/features/challenges/domain/entities/challenge.dart';
import 'package:edubridge_mobile_application/features/challenges/presentation/providers/challenge_provider.dart';
import 'package:edubridge_mobile_application/features/notifications/presentation/providers/notification_providers.dart';
import 'package:edubridge_mobile_application/features/profiles/presentation/providers/profile_provider.dart';
import 'package:edubridge_mobile_application/features/submissions/domain/entities/submission.dart';
import 'package:edubridge_mobile_application/features/submissions/presentation/pages/company/company_submissions_page.dart';
import 'package:edubridge_mobile_application/features/submissions/presentation/providers/submission_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('company submissions page paginates two cards at a time', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(290, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final submissions = List.generate(
      3,
      (index) => Submission(
        id: 'submission-$index',
        challengeId: 'challenge-$index',
        talentId: 'talent-$index',
        companyId: 'company',
        solutionText: 'Solution $index',
        attachmentUrls: const [],
        status: SubmissionStatus.submitted,
        isShortlisted: index == 0,
        submittedAt: DateTime(2026, 11, 10 + index),
        updatedAt: DateTime(2026, 11, 10 + index),
      ),
    );
    final challenges = List.generate(
      3,
      (index) => Challenge(
        id: 'challenge-$index',
        companyId: 'company',
        title: 'Challenge $index',
        description: 'Challenge description',
        category: 'Technology',
        requirements: const [],
        deadline: DateTime(2026, 12, 1),
        status: ChallengeStatus.open,
        createdAt: DateTime(2026, 11, 1),
        updatedAt: DateTime(2026, 11, 1),
      ),
    );
    var notifiedCount = 0;
    final router = GoRouter(
      initialLocation: '/company/submissions',
      routes: [
        GoRoute(
          path: '/company/submissions',
          builder: (context, state) => const CompanySubmissionsPage(),
        ),
        GoRoute(
          path: '/company/challenges/create',
          builder: (context, state) =>
              const Scaffold(body: Text('Create challenge route')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          submissionAuthStateProvider.overrideWith(
            (ref) => Stream.value(_CompanyUser()),
          ),
          companySubmissionsProvider.overrideWith(
            (ref, companyId) => Stream.value(submissions),
          ),
          companyChallengesProvider.overrideWith(
            (ref, companyId) => Stream.value(challenges),
          ),
          profileByIdProvider.overrideWith((ref, userId) async => null),
          unreadNotificationCountProvider.overrideWith((ref, userId) => 0),
          notifyShortlistedSubmissionsProvider.overrideWith(
            (ref) => ({required companyId, required submissions}) async {
              expect(companyId, 'company');
              notifiedCount = submissions.length;
              return notifiedCount;
            },
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Review Submissions'), findsOneWidget);
    expect(find.text('Total Submissions'), findsOneWidget);
    expect(find.text('3'), findsNWidgets(2));
    expect(find.text('Challenge 0'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Page'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    final nextPage = find.text('›');
    await tester.tap(nextPage);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(TextButton, '2'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Challenge 0'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Challenge 0'), findsOneWidget);
    expect(find.text('Page'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.scrollUntilVisible(
      find.text('Notify Shortlisted'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.text('Notify Shortlisted')),
      alignment: 0.1,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notify Shortlisted'));
    await tester.pumpAndSettle();
    expect(find.text('Review Submissions'), findsOneWidget);
    expect(find.text('Give feedback'), findsNothing);
    expect(notifiedCount, 1);
    expect(find.text('Shortlist notification sent.'), findsOneWidget);

    await tester.tap(find.text('Post Challenge'));
    await tester.pumpAndSettle();
    expect(find.text('Create challenge route'), findsOneWidget);
  });
}

class _CompanyUser implements User {
  @override
  String get uid => 'company';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
