/// The two roles a user can pick on the role-selection screen.
/// Kept intentionally small — add more (e.g. `admin`) only when there's an
/// actual admin surface to gate, not speculatively.
enum UserRole { customer, provider }

extension UserRoleFirestoreValue on UserRole {
  /// The exact string stored in Firestore's `role` field.
  String get value => switch (this) {
        UserRole.customer => 'customer',
        UserRole.provider => 'provider',
      };
}

UserRole? userRoleFromValue(String? value) => switch (value) {
      'customer' => UserRole.customer,
      'provider' => UserRole.provider,
      _ => null,
    };