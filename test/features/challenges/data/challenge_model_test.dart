import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:edubridge_mobile_application/features/challenges/data/models/challenge_model.dart';
import 'package:edubridge_mobile_application/features/challenges/domain/entities/challenge.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _legacyChallengeMap() {
  final now = DateTime.utc(2026, 11, 21);
  return {
    'companyId': 'company-1',
    'title': 'Campus Garden',
    'description': 'Design a practical community garden plan.',
    'category': 'Design',
    'requirements': ['Submit a garden plan'],
    'deadline': Timestamp.fromDate(now.add(const Duration(days: 14))),
    'status': 'open',
    'createdAt': Timestamp.fromDate(now),
    'updatedAt': Timestamp.fromDate(now),
  };
}

void main() {
  test('legacy challenge documents default the new optional fields', () {
    final challenge = ChallengeModel.fromMap(
      'legacy-challenge',
      _legacyChallengeMap(),
    );

    expect(challenge.shortDescription, isEmpty);
    expect(challenge.estimatedDuration, isEmpty);
    expect(challenge.requiredSkills, isEmpty);
    expect(challenge.difficulty, isEmpty);
    expect(challenge.submissionFormats, isEmpty);
    expect(challenge.maxTeamSize, 1);
    expect(challenge.accessType, 'open');
    expect(challenge.eligibility, isEmpty);
    expect(challenge.reward, isEmpty);
  });

  test('new challenge fields round-trip to Firestore data', () {
    final now = DateTime.utc(2026, 11, 21);
    final entity = Challenge(
      id: 'full-challenge',
      companyId: 'company-1',
      title: 'Campus Garden',
      shortDescription: 'Plan an accessible community garden.',
      description: 'Design a practical community garden plan.',
      category: 'Design',
      estimatedDuration: '2-3 weeks',
      requiredSkills: const ['Landscape design', 'Research'],
      difficulty: 'Intermediate',
      submissionFormats: const ['Written Report', 'Slide Deck'],
      maxTeamSize: 4,
      participantStatus: 'Students',
      accessType: 'open',
      cashPrize: '500',
      requirements: const ['Submit a garden plan'],
      eligibility: 'Open to all students',
      reward: 'Mentorship and a certificate',
      deadline: now.add(const Duration(days: 14)),
      status: ChallengeStatus.open,
      createdAt: now,
      updatedAt: now,
    );

    final serialized = ChallengeModel.fromEntity(entity).toFirestore();
    final restored = ChallengeModel.fromMap('full-challenge', serialized);
    final update = ChallengeModel.fromEntity(entity).toUpdateFirestore();

    expect(restored.shortDescription, entity.shortDescription);
    expect(restored.estimatedDuration, entity.estimatedDuration);
    expect(restored.requiredSkills, entity.requiredSkills);
    expect(restored.difficulty, entity.difficulty);
    expect(restored.submissionFormats, entity.submissionFormats);
    expect(restored.maxTeamSize, entity.maxTeamSize);
    expect(restored.participantStatus, entity.participantStatus);
    expect(restored.accessType, entity.accessType);
    expect(restored.cashPrize, entity.cashPrize);
    expect(restored.eligibility, entity.eligibility);
    expect(restored.reward, entity.reward);
    expect(update['shortDescription'], entity.shortDescription);
    expect(update['estimatedDuration'], entity.estimatedDuration);
    expect(update['requiredSkills'], entity.requiredSkills);
    expect(update['difficulty'], entity.difficulty);
    expect(update['submissionFormats'], entity.submissionFormats);
    expect(update['maxTeamSize'], entity.maxTeamSize);
    expect(update['participantStatus'], entity.participantStatus);
    expect(update['accessType'], entity.accessType);
    expect(update['cashPrize'], entity.cashPrize);
    expect(update['eligibility'], entity.eligibility);
    expect(update['reward'], entity.reward);
  });

  test('malformed optional skill data is rejected', () {
    final data = _legacyChallengeMap()..['requiredSkills'] = ['Dart', 42];

    expect(
      () => ChallengeModel.fromMap('invalid-challenge', data),
      throwsFormatException,
    );
  });

  test('website published status maps to open and drafts stay private', () {
    final published = _legacyChallengeMap()..['status'] = 'published';
    final draft = _legacyChallengeMap()..['status'] = 'draft';

    expect(
      ChallengeModel.fromMap('published', published).status,
      ChallengeStatus.open,
    );
    expect(
      ChallengeModel.fromMap('draft', draft).status,
      ChallengeStatus.draft,
    );
  });
}
