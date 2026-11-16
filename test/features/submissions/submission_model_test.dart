import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:edubridge_mobile_application/features/submissions/data/models/submission_model.dart';
import 'package:edubridge_mobile_application/features/submissions/domain/entities/submission.dart';

void main() {
  final submittedAt = DateTime.utc(2026, 11, 10, 9);
  final updatedAt = DateTime.utc(2026, 11, 10, 10);

  group('SubmissionModel', () {
    test('parses a Firestore map into a model and domain entity', () {
      final model = SubmissionModel.fromMap('firestoreGeneratedId123', {
        'challengeId': 'challengeA',
        'talentId': 'talentB',
        'companyId': 'companyC',
        'solutionText': 'A proposed practical solution for the problem.',
        'attachmentUrls': ['https://example.com/demo'],
        'status': 'under_review',
        'isShortlisted': false,
        'submittedAt': Timestamp.fromDate(submittedAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      });

      final submission = model.toEntity();

      expect(submission.id, 'firestoreGeneratedId123');
      expect(submission.challengeId, 'challengeA');
      expect(submission.talentId, 'talentB');
      expect(submission.companyId, 'companyC');
      expect(submission.status, SubmissionStatus.underReview);
      expect(submission.attachmentUrls, ['https://example.com/demo']);
      expect(submission.submittedAt, submittedAt);
      expect(submission.reviewedAt, isNull);
    });

    test('supports optional attachment links and reviewedAt', () {
      final model = SubmissionModel.fromMap('submission1', {
        'challengeId': 'challenge1',
        'talentId': 'talent1',
        'companyId': 'company1',
        'solutionText': 'A sufficiently detailed solution.',
        'status': 'reviewed',
        'isShortlisted': true,
        'submittedAt': Timestamp.fromDate(submittedAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'reviewedAt': Timestamp.fromDate(updatedAt),
      });

      expect(model.attachmentUrls, isEmpty);
      expect(model.reviewedAt, updatedAt);
      expect(model.toEntity().isShortlisted, isTrue);
    });

    test('rejects unsupported status values', () {
      expect(
        () => SubmissionStatusX.fromValue('accepted'),
        throwsFormatException,
      );
    });

    test('uses the Firestore document ID supplied by the snapshot', () {
      final model = SubmissionModel.fromMap('firestoreGeneratedId123', {
        'challengeId': 'challenge123',
        'talentId': 'talent456',
        'companyId': 'company789',
        'solutionText': 'A detailed solution for the test challenge.',
        'attachmentUrls': <String>[],
        'status': 'submitted',
        'isShortlisted': false,
        'submittedAt': Timestamp.fromDate(submittedAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      });

      expect(model.id, 'firestoreGeneratedId123');
    });

    test('serializes a domain entity without Firebase types in the entity', () {
      final entity = Submission(
        id: 'firestoreGeneratedId123',
        challengeId: 'challengeA',
        talentId: 'talentB',
        companyId: 'companyC',
        solutionText: '  My solution is detailed enough.  ',
        attachmentUrls: const [],
        status: SubmissionStatus.submitted,
        isShortlisted: false,
        submittedAt: submittedAt,
        updatedAt: updatedAt,
      );

      final map = SubmissionModel.fromEntity(entity).toFirestore();

      expect(map['solutionText'], 'My solution is detailed enough.');
      expect(map['status'], 'submitted');
      expect(map['submittedAt'], isA<Timestamp>());
      expect(map['attachmentUrls'], isEmpty);
    });
  });
}
