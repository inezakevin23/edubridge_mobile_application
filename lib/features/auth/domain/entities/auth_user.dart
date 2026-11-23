enum UserRole { talent, company, admin }

/// Roles that a user may select during public registration.
const publicRegistrationRoles = <UserRole>{UserRole.talent, UserRole.company};

UserRole? tryParseUserRole(String? value) {
  switch (value) {
    case 'talent':
      return UserRole.talent;
    case 'company':
      return UserRole.company;
    case 'admin':
      return UserRole.admin;
    default:
      return null;
  }
}

/// Backwards-compatible parser used by existing feature modules. New code that
/// must detect missing/invalid records should use [tryParseUserRole].
UserRole userRoleFromString(String value) =>
    tryParseUserRole(value) ?? UserRole.talent;

String userRoleToString(UserRole role) => role.name;

class AuthUser {
  const AuthUser({
    required this.id,
    required this.email,
    required this.role,
    this.emailVerified = false,
    this.displayName = '',
    this.photoUrl = '',
    this.requiresAccountSetup = false,
  });

  final String id;
  final String email;
  final String displayName;
  final String photoUrl;
  final UserRole role;
  final bool emailVerified;

  /// True when Firebase Authentication exists but its Firestore role record
  /// is missing or invalid. `role` remains non-null for compatibility with
  /// the other feature modules, but route guards must honor this flag.
  final bool requiresAccountSetup;
}
