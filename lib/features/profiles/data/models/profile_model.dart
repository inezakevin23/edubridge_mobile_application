import 'package:cloud_firestore/cloud_firestore.dart';

import '../../domain/entities/user_profile.dart';

class ProfileModel extends UserProfile {
  const ProfileModel({
    required super.userId,
    required super.role,
    required super.displayName,
    super.photoUrl,
    super.bio,
    super.headline,
    super.location,
    super.education,
    super.companyDescription,
    super.industry,
    super.website,
    super.createdAt,
    super.updatedAt,
  });

  factory ProfileModel.fromDocument(String userId, Map<String, dynamic> data) {
    DateTime? dateOf(Object? value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return ProfileModel(
      userId: userId,
      role: data['role'] as String? ?? 'talent',
      displayName: data['displayName'] as String? ?? '',
      photoUrl: data['photoUrl'] as String? ?? '',
      bio: data['bio'] as String? ?? '',
      headline: data['headline'] as String? ?? '',
      location: data['location'] as String? ?? '',
      education: data['education'] as String? ?? '',
      companyDescription: data['companyDescription'] as String? ?? '',
      industry: data['industry'] as String? ?? '',
      website: data['website'] as String? ?? '',
      createdAt: dateOf(data['createdAt']),
      updatedAt: dateOf(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'role': role,
    'displayName': displayName.trim(),
    'photoUrl': photoUrl.trim(),
    'bio': bio.trim(),
    'headline': headline.trim(),
    'location': location.trim(),
    'education': education.trim(),
    'companyDescription': companyDescription.trim(),
    'industry': industry.trim(),
    'website': website.trim(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
