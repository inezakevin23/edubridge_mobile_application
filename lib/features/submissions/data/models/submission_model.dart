import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/submission.dart';

class SubmissionModel extends Submission {
  const SubmissionModel({
    required super.id,
    required super.challengeId,
    required super.talentId,
    required super.companyId,
    required super.solutionText,
    super.attachmentUrls,
    super.status,
    super.isShortlisted,
    required super.submittedAt,
    required super.updatedAt,
    super.reviewedAt,
    super.challengeTitle,
    super.talentName,
    super.talentEmail,
    super.feedback,
    super.pointsAwarded,
  });

  factory SubmissionModel.fromEntity(Submission submission) {
    return SubmissionModel(
      id: submission.id,
      challengeId: submission.challengeId,
      talentId: submission.talentId,
      companyId: submission.companyId,
      solutionText: submission.solutionText,
      attachmentUrls: submission.attachmentUrls,
      status: submission.status,
      isShortlisted: submission.isShortlisted,
      submittedAt: submission.submittedAt,
      updatedAt: submission.updatedAt,
      reviewedAt: submission.reviewedAt,
      challengeTitle: submission.challengeTitle,
      talentName: submission.talentName,
      talentEmail: submission.talentEmail,
      feedback: submission.feedback,
      pointsAwarded: submission.pointsAwarded,
    );
  }

  factory SubmissionModel.fromMap(Map<String, dynamic> map, {String? id}) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.now();
    }

    DateTime? parseNullableDateTime(dynamic value) {
      if (value == null) return null;
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value);
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return null;
    }

    // Attachment URLs list parsing
    List<String> parseAttachments(dynamic raw) {
      if (raw is List) {
        return raw.map((e) => e.toString()).toList();
      }
      return [];
    }

    final docId = id ?? map['id'] as String? ?? '';
    final challengeId = map['challengeId'] as String? ?? '';
    final talentId = map['talentId'] as String? ?? '';

    return SubmissionModel(
      id: docId.isNotEmpty ? docId : Submission.generateId(challengeId, talentId),
      challengeId: challengeId,
      talentId: talentId,
      companyId: map['companyId'] as String? ?? '',
      solutionText: map['solutionText'] as String? ??
          map['description'] as String? ??
          '',
      attachmentUrls: parseAttachments(map['attachmentUrls']),
      status: map['status'] as String? ?? 'submitted',
      isShortlisted: map['isShortlisted'] as bool? ?? false,
      submittedAt: parseDateTime(map['submittedAt']),
      updatedAt: parseDateTime(map['updatedAt'] ?? map['submittedAt']),
      reviewedAt: parseNullableDateTime(map['reviewedAt']),
      challengeTitle: map['challengeTitle'] as String?,
      talentName: map['talentName'] as String?,
      talentEmail: map['talentEmail'] as String?,
      feedback: map['feedback'] as String?,
      pointsAwarded: (map['pointsAwarded'] as num?)?.toInt(),
    );
  }

  factory SubmissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SubmissionModel.fromMap(data, id: doc.id);
  }

  Map<String, dynamic> toFirestoreMap() {
    return {
      'challengeId': challengeId,
      'talentId': talentId,
      'companyId': companyId,
      'solutionText': solutionText,
      'attachmentUrls': attachmentUrls,
      'status': status,
      'isShortlisted': isShortlisted,
      'submittedAt': Timestamp.fromDate(submittedAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
    };
  }

  Map<String, dynamic> toMap() {
    return toFirestoreMap();
  }

  Map<String, dynamic> toJsonMap() {
    return {
      'id': id,
      'challengeId': challengeId,
      'talentId': talentId,
      'companyId': companyId,
      'solutionText': solutionText,
      'attachmentUrls': attachmentUrls,
      'status': status,
      'isShortlisted': isShortlisted,
      'submittedAt': submittedAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (reviewedAt != null) 'reviewedAt': reviewedAt!.toIso8601String(),
      if (challengeTitle != null) 'challengeTitle': challengeTitle,
      if (talentName != null) 'talentName': talentName,
      if (talentEmail != null) 'talentEmail': talentEmail,
      if (feedback != null) 'feedback': feedback,
      if (pointsAwarded != null) 'pointsAwarded': pointsAwarded,
    };
  }
}
