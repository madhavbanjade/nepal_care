import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:nepal_care/models/provider_prrofile.dart';
import 'package:nepal_care/core/enum/user_role.dart';

/// Everything to do with a user's role and (for providers) their
/// verification profile. Screens only talk to this repository — never to
/// Firestore or Storage directly — same pattern as AuthRepository.
///
/// Firestore schema (one doc per user, keyed by their Firebase Auth uid):
///
/// users/{uid}
///   role: 'customer' | 'provider'
///   verificationStatus: 'pending' | 'verified' | 'rejected'   (providers only)
///   providerProfile: { fullName, phone, serviceCategory,
///                       yearsOfExperience, bio, idDocumentUrl }
///   updatedAt / submittedAt: server timestamps
///
/// See the README for the Firestore security rules that should back this —
/// in particular, `verificationStatus` should only ever move from 'pending'
/// to 'verified'/'rejected' via an admin console or Cloud Function, never
/// directly from the client.
class UserRepository {
  UserRepository({FirebaseFirestore? firestore, FirebaseStorage? storage})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection('users').doc(uid);

  /// Called right after role selection.
  Future<void> setRole(String uid, UserRole role) {
    return _userDoc(uid).set({
      'role': role.value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<UserRole?> getRole(String uid) async {
    final snapshot = await _userDoc(uid).get();
    return userRoleFromValue(snapshot.data()?['role'] as String?);
  }

  /// Uploads the ID/certificate to Storage and returns its download URL.
  Future<String> uploadIdDocument({
    required String uid,
    required File file,
    required String fileName,
  }) async {
    final ref = _storage.ref('provider_documents/$uid/$fileName');
    final task = await ref.putFile(file);
    return task.ref.getDownloadURL();
  }

  /// Saves the provider's profile and marks verification as pending.
  Future<void> submitProviderProfile(String uid, ProviderProfile profile) {
    return _userDoc(uid).set({
      'role': UserRole.provider.value,
      'providerProfile': profile.toMap(),
      'verificationStatus': 'pending',
      'submittedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
