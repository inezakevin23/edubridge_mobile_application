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
    this.shortDescription = '',
    required this.description,
    required this.category,
    this.estimatedDuration = '',
    this.requiredSkills = const [],
    this.difficulty = '',
    this.submissionFormats = const [],
    this.maxTeamSize = 1,
    this.participantStatus = '',
    this.accessType = 'open',
    this.cashPrize = '',
    required this.requirements,
    this.eligibility = '',
    this.reward = '',
    required this.deadline,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String companyId;
  final String title;
  final String shortDescription;
  final String description;
  final String category;
  final String estimatedDuration;
  final List<String> requiredSkills;
  final String difficulty;
  final List<String> submissionFormats;
  final int maxTeamSize;
  final String participantStatus;
  final String accessType;
  final String cashPrize;
  final List<String> requirements;
  final String eligibility;
  final String reward;
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
      shortDescription: _optionalString(map, 'shortDescription'),
      description: _requiredString(map, 'description'),
      category: _requiredString(map, 'category'),
      estimatedDuration: _optionalString(map, 'estimatedDuration'),
      requiredSkills: _optionalStringList(map, 'requiredSkills'),
      difficulty: _optionalString(map, 'difficulty'),
      submissionFormats: _optionalStringList(map, 'submissionFormats'),
      maxTeamSize: _optionalInt(map, 'maxTeamSize', fallback: 1),
      participantStatus: _optionalString(map, 'participantStatus'),
      accessType: _optionalString(map, 'accessType', fallback: 'open'),
      cashPrize: _optionalString(map, 'cashPrize'),
      requirements: _requiredStringList(map, 'requirements'),
      eligibility: _optionalString(map, 'eligibility'),
      reward: _optionalString(map, 'reward'),
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
      shortDescription: challenge.shortDescription,
      description: challenge.description,
      category: challenge.category,
      estimatedDuration: challenge.estimatedDuration,
      requiredSkills: List.unmodifiable(challenge.requiredSkills),
      difficulty: challenge.difficulty,
      submissionFormats: List.unmodifiable(challenge.submissionFormats),
      maxTeamSize: challenge.maxTeamSize,
      participantStatus: challenge.participantStatus,
      accessType: challenge.accessType,
      cashPrize: challenge.cashPrize,
      requirements: List.unmodifiable(challenge.requirements),
      eligibility: challenge.eligibility,
      reward: challenge.reward,
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
      shortDescription: shortDescription,
      description: description,
      category: category,
      estimatedDuration: estimatedDuration,
      requiredSkills: List.unmodifiable(requiredSkills),
      difficulty: difficulty,
      submissionFormats: List.unmodifiable(submissionFormats),
      maxTeamSize: maxTeamSize,
      participantStatus: participantStatus,
      accessType: accessType,
      cashPrize: cashPrize,
      requirements: List.unmodifiable(requirements),
      eligibility: eligibility,
      reward: reward,
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
      'shortDescription': shortDescription.trim(),
      'description': description.trim(),
      'category': category.trim(),
      'estimatedDuration': estimatedDuration.trim(),
      'requiredSkills': requiredSkills.map((item) => item.trim()).toList(),
      'difficulty': difficulty.trim(),
      'submissionFormats': submissionFormats
          .map((item) => item.trim())
          .toList(),
      'maxTeamSize': maxTeamSize,
      'participantStatus': participantStatus.trim(),
      'accessType': accessType.trim(),
      'cashPrize': cashPrize.trim(),
      'requirements': requirements.map((item) => item.trim()).toList(),
      'eligibility': eligibility.trim(),
      'reward': reward.trim(),
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
      'shortDescription': shortDescription.trim(),
      'description': description.trim(),
      'category': category.trim(),
      'estimatedDuration': estimatedDuration.trim(),
      'requiredSkills': requiredSkills.map((item) => item.trim()).toList(),
      'difficulty': difficulty.trim(),
      'submissionFormats': submissionFormats
          .map((item) => item.trim())
          .toList(),
      'maxTeamSize': maxTeamSize,
      'participantStatus': participantStatus.trim(),
      'accessType': accessType.trim(),
      'cashPrize': cashPrize.trim(),
      'requirements': requirements.map((item) => item.trim()).toList(),
      'eligibility': eligibility.trim(),
      'reward': reward.trim(),
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

  static String _optionalString(
    Map<String, dynamic> map,
    String key, {
    String fallback = '',
  }) {
    final value = map[key];
    if (value == null) return fallback;
    if (value is String) return value;
    throw FormatException('Challenge field "$key" must be a string.');
  }

  static int _optionalInt(
    Map<String, dynamic> map,
    String key, {
    required int fallback,
  }) {
    final value = map[key];
    if (value == null) return fallback;
    if (value is int && value > 0) return value;
    throw FormatException('Challenge field "$key" must be a positive integer.');
  }

  static List<String> _optionalStringList(
    Map<String, dynamic> map,
    String key,
  ) {
    final value = map[key];
    if (value == null) return const [];
    if (value is! List || value.any((item) => item is! String)) {
      throw FormatException(
        'Challenge field "$key" must be a list of strings.',
      );
    }
    return value.cast<String>();
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
