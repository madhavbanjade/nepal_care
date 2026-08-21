import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nepal_care/core/theme/app_colors.dart';
import 'package:nepal_care/models/booking.dart';
import 'package:nepal_care/repositories/booking_repository.dart';
import 'package:nepal_care/core/enum/user_role.dart';
import 'package:nepal_care/screens/profile/profile_screen.dart';

class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({super.key});

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Scaffold(body: Center(child: Text('Please log in to see your bookings.')));
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _selectedNavIndex == 3 ? null : AppBar(backgroundColor: AppColors.background, surfaceTintColor: Colors.transparent, title: const Text('Provider dashboard')),
      body: _selectedNavIndex == 3 ? const ProfileScreen(role: UserRole.provider) : StreamBuilder<List<Booking>>(
        stream: BookingRepository().streamProviderBookings(user.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text('Unable to load booking requests.'));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final pending = snapshot.data!.where((item) => item.status == BookingStatus.pending).toList();
          final accepted = snapshot.data!.where((item) => item.status == BookingStatus.accepted).toList();
          return ListView(padding: const EdgeInsets.all(20), children: [
            Row(children: [_StatCard('Pending', '${pending.length}', const Color(0xFFFFD5D5)), const SizedBox(width: 10), _StatCard('Accepted', '${accepted.length}', const Color(0xFFD6ECFC))]),
            const SizedBox(height: 24),
            Text('Booking requests', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (pending.isEmpty) const _EmptyBookings() else ...pending.map((item) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _BookingCard(booking: item))),
            const SizedBox(height: 20),
            Text('Upcoming schedule', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (accepted.isEmpty) const _EmptyBookings(message: 'Accepted bookings will appear here.') else ...accepted.map((item) => Padding(padding: const EdgeInsets.only(bottom: 12), child: _BookingCard(booking: item, canRespond: false))),
          ]);
        },
      ),
      bottomNavigationBar: NavigationBar(
        height: 64,
        selectedIndex: _selectedNavIndex,
        onDestinationSelected: (index) => setState(() => _selectedNavIndex = index),
        indicatorColor: const Color(0xFFF7C5C6),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_today_outlined), label: 'Schedule'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), label: 'Earnings'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.color);
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value, style: Theme.of(context).textTheme.headlineSmall), Text(label)])));
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, this.canRespond = true});
  final Booking booking;
  final bool canRespond;
  @override
  Widget build(BuildContext context) {
    final date = MaterialLocalizations.of(context).formatMediumDate(booking.scheduledAt);
    final time = MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(booking.scheduledAt));
    return Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.borderGray)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(booking.customerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: 3), Text(booking.serviceCategory), const SizedBox(height: 7), Text('$date at $time'),
      if (booking.hourlyRate > 0) Padding(padding: const EdgeInsets.only(top: 5), child: Text('Rs ${booking.hourlyRate} / hour', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accentRed))),
      if (canRespond) ...[const SizedBox(height: 12), Row(children: [Expanded(child: OutlinedButton(onPressed: () => BookingRepository().setBookingStatus(booking.id, BookingStatus.declined), child: const Text('Decline'))), const SizedBox(width: 10), Expanded(child: FilledButton(onPressed: () => BookingRepository().setBookingStatus(booking.id, BookingStatus.accepted), child: const Text('Accept')))])],
    ]));
  }
}

class _EmptyBookings extends StatelessWidget {
  const _EmptyBookings({this.message = 'No booking requests yet.'});
  final String message;
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(24), alignment: Alignment.center, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)), child: Text(message));
}
