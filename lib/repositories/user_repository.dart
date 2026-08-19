import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:nepal_care/core/enum/provider_verification_status.dart';
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
///   verificationStatus: 'pending' | 'verified'   (providers only)
///   providerProfile: { fullName, phone, serviceCategory,
///                       yearsOfExperience, bio, idDocumentUrl }
///   updatedAt / submittedAt: server timestamps
///
/// See the README for the Firestore security rules that should back this —
/// in particular, `verificationStatus` should only ever move from 'pending'
/// to 'verified' via an admin console or Cloud Function, never
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
  Future<void> setRole(String uid, UserRole role) async {
    debugPrint('[Role selection] Saving role=${role.value} for uid=$uid');
    await _userDoc(uid).set({
      'role': role.value,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    debugPrint('[Role selection] Saved role=${role.value} for uid=$uid');
  }

  Future<UserRole?> getRole(String uid) async {
    final snapshot = await _userDoc(uid).get();
    return userRoleFromValue(snapshot.data()?['role'] as String?);
  }

  /// Emits provider profiles only after an admin has marked them verified in
  /// Firestore. Pending profiles are deliberately excluded from this stream.
  Stream<List<ProviderProfile>> streamVerifiedProviderProfiles() async* {
    try {
      final verifiedProvidersQuery = _firestore
        .collection('users')
        .where(
          'verificationStatus',
          isEqualTo: ProviderVerificationStatus.verified.value,
        );

      await for (final snapshot in verifiedProvidersQuery.snapshots()) {
        debugPrint(
          '[Verified providers] Query returned ${snapshot.docs.length} document(s).',
        );

        final profiles = <ProviderProfile>[];
        for (final document in snapshot.docs) {
          final data = document.data();
          final profileData = data['providerProfile'];
          debugPrint(
            '[Verified providers] id=${document.id}, role=${data["role"]}, '
            'status=${data["verificationStatus"]}, '
            'hasProfile=${profileData is Map}',
          );

          if (profileData is! Map) {
            debugPrint(
              '[Verified providers] Skipped ${document.id}: providerProfile is missing or invalid.',
            );
            continue;
          }

          profiles.add(
            ProviderProfile.fromMap(Map<String, dynamic>.from(profileData)),
          );
        }

        debugPrint(
          '[Verified providers] Displaying ${profiles.length} provider card(s).',
        );
        yield profiles;
      }
    } catch (error, stackTrace) {
      debugPrint('[Verified providers] Firestore query failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
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
      'verificationStatus': ProviderVerificationStatus.pending.value,
      'submittedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
