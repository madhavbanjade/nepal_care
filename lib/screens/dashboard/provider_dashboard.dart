import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nepal_care/core/theme/app_colors.dart';
import 'package:nepal_care/core/theme/app_text_theme.dart';
import 'package:nepal_care/models/booking.dart';
import 'package:nepal_care/repositories/booking_repository.dart';
import 'package:nepal_care/core/enum/user_role.dart';
import 'package:nepal_care/core/utils/user_display_name.dart';
import 'package:nepal_care/repositories/chat_repository.dart';
import 'package:nepal_care/screens/chat/chat_screen.dart';
import 'package:nepal_care/screens/chat/message_list_screen.dart';
import 'package:nepal_care/screens/profile/profile_screen.dart';

/// How soon a pending booking must start to get the "URGENT" badge and the
/// expanded detail card treatment.
const _urgentWindow = Duration(hours: 6);

const _avatarPalette = <Color>[
  Color(0xFFC8EAF8),
  Color(0xFFFFD9DA),
  Color(0xFFDFF0DF),
  Color(0xFFFFE7A8),
  Color(0xFFD9D7E8),
];

class ProviderDashboard extends StatefulWidget {
  const ProviderDashboard({
    super.key,
    this.providerName = 'Provider',
    this.locationLabel = 'Kathmandu',
  });

  final String providerName;
  final String locationLabel;

  @override
  State<ProviderDashboard> createState() => _ProviderDashboardState();
}

class _ProviderDashboardState extends State<ProviderDashboard> {
  int _selectedNavIndex = 0;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in to see your bookings.')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _selectedNavIndex == 3
            ? const ProfileScreen(role: UserRole.provider)
            : _selectedNavIndex == 2
                ? MessagesListScreen(currentUserId: user.uid)
            : StreamBuilder<List<Booking>>(
                stream: BookingRepository().streamProviderBookings(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Unable to load booking requests.'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final bookings = snapshot.data!;
                  final pending = bookings.where((b) => b.status == BookingStatus.pending).toList()
                    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
                  final accepted = bookings.where((b) => b.status == BookingStatus.accepted).toList()
                    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

                  final now = DateTime.now();
                  final todayCount = bookings
                      .where((b) =>
                          b.status != BookingStatus.declined && _isSameDay(b.scheduledAt, now))
                      .length;
                  final weekStart = DateTime(now.year, now.month, now.day)
                      .subtract(Duration(days: now.weekday - 1));
                  final weekEnd = weekStart.add(const Duration(days: 7));
                  final weekRevenue = accepted
                      .where((b) => !b.scheduledAt.isBefore(weekStart) && b.scheduledAt.isBefore(weekEnd))
                      .fold<int>(0, (sum, b) => sum + b.hourlyRate);

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                    children: [
                      _DashboardHeader(
                        providerName: widget.providerName,
                        locationLabel: widget.locationLabel,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _StatCard(label: 'Pending', value: '${pending.length}', color: const Color(0xFFFFD5D5)),
                          const SizedBox(width: 10),
                          _StatCard(label: 'Today', value: '$todayCount', color: const Color(0xFFD6ECFC)),
                          const SizedBox(width: 10),
                          _StatCard(
                            label: 'This week',
                            value: 'Rs ${_formatShortCurrency(weekRevenue)}',
                            color: const Color(0xFFDFF0DF),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Booking requests', style: Theme.of(context).textTheme.titleLarge),
                          if (pending.isNotEmpty) _NewCountBadge(count: pending.length),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (pending.isEmpty)
                        const _EmptyBookings()
                      else
                        for (var i = 0; i < pending.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: i == 0
                                ? _UrgentBookingCard(
                                    booking: pending[i],
                                    avatarColor: _avatarPalette[i % _avatarPalette.length],
                                    isUrgent: _isUrgent(pending[i].scheduledAt),
                                  )
                                : _CompactBookingCard(
                                    booking: pending[i],
                                    avatarColor: _avatarPalette[i % _avatarPalette.length],
                                    onTap: () => _showRespondSheet(context, pending[i]),
                                  ),
                          ),

                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Today's schedule", style: Theme.of(context).textTheme.titleLarge),
                          TextButton(onPressed: () {}, child: const Text('View all')),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (accepted.isEmpty)
                        const _EmptyBookings(message: 'Accepted bookings will appear here.')
                      else
                        for (var i = 0; i < accepted.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _CompactBookingCard(
                              booking: accepted[i],
                              avatarColor: _avatarPalette[(i + 2) % _avatarPalette.length],
                            ),
                          ),
                    ],
                  );
                },
              ),
      ),
      bottomNavigationBar: NavigationBar(
        height: 64,
        selectedIndex: _selectedNavIndex,
        onDestinationSelected: (index) => setState(() => _selectedNavIndex = index),
        indicatorColor: const Color(0xFFF7C5C6),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_today_outlined), label: 'Schedule'),
          NavigationDestination(icon: Icon(Icons.chat_bubble_outline_rounded), label: 'Messages'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }

  void _showRespondSheet(BuildContext context, Booking booking) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(booking.customerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              const SizedBox(height: 4),
              Text(booking.serviceCategory, style: AppTextTheme.textTheme.bodySmall),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  _startCustomerChat(context, booking);
                },
                icon: const Icon(Icons.chat_bubble_outline_rounded),
                label: const Text('Message customer'),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        BookingRepository().setBookingStatus(booking.id, BookingStatus.declined);
                        Navigator.of(sheetContext).pop();
                      },
                      child: const Text('Decline'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        BookingRepository().setBookingStatus(booking.id, BookingStatus.accepted);
                        Navigator.of(sheetContext).pop();
                      },
                      child: const Text('Accept'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startCustomerChat(BuildContext context, Booking booking) async {
    final provider = FirebaseAuth.instance.currentUser;
    if (provider == null || booking.customerId.isEmpty) return;

    try {
      final conversationId = await ChatRepository().getOrCreateConversation(
        userAId: provider.uid,
        userAName: userDisplayName(
          displayName: provider.displayName,
          email: provider.email,
          fallback: widget.providerName,
        ),
        userARole: 'Provider',
        userBId: booking.customerId,
        userBName: booking.customerName,
        userBRole: 'Customer',
      );
      if (!context.mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            conversationId: conversationId,
            currentUserId: provider.uid,
            otherUserId: booking.customerId,
            otherUserName: booking.customerName,
            otherUserRole: 'Customer',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to start this conversation. Please try again.')),
      );
    }
  }
}

