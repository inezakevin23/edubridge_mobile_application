import 'package:edubridge_mobile_application/config/theme/app_theme.dart';
import 'package:edubridge_mobile_application/features/challenges/domain/entities/challenge.dart';
import 'package:edubridge_mobile_application/features/challenges/presentation/providers/challenge_provider.dart';
import 'package:edubridge_mobile_application/features/profiles/domain/entities/user_profile.dart';
import 'package:edubridge_mobile_application/features/profiles/presentation/providers/profile_provider.dart';
import 'package:edubridge_mobile_application/features/submissions/presentation/pages/talent/talent_solution_page.dart';
import 'package:edubridge_mobile_application/features/submissions/presentation/providers/submission_provider.dart';
import 'package:edubridge_mobile_application/features/notifications/presentation/providers/notification_providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('solution submission matches the compact mobile flow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final actions = _FakeSubmissionActions();
    final challenge = Challenge(
      id: 'challenge-1',
      companyId: 'company-1',
      title: 'Open Source Contribution Platform',
      shortDescription: 'Create a platform connecting African developers.',
      description: 'Create a platform connecting African developers.',
      category: 'Technology',
      submissionFormats: const [
        'Written Report',
        'Code Repository',
        'Slide Deck',
      ],
      requirements: const ['Submit a working solution'],
      deadline: DateTime.now().add(const Duration(days: 14)),
      status: ChallengeStatus.open,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          submissionAuthStateProvider.overrideWith(
            (ref) => Stream.value(_TalentUser()),
          ),
          challengeByIdProvider('challenge-1')
              .overrideWith((ref) => Stream.value(challenge)),
          submissionForChallengeProvider(
            const SubmissionLookup(
              challengeId: 'challenge-1',
              talentId: 'talent-1',
            ),
          ).overrideWith((ref) => Stream.value(null)),
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
                displayName: 'EduBridge Africa',
              ),
            ),
          ),
          submissionActionsProvider.overrideWith(() => actions),
          unreadNotificationCountProvider.overrideWith((ref, userId) => 0),
        ],
        child: MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) => Scaffold(
              body: Column(
                children: [
                  const Text('Challenge detail screen'),
                  Expanded(
                    child: Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const TalentSolutionPage(
                              challengeId: 'challenge-1',
                            ),
                          ),
                        ),
                        child: const Text('Open solution form'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open solution form'));
    await tester.pumpAndSettle();

    final scrollable = find.byType(Scrollable).first;
    expect(find.text('Submission Checklist'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Solution Overview'),
      200,
      scrollable: scrollable,
    );
    expect(find.text('Solution Overview'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Upload Deliverables'),
      200,
      scrollable: scrollable,
    );
    expect(find.text('Upload Deliverables'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Code Repository'),
      200,
      scrollable: scrollable,
    );
    expect(find.text('Written Report'), findsOneWidget);
    expect(find.text('Code Repository'), findsOneWidget);
    expect(find.text('Presentation Deck'), findsOneWidget);
    expect(find.text('Challenges'), findsWidgets);
    expect(find.byKey(const ValueKey('submit_solution')), findsOneWidget);
    expect(tester.takeException(), isNull);

    final titleField = find.byKey(const ValueKey('solution_title'));
    await tester.scrollUntilVisible(titleField, 200, scrollable: scrollable);
    await tester.enterText(titleField, 'Route planning solution');
    final summaryField = find.byKey(const ValueKey('solution_summary'));
    await tester.scrollUntilVisible(summaryField, 200, scrollable: scrollable);
    await tester.enterText(
      summaryField,
      'I analyzed travel patterns and grouped them by distance to improve route efficiency.',
    );
    final reportField = find.byKey(
      const ValueKey('deliverable_Written Report'),
    );
    await tester.scrollUntilVisible(reportField, 200, scrollable: scrollable);
    await tester.enterText(reportField, 'https://example.com/report.pdf');
    final repositoryField = find.byKey(
      const ValueKey('deliverable_Code Repository'),
    );
    await tester.scrollUntilVisible(
      repositoryField,
      200,
      scrollable: scrollable,
    );
    await tester.enterText(
      repositoryField,
      'https://github.com/example/project',
    );
    final deckField = find.byKey(const ValueKey('deliverable_Slide Deck'));
    await tester.scrollUntilVisible(deckField, 200, scrollable: scrollable);
    await tester.enterText(deckField, 'https://example.com/slides.pdf');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('submit_solution')));
    await tester.pumpAndSettle();

    expect(
      actions.savedSolutionText,
      'Route planning solution\n\n'
      'I analyzed travel patterns and grouped them by distance to improve route efficiency.',
    );
    expect(actions.savedAttachmentUrls, [
      'https://example.com/report.pdf',
      'https://github.com/example/project',
      'https://example.com/slides.pdf',
    ]);
    expect(find.text('Challenge detail screen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _TalentUser implements User {
  @override
  String get uid => 'talent-1';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSubmissionActions extends SubmissionActions {
  String? savedSolutionText;
  List<String>? savedAttachmentUrls;

  @override
  Future<String> submitSolution({
    required String challengeId,
    required String talentId,
    required String companyId,
    required String solutionText,
    required List<String> attachmentUrls,
  }) async {
    savedSolutionText = solutionText;
    savedAttachmentUrls = attachmentUrls;
    return 'submission-1';
  }
}
