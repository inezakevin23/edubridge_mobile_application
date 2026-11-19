import '../entities/auth_user.dart';

abstract class AuthRepository {
  Stream<AuthUser?> authStateChanges();

  Future<AuthUser> register({
    required String email,
    required String password,
    required UserRole role,
    required String displayName,
  });

  Future<AuthUser> signIn({required String email, required String password});

  /// Existing Google accounts keep their saved role. [newAccountRole] is used
  /// only when a Google account has no EduBridge user document yet.
  Future<AuthUser> signInWithGoogle({
    required UserRole newAccountRole,
    String displayName = '',
  });

  Future<void> completeAccountSetup({
    required UserRole role,
    required String displayName,
  });

  Future<void> signOut();
  Future<void> sendPasswordReset(String email);
  Future<void> resendEmailVerification();
  Future<bool> reloadCurrentUser();
}