bool _isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

bool _isUrgent(DateTime scheduledAt) =>
    scheduledAt.difference(DateTime.now()) <= _urgentWindow;

String _initials(String name) => name
    .split(RegExp(r'\s+'))
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => part[0].toUpperCase())
    .join();

/// "1500" -> "1500", "16400" -> "16.4k"
String _formatShortCurrency(int amount) {
  if (amount < 1000) return '$amount';
  final thousands = amount / 1000;
  final rounded = (thousands * 10).round() / 10;
  final isWhole = rounded == rounded.roundToDouble();
  return '${isWhole ? rounded.toInt() : rounded}k';
}

String _whenLabel(BuildContext context, DateTime dt) {
  final now = DateTime.now();
  final time = MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(dt));
  if (_isSameDay(dt, now)) return 'Today at $time';
  final tomorrow = now.add(const Duration(days: 1));
  if (_isSameDay(dt, tomorrow)) return 'Tomorrow at $time';
  final date = MaterialLocalizations.of(context).formatMediumDate(dt);
  return '$date at $time';
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.providerName, required this.locationLabel});

  final String providerName;
  final String locationLabel;

  @override
  Widget build(BuildContext context) {
    final firstName = providerName.split(' ').first;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.accentRed),
                  const SizedBox(width: 3),
                  Text(locationLabel, style: AppTextTheme.textTheme.bodySmall),
                  const SizedBox(width: 6),
                  const Text('·', style: TextStyle(color: AppColors.textMuted)),
                  const SizedBox(width: 6),
                  Container(width: 6, height: 6, decoration: const BoxDecoration(color: Color(0xFF43A85F), shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  Text('Active', style: AppTextTheme.textTheme.bodySmall?.copyWith(color: const Color(0xFF287A40), fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 4),
              Text('Good morning, $firstName 👋', style: AppTextTheme.textTheme.headlineSmall),
            ],
          ),
        ),
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFF7C5C6),
          child: Text(
            _initials(providerName).isEmpty ? 'CP' : _initials(providerName),
            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textDark),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(label, style: AppTextTheme.textTheme.bodySmall),
            ],
          ),
        ),
      );
}

