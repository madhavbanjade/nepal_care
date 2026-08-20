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
    this.uid = '',
    this.hourlyRate = 0,
    this.idDocumentUrl,
  });

  final String fullName;
  final String phone;
  final String serviceCategory;
  final String yearsOfExperience;
  final String bio;
  final String uid;
  final int hourlyRate;
  final String? idDocumentUrl;

  factory ProviderProfile.fromMap(Map<String, dynamic> map, {String uid = ''}) => ProviderProfile(
        fullName: map['fullName'] as String? ?? 'Care provider',
        phone: map['phone'] as String? ?? '',
        serviceCategory: map['serviceCategory'] as String? ?? 'Care services',
        yearsOfExperience: map['yearsOfExperience'] as String? ?? '',
        bio: map['bio'] as String? ?? '',
        uid: uid,
        hourlyRate: (map['hourlyRate'] as num?)?.toInt() ?? 0,
        idDocumentUrl: map['idDocumentUrl'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'fullName': fullName,
        'phone': phone,
        'serviceCategory': serviceCategory,
        'yearsOfExperience': yearsOfExperience,
        'bio': bio,
        'hourlyRate': hourlyRate,
        'idDocumentUrl': idDocumentUrl,
      };
}
