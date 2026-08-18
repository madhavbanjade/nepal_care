/// The data collected on the "Professional profile" form. Kept as a plain
/// model separate from the Firestore repository so the UI never has to
/// think about map keys directly.
class ProviderProfile {
  const ProviderProfile({
    required this.fullName,
    required this.phone,
    required this.serviceCategory,
    required this.yearsOfExperience,
    required this.bio,
    this.idDocumentUrl,
  });

  final String fullName;
  final String phone;
  final String serviceCategory;
  final String yearsOfExperience;
  final String bio;
  final String? idDocumentUrl;

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'phone': phone,
        'serviceCategory': serviceCategory,
        'yearsOfExperience': yearsOfExperience,
        'bio': bio,
        'idDocumentUrl': idDocumentUrl,
      };
}