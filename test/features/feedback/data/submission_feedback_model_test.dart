import 'package:edubridge_mobile_application/features/feedback/data/models/submission_feedback_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('serializes the optional cash prize awarded amount', () {
    const feedback = SubmissionFeedbackModel(
      submissionId: 'submission-1',
      challengeId: 'challenge-1',
      talentId: 'talent-1',
      companyId: 'company-1',
      rating: 4,
      pointsAwarded: 80,
      summary: 'A clear and thoughtful solution.',
      strengths: '',
      areasForImprovement: '',
      cashPrizeAwarded: 250.5,
    );

    expect(feedback.toFirestore()['cashPrizeAwarded'], 250.5);
  });
}
