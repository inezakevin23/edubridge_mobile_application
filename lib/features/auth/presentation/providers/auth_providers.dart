import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/firebase_auth_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Shared Firebase providers. Member 2–4 should reuse these rather than
/// creating additional Firebase instances or initialization code.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final firebaseAuthDataSourceProvider = Provider<FirebaseAuthDataSource>((ref) {
  return FirebaseAuthDataSource(
    auth: ref.watch(firebaseAuthProvider),
    firestore: ref.watch(firestoreProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(firebaseAuthDataSourceProvider));
});

final authStateProvider = StreamProvider<AuthUser?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final authControllerProvider = Provider<AuthController>((ref) {
  return AuthController(ref.watch(authRepositoryProvider));
});

/// Forces a fresh first event from Firebase after actions that may create or
/// repair Firestore account documents. This avoids routing on a stale early
/// auth event that arrived before account setup finished.
Future<AuthUser?> refreshAuthState(WidgetRef ref) {
  return ref.refresh(authStateProvider.future);
}

class AuthController {
  const AuthController(this._repository);
  final AuthRepository _repository;

  Future<AuthUser> register({
    required String email,
    required String password,
    required UserRole role,
    required String displayName,
    Map<String, Object?> profileDetails = const {},
  }) {
    return _repository.register(
      email: email,
      password: password,
      role: role,
      displayName: displayName,
      profileDetails: profileDetails,
    );
  }

  Future<AuthUser> signIn(String email, String password) {
    return _repository.signIn(email: email, password: password);
  }

  Future<AuthUser> signInWithGoogle(UserRole role, {String displayName = ''}) {
    return _repository.signInWithGoogle(
      newAccountRole: role,
      displayName: displayName,
    );
  }

  Future<void> completeAccountSetup({
    required UserRole role,
    required String displayName,
  }) {
    return _repository.completeAccountSetup(
      role: role,
      displayName: displayName,
    );
  }

  Future<void> signOut() => _repository.signOut();
  Future<void> resetPassword(String email) =>
      _repository.sendPasswordReset(email);
}
