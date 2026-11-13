import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_mobile_application/features/submissions/domain/entities/submission.dart';
import 'package:edubridge_mobile_application/features/submissions/presentation/widgets/submission_card.dart';

void main() {
  group('SubmissionCard Widget Tests', () {
    final sampleSubmission = Submission(
      id: 'sub_001',
      challengeId: 'chal_001',
      challengeTitle: 'Mobile App Redesign',
      talentId: 'talent_001',
      talentName: 'Sarah Connor',
      talentEmail: 'sarah@example.com',
      githubUrl: 'https://github.com/sarah/app',
      liveDemoUrl: 'https://demo.app',
      description: 'Built a responsive mobile application.',
      status: 'pending',
      isShortlisted: true,
      submittedAt: DateTime(2026, 11, 10),
    );

    testWidgets('renders challenge title, status, and description', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubmissionCard(submission: sampleSubmission),
          ),
        ),
      );

      expect(find.text('Mobile App Redesign'), findsOneWidget);
      expect(find.text('Pending'), findsOneWidget);
      expect(find.text('Shortlisted'), findsOneWidget);
      expect(find.text('Built a responsive mobile application.'), findsOneWidget);
    });

    testWidgets('shows talent info when showTalentInfo is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubmissionCard(
              submission: sampleSubmission,
              showTalentInfo: true,
            ),
          ),
        ),
      );

      expect(find.text('Sarah Connor'), findsOneWidget);
      expect(find.text('(sarah@example.com)'), findsOneWidget);
    });

    testWidgets('triggers onTap callback when card is tapped', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubmissionCard(
              submission: sampleSubmission,
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(SubmissionCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });
  });
}
