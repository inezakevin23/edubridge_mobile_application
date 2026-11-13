import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/submission.dart';
import '../models/submission_model.dart';

abstract class SubmissionDataSource {
  Future<void> submitSolution(SubmissionModel submission);
  Stream<List<SubmissionModel>> getSubmissionsByChallenge(String challengeId);
  Stream<List<SubmissionModel>> getSubmissionsByTalent(String talentId);
  Stream<List<SubmissionModel>> getSubmissionsByCompany(String companyId);
  Future<SubmissionModel?> getSubmissionById(String submissionId);
  Future<void> updateSubmission(SubmissionModel submission);
  Future<void> updateSubmissionStatus(
    String submissionId,
    String status, {
    bool? isShortlisted,
    DateTime? reviewedAt,
  });
  Future<void> deleteSubmission(String submissionId);
}

class FirestoreSubmissionDataSource implements SubmissionDataSource {
  final FirebaseFirestore _firestore;
  static const String collection = 'submissions';

  FirestoreSubmissionDataSource({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> submitSolution(SubmissionModel submission) async {
    // Generate deterministic document ID: {challengeId}_{talentId}
    final docId = submission.id.isNotEmpty
        ? submission.id
        : Submission.generateId(submission.challengeId, submission.talentId);

    final docRef = _firestore.collection(collection).doc(docId);

    final toSave = SubmissionModel(
      id: docId,
      challengeId: submission.challengeId,
      talentId: submission.talentId,
      companyId: submission.companyId,
      solutionText: submission.solutionText,
      attachmentUrls: submission.attachmentUrls,
      status: submission.status,
      isShortlisted: submission.isShortlisted,
      submittedAt: submission.submittedAt,
      updatedAt: DateTime.now(),
      reviewedAt: submission.reviewedAt,
      challengeTitle: submission.challengeTitle,
      talentName: submission.talentName,
      talentEmail: submission.talentEmail,
      feedback: submission.feedback,
      pointsAwarded: submission.pointsAwarded,
    );

    await docRef.set(toSave.toFirestoreMap(), SetOptions(merge: true));
  }

  @override
  Stream<List<SubmissionModel>> getSubmissionsByChallenge(String challengeId) {
    return _firestore
        .collection(collection)
        .where('challengeId', isEqualTo: challengeId)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => SubmissionModel.fromFirestore(doc))
          .toList();
      items.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return items;
    });
  }

  @override
  Stream<List<SubmissionModel>> getSubmissionsByTalent(String talentId) {
    return _firestore
        .collection(collection)
        .where('talentId', isEqualTo: talentId)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => SubmissionModel.fromFirestore(doc))
          .toList();
      items.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return items;
    });
  }

  @override
  Stream<List<SubmissionModel>> getSubmissionsByCompany(String companyId) {
    return _firestore
        .collection(collection)
        .where('companyId', isEqualTo: companyId)
        .snapshots()
        .map((snapshot) {
      final items = snapshot.docs
          .map((doc) => SubmissionModel.fromFirestore(doc))
          .toList();
      items.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return items;
    });
  }

  @override
  Future<SubmissionModel?> getSubmissionById(String submissionId) async {
    final doc = await _firestore.collection(collection).doc(submissionId).get();
    if (!doc.exists) return null;
    return SubmissionModel.fromFirestore(doc);
  }

  @override
  Future<void> updateSubmission(SubmissionModel submission) async {
    await _firestore
        .collection(collection)
        .doc(submission.id)
        .update(submission.toFirestoreMap());
  }

  @override
  Future<void> updateSubmissionStatus(
    String submissionId,
    String status, {
    bool? isShortlisted,
    DateTime? reviewedAt,
  }) async {
    final Map<String, dynamic> updates = {
      'status': status,
      'updatedAt': Timestamp.now(),
    };

    if (isShortlisted != null) {
      updates['isShortlisted'] = isShortlisted;
    }
    if (reviewedAt != null) {
      updates['reviewedAt'] = Timestamp.fromDate(reviewedAt);
    } else if (status == 'reviewed') {
      updates['reviewedAt'] = Timestamp.now();
    }

    await _firestore.collection(collection).doc(submissionId).update(updates);
  }

  @override
  Future<void> deleteSubmission(String submissionId) async {
    await _firestore.collection(collection).doc(submissionId).delete();
  }
}
