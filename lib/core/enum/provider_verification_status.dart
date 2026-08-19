/// The approval state of a provider profile stored in Firestore.
enum ProviderVerificationStatus { pending, verified }

extension ProviderVerificationStatusFirestoreValue on ProviderVerificationStatus {
  String get value => switch (this) {
        ProviderVerificationStatus.pending => 'pending',
        ProviderVerificationStatus.verified => 'verified',
      };
}

ProviderVerificationStatus? providerVerificationStatusFromValue(String? value) => switch (value) {
      'pending' => ProviderVerificationStatus.pending,
      'verified' => ProviderVerificationStatus.verified,
      _ => null,
    };
