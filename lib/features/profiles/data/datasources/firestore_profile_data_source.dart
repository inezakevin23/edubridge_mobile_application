import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/profile_model.dart';

class FirestoreProfileDataSource {
  const FirestoreProfileDataSource(this.firestore);
  final FirebaseFirestore firestore;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      firestore.collection('profiles');

  Future<ProfileModel?> getProfile(String userId) async {
    final snapshot = await _profiles.doc(userId).get();
    if (!snapshot.exists || snapshot.data() == null) return null;
    return ProfileModel.fromDocument(userId, snapshot.data()!);
  }

  Stream<ProfileModel?> watchProfile(String userId) {
    return _profiles.doc(userId).snapshots().map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return ProfileModel.fromDocument(userId, snapshot.data()!);
    });
  }

  Future<void> createOrUpdateProfile(ProfileModel profile) async {
    final reference = _profiles.doc(profile.userId);
    await firestore.runTransaction((transaction) async {
      final current = await transaction.get(reference);
      final data = profile.toFirestore();
      if (!current.exists) data['createdAt'] = FieldValue.serverTimestamp();
      transaction.set(reference, data, SetOptions(merge: true));
    });
  }
}
