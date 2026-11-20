import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/submission.dart';

/// Firestore representation of [Submission]. All Firestore-specific
/// serialization stays in the data layer.
class SubmissionModel {
  const SubmissionModel({
    required this.id,
    required this.challengeId,
    required this.talentId,
    required this.companyId,
    required this.solutionText,
    required this.attachmentUrls,
    required this.status,
    required this.isShortlisted,
    required this.submittedAt,
    required this.updatedAt,
    this.reviewedAt,
  });

  final String id;
  final String challengeId;
  final String talentId;
  final String companyId;
  final String solutionText;
  final List<String> attachmentUrls;
  final SubmissionStatus status;
  final bool isShortlisted;
  final DateTime submittedAt;
  final DateTime updatedAt;
  final DateTime? reviewedAt;

  factory SubmissionModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw FormatException('Submission document ${document.id} has no data.');
    }
    return SubmissionModel.fromMap(document.id, data);
  }

  factory SubmissionModel.fromEntity(Submission submission) {
    return SubmissionModel(
      id: submission.id,
      challengeId: submission.challengeId,
      talentId: submission.talentId,
      companyId: submission.companyId,
      solutionText: submission.solutionText,
      attachmentUrls: List.unmodifiable(submission.attachmentUrls),
      status: submission.status,
      isShortlisted: submission.isShortlisted,
      submittedAt: submission.submittedAt,
      updatedAt: submission.updatedAt,
      reviewedAt: submission.reviewedAt,
    );
  }

  factory SubmissionModel.fromMap(String id, Map<String, dynamic> map) {
    return SubmissionModel(
      id: id,
      challengeId: _requiredString(map, 'challengeId'),
      talentId: _requiredString(map, 'talentId'),
      companyId: _requiredString(map, 'companyId'),
      solutionText: _requiredString(map, 'solutionText'),
      attachmentUrls: _stringList(map['attachmentUrls']),
      status: SubmissionStatusX.fromValue(map['status']),
      isShortlisted: _requiredBool(map, 'isShortlisted'),
      submittedAt: _requiredDateTime(map, 'submittedAt'),
      updatedAt: _requiredDateTime(map, 'updatedAt'),
      reviewedAt: _optionalDateTime(map['reviewedAt']),
    );
  }

  Submission toEntity() {
    return Submission(
      id: id,
      challengeId: challengeId,
      talentId: talentId,
      companyId: companyId,
      solutionText: solutionText,
      attachmentUrls: List.unmodifiable(attachmentUrls),
      status: status,
      isShortlisted: isShortlisted,
      submittedAt: submittedAt,
      updatedAt: updatedAt,
      reviewedAt: reviewedAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'challengeId': challengeId,
      'talentId': talentId,
      'companyId': companyId,
      'solutionText': solutionText.trim(),
      'attachmentUrls': attachmentUrls,
      'status': status.value,
      'isShortlisted': isShortlisted,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
    };
  }

  static String _requiredString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Submission field "$key" must be a non-empty string.');
    }
    return value;
  }

  static bool _requiredBool(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! bool) {
      throw FormatException('Submission field "$key" must be a boolean.');
    }
    return value;
  }

  static List<String> _stringList(Object? value) {
    if (value == null) return const [];
    if (value is! List || value.any((item) => item is! String)) {
      throw const FormatException('Submission attachmentUrls must be a list of strings.');
    }
    return List<String>.unmodifiable(value.cast<String>());
  }

  static DateTime _requiredDateTime(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    throw FormatException('Submission field "$key" must be a Firestore Timestamp.');
  }

  static DateTime? _optionalDateTime(Object? value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate().toUtc();
    if (value is DateTime) return value.toUtc();
    throw const FormatException('Submission reviewedAt must be a Firestore Timestamp.');
  }
}
