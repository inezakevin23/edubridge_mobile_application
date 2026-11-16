import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edubridge_mobile_application/features/submissions/domain/entities/submission.dart';
import 'package:edubridge_mobile_application/features/submissions/presentation/widgets/submission_card.dart';

void main() {
  testWidgets('shows challenge title, status and shortlist state', (tester) async {
    final submission = Submission(
      id: 'challenge1_talent1',
      challengeId: 'challenge1',
      talentId: 'talent1',
      companyId: 'company1',
      solutionText: 'A detailed solution for the challenge.',
      attachmentUrls: const [],
      status: SubmissionStatus.reviewed,
      isShortlisted: true,
      submittedAt: DateTime(2026, 11, 10),
      updatedAt: DateTime(2026, 11, 11),
    );

    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SubmissionCard(
            submission: submission,
            challengeTitle: 'Improve customer feedback',
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Improve customer feedback'), findsOneWidget);
    expect(find.text('Reviewed'), findsOneWidget);
    expect(find.text('Shortlisted'), findsOneWidget);

    await tester.tap(find.byType(SubmissionCard));
    expect(tapped, isTrue);
  });
}
