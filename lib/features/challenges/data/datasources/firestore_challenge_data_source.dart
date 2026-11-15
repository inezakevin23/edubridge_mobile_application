import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/challenge_model.dart';

class ChallengeHasSubmissionsException implements Exception {
  const ChallengeHasSubmissionsException();

  @override
  String toString() =>
      'This challenge already has submissions. Close it instead of deleting it.';
}

/// Performs direct Firestore operations for the challenges feature.
class FirestoreChallengeDataSource {
  FirestoreChallengeDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _challenges =>
      _firestore.collection('challenges');

  Stream<List<ChallengeModel>> watchOpenChallenges() {
    return _challenges
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(ChallengeModel.fromDocument)
              .toList(growable: false),
        );
  }

  Stream<ChallengeModel?> watchChallengeById(String challengeId) {
    return _challenges.doc(challengeId).snapshots().map((document) {
      if (!document.exists) return null;
      return ChallengeModel.fromDocument(document);
    });
  }

  Stream<List<ChallengeModel>> watchCompanyChallenges(String companyId) {
    return _challenges
        .where('companyId', isEqualTo: companyId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(ChallengeModel.fromDocument)
              .toList(growable: false),
        );
  }

  Future<String> createChallenge(ChallengeModel model) async {
    final document = _challenges.doc();
    final data = model.toFirestore()
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();

    await document.set(data);
    return document.id;
  }

  Future<void> updateChallenge(ChallengeModel model) async {
    if (model.id.isEmpty) {
      throw ArgumentError('A challenge ID is required for an update.');
    }
    await _challenges.doc(model.id).update(model.toUpdateFirestore());
  }

  Future<void> deleteChallenge({
    required String challengeId,
    required String companyId,
  }) async {
    // Preserve submissions and feedback. A challenge that has received a
    // submission should be closed, not physically deleted.
    final existingSubmissions = await _firestore
        .collection('submissions')
        .where('challengeId', isEqualTo: challengeId)
        .where('companyId', isEqualTo: companyId)
        .limit(1)
        .get();

    if (existingSubmissions.docs.isNotEmpty) {
      throw const ChallengeHasSubmissionsException();
    }

    final reference = _challenges.doc(challengeId);
    final snapshot = await reference.get();
    if (!snapshot.exists) return;

    final data = snapshot.data();
    if (data == null || data['companyId'] != companyId) {
      throw StateError('You are not allowed to delete this challenge.');
    }

    await reference.delete();
  }
}
