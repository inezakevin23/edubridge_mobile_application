import 'package:flutter_test/flutter_test.dart';
import 'package:edubridge_mobile_application/features/submissions/domain/entities/submission.dart';
import 'package:edubridge_mobile_application/features/submissions/data/models/submission_model.dart';

void main() {
  group('SubmissionModel Tests - Official Schema Alignment', () {
    final testDate = DateTime(2026, 11, 12, 10, 0, 0);

    final testSubmissionModel = SubmissionModel(
      id: 'chal_456_talent_789',
      challengeId: 'chal_456',
      talentId: 'talent_789',
      companyId: 'company_101',
      challengeTitle: 'Flutter Clean Architecture Challenge',
      talentName: 'John Talent',
      talentEmail: 'john@example.com',
      solutionText: 'Implemented solution with clean architecture and Riverpod.',
      attachmentUrls: const [
        'https://github.com/john/solution',
        'https://solution-demo.web.app',
      ],
      status: 'submitted',
      isShortlisted: false,
      submittedAt: testDate,
      updatedAt: testDate,
      feedback: 'Good architecture',
      pointsAwarded: 95,
    );

    test('should be a subclass of Submission entity', () {
      expect(testSubmissionModel, isA<Submission>());
    });

    test('should generate document ID according to schema: {challengeId}_{talentId}', () {
      final generatedId = Submission.generateId('chal_456', 'talent_789');
      expect(generatedId, 'chal_456_talent_789');
    });

    test('should convert from Map matching schema fields correctly', () {
      final map = {
        'id': 'chal_456_talent_789',
        'challengeId': 'chal_456',
        'talentId': 'talent_789',
        'companyId': 'company_101',
        'solutionText': 'Implemented solution with clean architecture and Riverpod.',
        'attachmentUrls': [
          'https://github.com/john/solution',
          'https://solution-demo.web.app',
        ],
        'status': 'submitted',
        'isShortlisted': false,
        'submittedAt': testDate.toIso8601String(),
        'updatedAt': testDate.toIso8601String(),
        'feedback': 'Good architecture',
        'pointsAwarded': 95,
      };

      final result = SubmissionModel.fromMap(map);

      expect(result.id, 'chal_456_talent_789');
      expect(result.challengeId, 'chal_456');
      expect(result.talentId, 'talent_789');
      expect(result.companyId, 'company_101');
      expect(result.solutionText, 'Implemented solution with clean architecture and Riverpod.');
      expect(result.description, 'Implemented solution with clean architecture and Riverpod.');
      expect(result.githubUrl, 'https://github.com/john/solution');
      expect(result.liveDemoUrl, 'https://solution-demo.web.app');
      expect(result.status, 'submitted');
      expect(result.isShortlisted, false);
      expect(result.submittedAt, testDate);
      expect(result.pointsAwarded, 95);
      expect(result.score, 95.0);
    });

    test('should convert to JsonMap correctly', () {
      final jsonMap = testSubmissionModel.toJsonMap();

      expect(jsonMap['id'], 'chal_456_talent_789');
      expect(jsonMap['challengeId'], 'chal_456');
      expect(jsonMap['talentId'], 'talent_789');
      expect(jsonMap['companyId'], 'company_101');
      expect(jsonMap['solutionText'], 'Implemented solution with clean architecture and Riverpod.');
      expect(jsonMap['status'], 'submitted');
      expect(jsonMap['isShortlisted'], false);
      expect(jsonMap['submittedAt'], testDate.toIso8601String());
      expect(jsonMap['pointsAwarded'], 95);
    });

    test('should support copyWith correctly', () {
      final updated = testSubmissionModel.copyWith(
        status: 'reviewed',
        isShortlisted: true,
        pointsAwarded: 98,
      );

      expect(updated.status, 'reviewed');
      expect(updated.isShortlisted, true);
      expect(updated.pointsAwarded, 98);
      expect(updated.score, 98.0);
      expect(updated.id, testSubmissionModel.id);
      expect(updated.challengeId, testSubmissionModel.challengeId);
    });

    test('should create model from Entity correctly', () {
      final entity = Submission(
        id: 'chal_999_talent_999',
        challengeId: 'chal_999',
        talentId: 'talent_999',
        companyId: 'company_999',
        solutionText: 'Test Solution',
        submittedAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      final model = SubmissionModel.fromEntity(entity);

      expect(model.id, entity.id);
      expect(model.challengeId, entity.challengeId);
      expect(model.talentId, entity.talentId);
      expect(model.companyId, entity.companyId);
      expect(model.solutionText, entity.solutionText);
      expect(model.status, 'submitted');
    });
  });
}
