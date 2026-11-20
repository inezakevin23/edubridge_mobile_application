import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/submission_model.dart';

class SubmissionAlreadyExistsException implements Exception {
  const SubmissionAlreadyExistsException();

  @override
  String toString() => 'A solution has already been submitted for this challenge.';
}

class SubmissionNotEditableException implements Exception {
  const SubmissionNotEditableException();

  @override
  String toString() => 'This submission can no longer be edited or deleted.';
}

class ChallengeUnavailableForSubmissionException implements Exception {
  const ChallengeUnavailableForSubmissionException();

  @override
  String toString() => 'This challenge is closed or its deadline has passed.';
}

class SubmissionAccessException implements Exception {
  const SubmissionAccessException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Performs the submissions feature's direct Firestore operations.
class FirestoreSubmissionDataSource {
  FirestoreSubmissionDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _submissions =>
      _firestore.collection('submissions');

  CollectionReference<Map<String, dynamic>> get _challenges =>
      _firestore.collection('challenges');

  Stream<SubmissionModel?> watchSubmissionById(String submissionId) {
    return _submissions.doc(submissionId).snapshots().map((document) {
      if (!document.exists) return null;
      return SubmissionModel.fromDocument(document);
    });
  }

  Stream<SubmissionModel?> watchSubmissionForChallengeAndTalent({
    required String challengeId,
    required String talentId,
  }) {
    return _submissions
        .where('challengeId', isEqualTo: challengeId)
        .where('talentId', isEqualTo: talentId)
        .orderBy('submittedAt', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isEmpty
            ? null
            : SubmissionModel.fromDocument(snapshot.docs.first));
  }

  Stream<List<SubmissionModel>> watchTalentSubmissions(String talentId) {
    return _submissions
        .where('talentId', isEqualTo: talentId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(SubmissionModel.fromDocument)
              .toList(growable: false),
        );
  }

  Stream<List<SubmissionModel>> watchCompanySubmissions(String companyId) {
    return _submissions
        .where('companyId', isEqualTo: companyId)
        .orderBy('submittedAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(SubmissionModel.fromDocument)
              .toList(growable: false),
        );
  }

  /// Uses a Firestore-generated document ID, matching the agreed database
  /// schema. A preflight query prevents normal duplicate submissions; for
  /// strict race-proof uniqueness, a trusted backend/Cloud Function is needed.
  Future<String> createSubmission(SubmissionModel model) async {
    final existing = await _submissions
        .where('challengeId', isEqualTo: model.challengeId)
        .where('talentId', isEqualTo: model.talentId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) {
      throw const SubmissionAlreadyExistsException();
    }

    final submissionRef = _submissions.doc();
    final challengeRef = _challenges.doc(model.challengeId);

    await _firestore.runTransaction((transaction) async {
      final challengeSnapshot = await transaction.get(challengeRef);

      if (!challengeSnapshot.exists) {
        throw const ChallengeUnavailableForSubmissionException();
      }

      final challenge = challengeSnapshot.data()!;
      final deadline = challenge['deadline'];
      final deadlineDate = deadline is Timestamp ? deadline.toDate() : null;
      final isOpen = challenge['status'] == 'open';
      final companyId = challenge['companyId'];

      if (!isOpen || deadlineDate == null || !deadlineDate.isAfter(DateTime.now())) {
        throw const ChallengeUnavailableForSubmissionException();
      }
      if (companyId != model.companyId) {
        throw const SubmissionAccessException(
          'The company on this submission does not match the challenge owner.',
        );
      }

      final data = model.toFirestore()
        ..['submittedAt'] = FieldValue.serverTimestamp()
        ..['updatedAt'] = FieldValue.serverTimestamp();
      data.remove('reviewedAt');
      transaction.set(submissionRef, data);
    });

    return submissionRef.id;
  }

  /// Talent may edit the solution only while it remains in `submitted` state
  /// and the parent challenge is still open and before its deadline.
  Future<void> updateTalentSubmission(SubmissionModel model) async {
    final submissionRef = _submissions.doc(model.id);
    final challengeRef = _challenges.doc(model.challengeId);

    await _firestore.runTransaction((transaction) async {
      final submissionSnapshot = await transaction.get(submissionRef);
      final challengeSnapshot = await transaction.get(challengeRef);

      if (!submissionSnapshot.exists) {
        throw const SubmissionAccessException('Submission not found.');
      }
      if (!challengeSnapshot.exists) {
        throw const ChallengeUnavailableForSubmissionException();
      }

      final current = submissionSnapshot.data()!;
      final challenge = challengeSnapshot.data()!;
      final deadline = challenge['deadline'];
      final deadlineDate = deadline is Timestamp ? deadline.toDate() : null;

      if (current['talentId'] != model.talentId) {
        throw const SubmissionAccessException('You do not own this submission.');
      }
      if (current['status'] != 'submitted') {
        throw const SubmissionNotEditableException();
      }
      if (challenge['status'] != 'open' ||
          deadlineDate == null ||
          !deadlineDate.isAfter(DateTime.now())) {
        throw const ChallengeUnavailableForSubmissionException();
      }

      transaction.update(submissionRef, {
        'solutionText': model.solutionText.trim(),
        'attachmentUrls': model.attachmentUrls,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Company can move a submission forward through its review lifecycle and
  /// shortlist/unshortlist it. Solution content is never changed here.
  Future<void> updateCompanyReview({
    required String submissionId,
    required String companyId,
    required String status,
    required bool isShortlisted,
  }) async {
    final submissionRef = _submissions.doc(submissionId);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(submissionRef);
      if (!snapshot.exists) {
        throw const SubmissionAccessException('Submission not found.');
      }

      final current = snapshot.data()!;
      if (current['companyId'] != companyId) {
        throw const SubmissionAccessException(
          'You can only review submissions sent to your company.',
        );
      }

      final currentStatus = current['status'];
      final canStartReview = currentStatus == 'submitted' &&
          (status == 'under_review' || status == 'reviewed');
      final canFinishReview = currentStatus == 'under_review' && status == 'reviewed';
      final canChangeShortlist = currentStatus == status &&
          (currentStatus == 'under_review' || currentStatus == 'reviewed');

      if (!(canStartReview || canFinishReview || canChangeShortlist)) {
        throw const SubmissionAccessException('This review status transition is not allowed.');
      }

      final updates = <String, dynamic>{
        'status': status,
        'isShortlisted': isShortlisted,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (status == 'reviewed' && currentStatus != 'reviewed') {
        updates['reviewedAt'] = FieldValue.serverTimestamp();
      }

      transaction.update(submissionRef, updates);
    });
  }

  Future<void> deleteSubmission({
    required String submissionId,
    required String talentId,
  }) async {
    final submissionRef = _submissions.doc(submissionId);

    await _firestore.runTransaction((transaction) async {
      final submissionSnapshot = await transaction.get(submissionRef);

      if (!submissionSnapshot.exists) return;
      final current = submissionSnapshot.data()!;

      if (current['talentId'] != talentId) {
        throw const SubmissionAccessException('You do not own this submission.');
      }
      if (current['status'] != 'submitted') {
        throw const SubmissionNotEditableException();
      }

      transaction.delete(submissionRef);
    });
  }
}
