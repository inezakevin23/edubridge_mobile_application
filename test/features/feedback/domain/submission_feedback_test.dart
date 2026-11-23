import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_mobile_application/features/feedback/domain/entities/submission_feedback.dart';
import 'package:edubridge_mobile_application/features/feedback/domain/repositories/feedback_repository.dart';
import 'package:edubridge_mobile_application/features/feedback/domain/usecases/save_submission_feedback.dart';

void main() {
  group('SubmissionFeedback validation', () {
    test('accepts valid feedback', () {
      final feedback = _validFeedback();

      expect(feedback.validate(), isNull);
    });

    test('rejects a rating outside 1 to 5', () {
      final feedback = _validFeedback(rating: 6);

      expect(feedback.validate(), 'Rating must be between 1 and 5.');
    });

    test('rejects points outside 0 to 100', () {
      final feedback = _validFeedback(pointsAwarded: 101);

      expect(feedback.validate(), 'Points must be between 0 and 100.');
    });

    test('rejects a negative cash prize', () {
      final feedback = _validFeedback(cashPrizeAwarded: -1);

      expect(feedback.validate(), 'Cash prize must be a non-negative amount.');
    });

    test('requires meaningful overall feedback', () {
      final feedback = _validFeedback(summary: 'Good');

      expect(
        feedback.validate(),
        'Overall feedback must contain at least 10 characters.',
      );
    });
  });

  group('SaveSubmissionFeedback', () {
    test('does not call repository when validation fails', () async {
      final repository = _FakeFeedbackRepository();
      final useCase = SaveSubmissionFeedback(repository);

      await expectLater(
        () => useCase(_validFeedback(rating: 0)),
        throwsA(isA<ArgumentError>()),
      );
      expect(repository.saveCalled, isFalse);
    });
  });
}

SubmissionFeedback _validFeedback({
  int rating = 4,
  int pointsAwarded = 75,
  double cashPrizeAwarded = 0,
  String summary = 'A clear and thoughtful solution.',
}) {
  return SubmissionFeedback(
    submissionId: 'submission-1',
    challengeId: 'challenge-1',
    talentId: 'talent-1',
    companyId: 'company-1',
    rating: rating,
    pointsAwarded: pointsAwarded,
    summary: summary,
    strengths: 'Good analysis.',
    areasForImprovement: 'Add more testing.',
    cashPrizeAwarded: cashPrizeAwarded,
  );
}

class _FakeFeedbackRepository implements FeedbackRepository {
  bool saveCalled = false;

  @override
  Future<SubmissionFeedback?> getForSubmission(String submissionId) async =>
      null;

  @override
  Future<void> save(SubmissionFeedback feedback) async {
    saveCalled = true;
  }

  @override
  Stream<SubmissionFeedback?> watchForSubmission(String submissionId) =>
      const Stream.empty();
}