class _NewCountBadge extends StatelessWidget {
  const _NewCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: AppColors.accentRed, borderRadius: BorderRadius.circular(20)),
        child: Text(
          '$count new',
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
        ),
      );
}

class _UrgentBookingCard extends StatelessWidget {
  const _UrgentBookingCard({
    required this.booking,
    required this.avatarColor,
    required this.isUrgent,
  });

  final Booking booking;
  final Color avatarColor;
  final bool isUrgent;

  @override
  Widget build(BuildContext context) {
    final when = _whenLabel(context, booking.scheduledAt);
    final time = MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(booking.scheduledAt));

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isUrgent ? AppColors.accentRed.withValues(alpha: 0.35) : AppColors.borderGray),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: avatarColor, borderRadius: BorderRadius.circular(12)),
                child: Text(
                  _initials(booking.customerName).isEmpty ? 'CU' : _initials(booking.customerName),
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            booking.customerName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                        if (isUrgent) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.accentRed, borderRadius: BorderRadius.circular(20)),
                            child: const Text('URGENT', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 0.4)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${booking.serviceCategory} · $when',
                            overflow: TextOverflow.ellipsis,
                            style: AppTextTheme.textTheme.bodySmall,
                          ),
                        ),
                        if (booking.hourlyRate > 0)
                          Text(
                            'Rs ${booking.hourlyRate}',
                            style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accentRed, fontSize: 13),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(
                  icon: Icons.access_time_rounded,
                  text: booking.durationHours != null ? '$time · ${_formatDuration(booking.durationHours!)}' : time,
                ),
                if (booking.location != null && booking.location!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _DetailRow(icon: Icons.location_on_outlined, text: booking.location!),
                ],
                if (booking.hourlyRate > 0) ...[
                  const SizedBox(height: 6),
                  _DetailRow(
                    icon: Icons.payments_outlined,
                    text: booking.durationHours != null
                        ? 'Rs ${booking.hourlyRate} (${_formatDuration(booking.durationHours!)})'
                        : 'Rs ${booking.hourlyRate}',
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => BookingRepository().setBookingStatus(booking.id, BookingStatus.declined),
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.accentRed, side: const BorderSide(color: AppColors.accentRed)),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => BookingRepository().setBookingStatus(booking.id, BookingStatus.accepted),
                  child: const Text('Accept'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: AppTextTheme.textTheme.bodySmall)),
        ],
      );
}

class _CompactBookingCard extends StatelessWidget {
  const _CompactBookingCard({required this.booking, required this.avatarColor, this.onTap});

  final Booking booking;
  final Color avatarColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final when = _whenLabel(context, booking.scheduledAt);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGray),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: avatarColor, borderRadius: BorderRadius.circular(11)),
              child: Text(
                _initials(booking.customerName).isEmpty ? 'CU' : _initials(booking.customerName),
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(booking.customerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 2),
                  Text('${booking.serviceCategory} · $when', style: AppTextTheme.textTheme.bodySmall),
                ],
              ),
            ),
            if (booking.hourlyRate > 0)
              Text('Rs ${booking.hourlyRate}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.accentRed)),
          ],
        ),
      ),
    );
  }
}

String _formatDuration(double hours) {
  final isWhole = hours == hours.roundToDouble();
  final value = isWhole ? hours.toInt().toString() : hours.toString();
  return '$value ${hours == 1 ? 'hr' : 'hrs'}';
}

class _EmptyBookings extends StatelessWidget {
  const _EmptyBookings({this.message = 'No booking requests yet.'});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
        child: Text(message),
      );
}
