import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/challenge.dart';

/// Firestore representation of [Challenge].
///
/// Keep Firestore-specific serialization in this class, not in the UI or
/// domain entity.
class ChallengeModel {
  const ChallengeModel({
    required this.id,
    required this.companyId,
    required this.title,
    required this.description,
    required this.category,
    required this.requirements,
    required this.deadline,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String companyId;
  final String title;
  final String description;
  final String category;
  final List<String> requirements;
  final DateTime deadline;
  final ChallengeStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ChallengeModel.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    if (data == null) {
      throw FormatException('Challenge document ${document.id} has no data.');
    }
    return ChallengeModel.fromMap(document.id, data);
  }

  factory ChallengeModel.fromMap(String id, Map<String, dynamic> map) {
    return ChallengeModel(
      id: id,
      companyId: _requiredString(map, 'companyId'),
      title: _requiredString(map, 'title'),
      description: _requiredString(map, 'description'),
      category: _requiredString(map, 'category'),
      requirements: _requiredStringList(map, 'requirements'),
      deadline: _requiredDateTime(map, 'deadline'),
      status: ChallengeStatusX.fromValue(map['status']),
      createdAt: _requiredDateTime(map, 'createdAt'),
      updatedAt: _requiredDateTime(map, 'updatedAt'),
    );
  }

  factory ChallengeModel.fromEntity(Challenge challenge) {
    return ChallengeModel(
      id: challenge.id,
      companyId: challenge.companyId,
      title: challenge.title,
      description: challenge.description,
      category: challenge.category,
      requirements: List.unmodifiable(challenge.requirements),
      deadline: challenge.deadline,
      status: challenge.status,
      createdAt: challenge.createdAt,
      updatedAt: challenge.updatedAt,
    );
  }

  Challenge toEntity() {
    return Challenge(
      id: id,
      companyId: companyId,
      title: title,
      description: description,
      category: category,
      requirements: List.unmodifiable(requirements),
      deadline: deadline,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  /// Used when creating a challenge. The data source replaces createdAt and
  /// updatedAt with Firestore server timestamps.
  Map<String, dynamic> toFirestore() {
    return {
      'companyId': companyId,
      'title': title.trim(),
      'description': description.trim(),
      'category': category.trim(),
      'requirements': requirements.map((item) => item.trim()).toList(),
      'deadline': Timestamp.fromDate(deadline),
      'status': status.value,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Fields a company is allowed to change after creation.
  Map<String, dynamic> toUpdateFirestore() {
    return {
      'title': title.trim(),
      'description': description.trim(),
      'category': category.trim(),
      'requirements': requirements.map((item) => item.trim()).toList(),
      'deadline': Timestamp.fromDate(deadline),
      'status': status.value,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static String _requiredString(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException(
        'Challenge field "$key" must be a non-empty string.',
      );
    }
    return value;
  }

  static List<String> _requiredStringList(
    Map<String, dynamic> map,
    String key,
  ) {
    final value = map[key];
    if (value is! List ||
        value.isEmpty ||
        value.any((item) => item is! String)) {
      throw FormatException(
        'Challenge field "$key" must be a non-empty list of strings.',
      );
    }
    return value.cast<String>();
  }

  static DateTime _requiredDateTime(Map<String, dynamic> map, String key) {
    final value = map[key];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    throw FormatException(
      'Challenge field "$key" must be a Firestore Timestamp.',
    );
  }
}
