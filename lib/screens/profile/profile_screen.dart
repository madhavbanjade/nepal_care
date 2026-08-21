import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nepal_care/core/enum/user_role.dart';
import 'package:nepal_care/core/utils/user_display_name.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.role});
  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox.shrink();
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? const <String, dynamic>{};
        final profile = data['providerProfile'] is Map
            ? Map<String, dynamic>.from(data['providerProfile'] as Map)
            : const <String, dynamic>{};
        final providerName =
            (role == UserRole.provider ? profile['fullName'] : null) as String?;
        final name = userDisplayName(
          displayName: providerName ?? user.displayName,
          email: user.email,
          fallback: role == UserRole.provider ? 'Care provider' : 'Care-Nepal member',
        );
        return _ProfileView(role: role, name: name, category: profile['serviceCategory'] as String?);
      },
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.role, required this.name, this.category});
  final UserRole role;
  final String name;
  final String? category;

  bool get _isProvider => role == UserRole.provider;
  String get _initials => name.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).take(2).map((word) => word[0]).join().toUpperCase();

  @override
  Widget build(BuildContext context) {
    final items = _isProvider
        ? const [
            (Icons.person_outline_rounded, 'Edit profile', 'Update your info and photo'),
            (Icons.verified_outlined, 'Certifications', 'Manage your credentials'),
            (Icons.calendar_today_outlined, 'Availability', 'Set your working hours'),
            (Icons.currency_rupee_rounded, 'Payment details', 'Bank & e-sewa settings'),
            (Icons.notifications_none_rounded, 'Notifications', 'Alerts and reminders'),
            (Icons.info_outline_rounded, 'Help & Support', 'FAQs and Care-Nepal'),
          ]
        : const [
            (Icons.person_outline_rounded, 'Edit profile', 'Name, photo, address'),
            (Icons.calendar_today_outlined, 'My bookings', 'Past and upcoming sessions'),
            (Icons.favorite_border_rounded, 'Saved providers', 'Your favourites'),
            (Icons.notifications_none_rounded, 'Notifications', 'Alerts and reminders'),
            (Icons.info_outline_rounded, 'Help & Support', 'FAQs and contact us'),
          ];
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
          child: Column(children: [
            Container(
              width: 54, height: 54, alignment: Alignment.center,
              decoration: BoxDecoration(color: _isProvider ? const Color(0xFFF6B8BB) : const Color(0xFF91C8EF), borderRadius: BorderRadius.circular(16)),
              child: Text(_initials.isEmpty ? 'CN' : _initials, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            ),
            const SizedBox(height: 10),
            Text(name, style: const TextStyle(fontFamily: 'Fraunces', fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(_isProvider ? (category ?? 'Care provider') : 'Customer · Kathmandu', style: const TextStyle(fontSize: 10, color: Color(0xFF999999))),
            if (_isProvider) ...[
              const SizedBox(height: 5),
              const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.verified_rounded, size: 13, color: Color(0xFF54A9E2)), SizedBox(width: 3), Text('Care-Nepal Verified', style: TextStyle(fontSize: 10, color: Color(0xFF327CB3)))]),
              const SizedBox(height: 16),
              const Row(children: [_Stat('★', '4.9', 'Rating', Color(0xFFFFF8E7), Color(0xFFFFD48C)), SizedBox(width: 8), _Stat('◉', '214', 'Jobs', Color(0xFFEAF9EB), Color(0xFF8CD99A)), SizedBox(width: 8), _Stat('♙', '7 yrs', 'Exp.', Color(0xFFEAF6FF), Color(0xFF8AC7F4))]),
            ] else const SizedBox(height: 14),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(padding: const EdgeInsets.only(bottom: 7), child: _ProfileItem(icon: item.$1, title: item.$2, subtitle: item.$3))),
            const SizedBox(height: 4),
            SizedBox(width: double.infinity, height: 42, child: OutlinedButton(onPressed: () => FirebaseAuth.instance.signOut(), style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFE13B32), side: const BorderSide(color: Color(0xFFFF4039)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11))), child: const Text('Log out'))),
          ]),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.icon, this.value, this.label, this.color, this.border);
  final String icon;
  final String value;
  final String label;
  final Color color;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: TextStyle(fontSize: 11, color: border)),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 7, color: Color(0xFF888888)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  const _ProfileItem({required this.icon, required this.title, required this.subtitle});
  final IconData icon; final String title, subtitle;
  @override Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9), decoration: BoxDecoration(border: Border.all(color: const Color(0xFFE0E0E0)), borderRadius: BorderRadius.circular(11)), child: Row(children: [Container(width: 27, height: 27, decoration: const BoxDecoration(color: Color(0xFFF5F5F5), shape: BoxShape.circle), child: Icon(icon, size: 14, color: const Color(0xFF666666))), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 11)), Text(subtitle, style: const TextStyle(fontSize: 8, color: Color(0xFF9A9A9A)))])), const Icon(Icons.chevron_right_rounded, size: 17, color: Color(0xFFBDBDBD))]));
}
