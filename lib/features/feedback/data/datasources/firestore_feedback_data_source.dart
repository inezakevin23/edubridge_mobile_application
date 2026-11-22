import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edubridge_mobile_application/features/feedback/data/models/submission_feedback_model.dart';

class FirestoreFeedbackDataSource {
  FirestoreFeedbackDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _feedbackCollection =>
      _firestore.collection('feedback');

  Stream<SubmissionFeedbackModel?> watchForSubmission(String submissionId) {
    return _feedbackCollection.doc(submissionId).snapshots().map((document) {
      if (!document.exists || document.data() == null) return null;
      return SubmissionFeedbackModel.fromDocument(document);
    });
  }

  Future<SubmissionFeedbackModel?> getForSubmission(String submissionId) async {
    final document = await _feedbackCollection.doc(submissionId).get();
    if (!document.exists || document.data() == null) return null;
    return SubmissionFeedbackModel.fromDocument(document);
  }

  /// One feedback document is stored for each submission.
  /// A transaction preserves the original createdAt when feedback is edited.
  Future<void> save(SubmissionFeedbackModel feedback) async {
    final documentReference = _feedbackCollection.doc(feedback.submissionId);

    await _firestore.runTransaction((transaction) async {
      final existingDocument = await transaction.get(documentReference);
      final data = feedback.toFirestore();

      if (existingDocument.exists) {
        data['createdAt'] =
            existingDocument.data()?['createdAt'] ??
            FieldValue.serverTimestamp();
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
      }
      data['updatedAt'] = FieldValue.serverTimestamp();

      transaction.set(documentReference, data, SetOptions(merge: true));
    });
  }
}
