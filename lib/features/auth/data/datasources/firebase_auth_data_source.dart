import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthDataSource {
  FirebaseAuthDataSource({
    required this._auth,
    required this._firestore,
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final GoogleSignIn _googleSignIn;

  static Future<void>? _googleInitialization;
  static const _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  Future<void> _ensureGoogleInitialized() {
    return _googleInitialization ??= _googleSignIn.initialize(
      serverClientId: _googleServerClientId.isEmpty
          ? null
          : _googleServerClientId,
    );
  }

  Stream<User?> authStateChanges() => _auth.idTokenChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> register(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
  }

  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleInitialized();
    if (!_googleSignIn.supportsAuthenticate()) {
      throw UnsupportedError(
        'This Google sign-in button is configured for Android/iOS. '
        'Web requires the Google-rendered sign-in button.',
      );
    }

    try {
      final account = await _googleSignIn.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        throw StateError(
          'Google did not return an ID token. Check the Web OAuth client ID '
          'and Firebase Google provider configuration.',
        );
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        throw FirebaseAuthException(
          code: 'google-sign-in-cancelled',
          message: 'Google sign-in was cancelled.',
        );
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserDocument(String uid) async {
    final snapshot = await _firestore.collection('users').doc(uid).get();
    return snapshot.data();
  }

  Future<Map<String, dynamic>?> getProfileDocument(String uid) async {
    final snapshot = await _firestore.collection('profiles').doc(uid).get();
    return snapshot.data();
  }

  /// Creates only missing records. It never overwrites an existing role.
  /// The user and profile documents are created atomically.
  Future<void> ensureAccountDocuments({
    required User user,
    required String role,
    required String displayName,
  }) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final profileRef = _firestore.collection('profiles').doc(user.uid);

    await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      final profileSnapshot = await transaction.get(profileRef);

      if (!userSnapshot.exists) {
        transaction.set(userRef, {
          'email': user.email ?? '',
          'role': role,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final storedRole = userSnapshot.data()?['role'];
        if (storedRole == null) {
          // One-time repair for older accounts whose user document exists but
          // whose role field was never written.
          transaction.update(userRef, {
            'role': role,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } else if (storedRole != role) {
          throw StateError('The saved account role cannot be changed here.');
        }
      }

      final resolvedName = displayName.trim().isNotEmpty
          ? displayName.trim()
          : (user.displayName?.trim().isNotEmpty == true
                ? user.displayName!.trim()
                : (user.email?.split('@').first ?? 'EduBridge user'));

      if (!profileSnapshot.exists) {
        transaction.set(profileRef, {
          'displayName': resolvedName,
          'photoUrl': user.photoURL ?? '',
          'bio': '',
          'description': '',
          'industry': '',
          'website': '',
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        final existingName = profileSnapshot.data()?['displayName'];
        if (existingName is! String || existingName.trim().isEmpty) {
          transaction.update(profileRef, {
            'displayName': resolvedName,
            'updatedAt': FieldValue.serverTimestamp(),
          });
        }
      }
    });
  }

  Future<void> updateProfile({
    required String uid,
    required Map<String, dynamic> values,
  }) async {
    await _firestore.collection('profiles').doc(uid).set({
      ...values,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
  }

  Future<void> resendEmailVerification() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No signed-in account was found.');
    await user.reload();
    final refreshedUser = _auth.currentUser;
    if (refreshedUser == null) {
      throw StateError('Please sign in again.');
    }
    if (!refreshedUser.emailVerified) {
      await refreshedUser.sendEmailVerification();
    }
  }

  Future<bool> reloadCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  Future<void> signOut() async {
    // Firebase sign-out must still happen if the Google plugin is unavailable
    // or no Google session was created for this account.
    try {
      await _ensureGoogleInitialized();
      await _googleSignIn.signOut();
    } catch (_) {
      // The Firebase session is the source of truth for app authentication.
    }
    await _auth.signOut();
  }
}
