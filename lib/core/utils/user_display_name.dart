/// Returns a readable name when an account has no Firebase display name yet.
String userDisplayName({String? displayName, String? email, String fallback = 'Care-Nepal member'}) {
  final name = displayName?.trim();
  if (name != null && name.isNotEmpty) return name;

  final localPart = email?.split('@').first.trim() ?? '';
  if (localPart.isEmpty) return fallback;

  return localPart
      .split(RegExp(r'[._-]+'))
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
