/// Profile data shared by Talent and Company accounts.
/// Role-specific fields are optional and only shown by the relevant screen.
class UserProfile {
  const UserProfile({
    required this.userId,
    required this.role,
    required this.displayName,
    this.photoUrl = '',
    this.bio = '',
    this.headline = '',
    this.location = '',
    this.education = '',
    this.companyDescription = '',
    this.industry = '',
    this.website = '',
    this.registrationDetails = const {},
    this.scorePoints = 0,
    this.createdAt,
    this.updatedAt,
  });

  final String userId;
  final String role; // 'talent' or 'company'
  final String displayName;
  final String photoUrl;
  final String bio;

  // Talent-specific fields
  final String headline;
  final String location;
  final String education;

  // Company-specific fields
  final String companyDescription;
  final String industry;
  final String website;
  final Map<String, Object?> registrationDetails;
  final int scorePoints;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isCompany => role == 'company';
  bool get isTalent => role == 'talent';

  UserProfile copyWith({
    String? role,
    String? displayName,
    String? photoUrl,
    String? bio,
    String? headline,
    String? location,
    String? education,
    String? companyDescription,
    String? industry,
    String? website,
    Map<String, Object?>? registrationDetails,
    int? scorePoints,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => UserProfile(
    userId: userId,
    role: role ?? this.role,
    displayName: displayName ?? this.displayName,
    photoUrl: photoUrl ?? this.photoUrl,
    bio: bio ?? this.bio,
    headline: headline ?? this.headline,
    location: location ?? this.location,
    education: education ?? this.education,
    companyDescription: companyDescription ?? this.companyDescription,
    industry: industry ?? this.industry,
    website: website ?? this.website,
    registrationDetails: registrationDetails ?? this.registrationDetails,
    scorePoints: scorePoints ?? this.scorePoints,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
