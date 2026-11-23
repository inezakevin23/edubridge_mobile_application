import 'dart:async';

import 'package:edubridge_mobile_application/config/theme/app_theme.dart';
import 'package:edubridge_mobile_application/features/challenges/domain/entities/challenge.dart';
import 'package:edubridge_mobile_application/features/challenges/presentation/pages/company/create_challenge_page.dart';
import 'package:edubridge_mobile_application/features/challenges/presentation/pages/company/manage_challenges_page.dart';
import 'package:edubridge_mobile_application/features/challenges/presentation/pages/talent/challenge_detail_page.dart';
import 'package:edubridge_mobile_application/features/challenges/presentation/pages/talent/challenges_page.dart';
import 'package:edubridge_mobile_application/features/challenges/presentation/providers/challenge_provider.dart';
import 'package:edubridge_mobile_application/features/auth/presentation/providers/auth_providers.dart';
import 'package:edubridge_mobile_application/features/auth/domain/entities/auth_user.dart';
import 'package:edubridge_mobile_application/features/notifications/presentation/providers/notification_providers.dart';
import 'package:edubridge_mobile_application/features/profiles/presentation/providers/profile_provider.dart';
import 'package:edubridge_mobile_application/features/profiles/domain/entities/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

final _challenges = [
  Challenge(
    id: 'garden',
    companyId: 'company-1',
    title: 'Urban Garden Helper',
    shortDescription: 'Plan an accessible community garden.',
    description: 'Design an accessible tool for community garden planning.',
    category: 'Technology',
    estimatedDuration: '2-3 weeks',
    requiredSkills: const ['Flutter', 'Accessible design'],
    requirements: const ['Submit a practical garden plan'],
    eligibility: 'Open to all students',
    reward: 'Mentorship and a certificate',
    deadline: DateTime.now().add(const Duration(days: 14)),
    status: ChallengeStatus.open,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  Challenge(
    id: 'cleanup',
    companyId: 'company-2',
    title: 'Campus Cleanup Campaign',
    description: 'Create a campaign to encourage recycling on campus.',
    category: 'Design',
    requirements: const ['Visual communication'],
    deadline: DateTime.now().add(const Duration(days: 21)),
    status: ChallengeStatus.open,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
];

Widget _browsePage() => ProviderScope(
  overrides: [
    openChallengesProvider.overrideWith((ref) => Stream.value(_challenges)),
    authStateProvider.overrideWith((ref) => Stream.value(null)),
    profileStreamProvider('company-1').overrideWith(
      (ref) => Stream.value(
        const UserProfile(
          userId: 'company-1',
          role: 'company',
          displayName: 'EduBridge Labs Africa',
        ),
      ),
    ),
    profileStreamProvider('company-2').overrideWith(
      (ref) => Stream.value(
        const UserProfile(
          userId: 'company-2',
          role: 'company',
          displayName: 'Campus Partners',
        ),
      ),
    ),
  ],
  child: MaterialApp(theme: AppTheme.dark, home: const ChallengesPage()),
);

void main() {
  testWidgets('company challenge navigation fits a narrow mobile screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          openChallengesProvider.overrideWith(
            (ref) => Stream.value(_challenges),
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
          profileStreamProvider('company-2').overrideWith(
            (ref) => Stream.value(
              const UserProfile(
                userId: 'company-2',
                role: 'company',
                displayName: 'Campus Partners',
              ),
            ),
          ),
          authStateProvider.overrideWith(
            (ref) => Stream.value(
              const AuthUser(
                id: 'company-1',
                email: 'company@example.com',
                role: UserRole.company,
                emailVerified: true,
              ),
            ),
          ),
          unreadNotificationCountProvider.overrideWith(
            (ref, userId) => 0,
          ),
        ],
        child: MaterialApp(theme: AppTheme.dark, home: const ChallengesPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Browse Challenges'), findsOneWidget);
    expect(find.text('Active filters: None'), findsOneWidget);
    expect(find.text('EduBridge Labs Africa'), findsOneWidget);
    expect(find.text('View Challenge'), findsWidgets);
    expect(find.text('Manage'), findsOneWidget);
    expect(find.text('Submissions'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('company manage screen keeps the bottom navigation on mobile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          companyChallengesProvider('company-1')
              .overrideWith((ref) => Stream.value(_challenges)),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const ManageChallengesPage(companyId: 'company-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Manage challenges'), findsOneWidget);
    expect(find.text('Manage'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('company create form matches the compact mobile challenge flow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unreadNotificationCountProvider.overrideWith(
            (ref, userId) => 0,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const CreateChallengePage(companyId: 'company-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Create a Challenge'), findsOneWidget);
    expect(find.text('Basic\nInformation'), findsOneWidget);
    expect(find.text('Requirements &\nDeliverables'), findsOneWidget);
    expect(find.text('Rewards &\nAccess'), findsOneWidget);
    expect(find.text('Review &\nPublish'), findsOneWidget);
    expect(find.text('Manage'), findsOneWidget);
    expect(find.text('Basic Information'), findsOneWidget);
    expect(find.text('Challenge Title'), findsOneWidget);
    expect(find.text('Category'), findsOneWidget);
    expect(find.text('Difficulty Level'), findsOneWidget);
    expect(find.text('Required Skills'), findsOneWidget);
    expect(find.text('Estimated Duration'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Requirements & Deliverables'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Requirements & Deliverables'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Accepted Submission Formats'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Accepted Submission Formats'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Open Challenge'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Rewards & Access Control'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('Submission Deadline'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.scrollUntilVisible(
      find.text('Review & Publish'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Review & Publish'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Preview'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Save as draft'), findsOneWidget);
    expect(find.byKey(const ValueKey('challenge_publish')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'challenge preview and draft save work and return to management',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final actions = _FakeChallengeActions();
      final router = GoRouter(
        initialLocation: '/company/challenges/create',
        routes: [
          GoRoute(
            path: '/company/challenges/create',
            builder: (context, state) =>
                const CreateChallengePage(companyId: 'company-1'),
          ),
          GoRoute(
            path: '/company/challenges/manage',
            builder: (context, state) =>
                const Scaffold(body: Text('Manage challenges page')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            challengeActionsProvider.overrideWith(() => actions),
            unreadNotificationCountProvider.overrideWith(
              (ref, userId) => 0,
            ),
          ],
          child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Review &\nPublish'));
      await tester.pumpAndSettle();
      final previewButton = find.byKey(const ValueKey('challenge_preview'));
      await tester.ensureVisible(previewButton);
      await tester.pumpAndSettle();
      await tester.tap(previewButton);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Access'), findsOneWidget);
      expect(find.text('Close preview'), findsOneWidget);
      await tester.tap(find.text('Close preview'));
      await tester.pumpAndSettle();

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, 10000),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Test challenge',
      );
      final categoryField = find.byType(TextFormField).at(3);
      await tester.ensureVisible(categoryField);
      await tester.enterText(categoryField, 'Technology');
      await tester.pump();

      await tester.drag(
        find.byType(SingleChildScrollView).first,
        const Offset(0, -10000),
      );
      await tester.pumpAndSettle();
      final saveDraftButton = find.byKey(
        const ValueKey('challenge_save_draft'),
      );
      await tester.ensureVisible(saveDraftButton);
      await tester.pumpAndSettle();
      await tester.tap(saveDraftButton);
      await tester.pumpAndSettle();

      expect(actions.savedStatus, ChallengeStatus.draft);
      expect(find.text('Manage challenges page'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('browse search and category filters narrow challenge cards', (
    tester,
  ) async {
    await tester.pumpWidget(_browsePage());
    await tester.pumpAndSettle();

    expect(find.text('Showing 2 of 2 challenges'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'flutter');
    await tester.pumpAndSettle();

    expect(find.text('Urban Garden Helper'), findsOneWidget);
    expect(find.text('Campus Cleanup Campaign'), findsNothing);

    await tester.tap(find.byTooltip('Clear search'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(ChoiceChip, 'Design'));
    await tester.pumpAndSettle();

    expect(find.text('Urban Garden Helper'), findsNothing);
    await tester.drag(find.byType(ListView).first, const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Campus Cleanup Campaign'), findsOneWidget);
  });

  testWidgets('challenge details keep the solution action available', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          challengeByIdProvider('garden')
              .overrideWith((ref) => Stream.value(_challenges.first)),
          authStateProvider.overrideWith(
            (ref) => Stream.value(
              const AuthUser(
                id: 'talent-1',
                email: 'talent@example.com',
                role: UserRole.talent,
                emailVerified: true,
              ),
            ),
          ),
          unreadNotificationCountProvider.overrideWith(
            (ref, userId) => 0,
          ),
          profileStreamProvider('talent-1').overrideWith(
            (ref) => Stream.value(
              const UserProfile(
                userId: 'talent-1',
                role: 'talent',
                displayName: 'Ama Mensah',
                scorePoints: 1790,
              ),
            ),
          ),
          profileStreamProvider('company-1').overrideWith(
            (ref) => Stream.value(
              const UserProfile(
                userId: 'company-1',
                role: 'company',
                displayName: 'EduBridge Labs Africa',
                industry: 'Technology',
                companyDescription:
                    'Building tools for African developers and innovators.',
              ),
            ),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: const ChallengeDetailPage(challengeId: 'garden'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Urban Garden Helper'), findsOneWidget);
    expect(find.text('Ready to Compete?'), findsOneWidget);
    expect(find.text('Submit a Solution'), findsOneWidget);
    expect(find.text('Challenges'), findsWidgets);
    await tester.scrollUntilVisible(
      find.text('Challenge Description'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Challenge Description'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Requirements'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Requirements'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('About the Company'),
      240,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('About the Company'), findsOneWidget);
    expect(find.text('EduBridge Labs Africa'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeChallengeActions extends ChallengeActions {
  ChallengeStatus? savedStatus;

  @override
  Future<void> build() async {}

  @override
  Future<String> createChallenge({
    required String companyId,
    required String title,
    String shortDescription = '',
    required String description,
    required String category,
    String estimatedDuration = '',
    List<String> requiredSkills = const [],
    String difficulty = '',
    List<String> submissionFormats = const [],
    int maxTeamSize = 1,
    String participantStatus = '',
    String accessType = 'open',
    String cashPrize = '',
    required List<String> requirements,
    String eligibility = '',
    String reward = '',
    required DateTime deadline,
    ChallengeStatus status = ChallengeStatus.open,
  }) async {
    savedStatus = status;
    return 'new-challenge';
  }
}
