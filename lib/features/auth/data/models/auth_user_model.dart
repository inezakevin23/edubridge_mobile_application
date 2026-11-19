import '../../domain/entities/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.id,
    required super.email,
    required super.role,
    required super.emailVerified,
    super.displayName,
    super.photoUrl,
    super.requiresAccountSetup,
  });

  factory AuthUserModel.fromValues({
    required String uid,
    required String email,
    required bool emailVerified,
    required String? role,
    String displayName = '',
    String photoUrl = '',
  }) {
    final parsedRole = tryParseUserRole(role);
    return AuthUserModel(
      id: uid,
      email: email,
      emailVerified: emailVerified,
      role: parsedRole ?? UserRole.talent,
      requiresAccountSetup: parsedRole == null,
      displayName: displayName,
      photoUrl: photoUrl,
    );
  }
}
