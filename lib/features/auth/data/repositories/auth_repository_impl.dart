import 'package:firebase_auth/firebase_auth.dart';

import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_data_source.dart';
import '../models/auth_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._source);
  final FirebaseAuthDataSource _source;

  Future<AuthUser> _mapFirebaseUser(User user) async {
    final userData = await _source.getUserDocument(user.uid);
    final profileData = await _source.getProfileDocument(user.uid);
    final rawRole = userData?['role'];
    final displayNameValue = profileData?['displayName'];
    final photoUrlValue = profileData?['photoUrl'];
    final role = rawRole is String ? rawRole : null;

    // An unknown role is not silently changed to Talent. The app routes the
    // account to an explicit setup screen so the user can recover safely.
    return AuthUserModel.fromValues(
      uid: user.uid,
      email: user.email ?? '',
      emailVerified: user.emailVerified,
      role: role,
      displayName: displayNameValue is String
          ? displayNameValue
          : (user.displayName ?? ''),
      photoUrl: photoUrlValue is String ? photoUrlValue : (user.photoURL ?? ''),
    );
  }

  @override
  Stream<AuthUser?> authStateChanges() {
    return _source.authStateChanges().asyncMap((user) async {
      if (user == null) {
        return null;
      }
      return _mapFirebaseUser(user);
    });
  }

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
    required UserRole role,
    required String displayName,
    Map<String, Object?> profileDetails = const {},
  }) async {
    if (!publicRegistrationRoles.contains(role)) {
      throw ArgumentError('Only Talent and Company accounts can register.');
    }
    final credential = await _source.register(email, password);
    final user = credential.user;
    if (user == null) throw StateError('Firebase did not return the new user.');

    await _source.ensureAccountDocuments(
      user: user,
      role: userRoleToString(role),
      displayName: displayName,
      profileDetails: profileDetails,
    );
    return _mapFirebaseUser(user);
  }

  @override
  Future<AuthUser> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _source.signIn(email, password);
    final user = credential.user;
    if (user == null) {
      throw StateError('Firebase did not return a signed-in user.');
    }
    return _mapFirebaseUser(user);
  }

  @override
  Future<AuthUser> signInWithGoogle({
    required UserRole newAccountRole,
    String displayName = '',
  }) async {
    if (!publicRegistrationRoles.contains(newAccountRole)) {
      throw ArgumentError('Only Talent and Company accounts can register.');
    }
    final credential = await _source.signInWithGoogle();
    final user = credential.user;
    if (user == null) throw StateError('Google sign-in did not return a user.');

    final existingData = await _source.getUserDocument(user.uid);
    final existingRole = existingData?['role'];
    final resolvedRole = existingRole is String
        ? existingRole
        : userRoleToString(newAccountRole);

    await _source.ensureAccountDocuments(
      user: user,
      role: resolvedRole,
      displayName: displayName.trim().isNotEmpty
          ? displayName.trim()
          : (user.displayName ?? ''),
    );
    return _mapFirebaseUser(user);
  }

  @override
  Future<void> completeAccountSetup({
    required UserRole role,
    required String displayName,
  }) async {
    if (!publicRegistrationRoles.contains(role)) {
      throw ArgumentError('Only Talent and Company accounts can be selected.');
    }
    final user = _source.currentUser;
    if (user == null) {
      throw StateError('Please sign in again to complete setup.');
    }
    final existing = await _source.getUserDocument(user.uid);
    final savedRole = existing?['role'];
    if (savedRole is String && tryParseUserRole(savedRole) == null) {
      throw StateError(
        'This account has an unsupported role. Ask an administrator to correct it.',
      );
    }
    await _source.ensureAccountDocuments(
      user: user,
      role: savedRole is String ? savedRole : userRoleToString(role),
      displayName: displayName,
    );
  }

  @override
  Future<void> signOut() => _source.signOut();

  @override
  Future<void> sendPasswordReset(String email) =>
      _source.sendPasswordReset(email);
}
