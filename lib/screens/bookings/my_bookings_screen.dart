import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nepal_care/core/theme/app_colors.dart';
import 'package:nepal_care/core/theme/app_text_theme.dart';
import 'package:nepal_care/models/booking.dart';
import 'package:nepal_care/repositories/booking_repository.dart';

const _avatarPalette = <Color>[
  Color(0xFFF7C5C6),
  Color(0xFFC8EAF8),
  Color(0xFFDFF0DF),
  Color(0xFFFFE7A8),
  Color(0xFFD9D7E8),
];

class MyBookingsScreen extends StatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  State<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends State<MyBookingsScreen> {
  final _repository = BookingRepository();
  bool _showUpcoming = true;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in to see your bookings.')));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Text('My Bookings', style: AppTextTheme.textTheme.headlineSmall),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _TabToggle(
                showUpcoming: _showUpcoming,
                onChanged: (value) => setState(() => _showUpcoming = value),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<List<Booking>>(
                stream: _repository.streamCustomerBookings(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Unable to load your bookings.'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final now = DateTime.now();
                  final all = snapshot.data!;
                  final upcoming = all
                      .where((b) =>
                          b.status != BookingStatus.declined &&
                          b.status != BookingStatus.cancelled &&
                          !b.scheduledAt.isBefore(now))
                      .toList()
                    ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
                  final past = all
                      .where((b) =>
                          b.scheduledAt.isBefore(now) ||
                          b.status == BookingStatus.declined ||
                          b.status == BookingStatus.cancelled)
                      .toList()
                    ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

                  final visible = _showUpcoming ? upcoming : past;

                  if (visible.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          _showUpcoming ? 'No upcoming bookings yet.' : 'No past bookings.',
                          style: AppTextTheme.textTheme.bodyMedium,
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) => _BookingCard(
                      booking: visible[index],
                      avatarColor: _avatarPalette[index % _avatarPalette.length],
                      onCancel: _showUpcoming &&
                              (visible[index].status == BookingStatus.pending ||
                                  visible[index].status == BookingStatus.accepted)
                          ? () => _confirmCancel(context, visible[index])
                          : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmCancel(BuildContext context, Booking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cancel this booking?'),
        content: Text('Your booking with ${booking.providerName} will be cancelled.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Keep booking')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.accentRed),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cancel booking'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _repository.cancelBooking(booking.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not cancel the booking. Please try again.')),
      );
    }
  }
}

class _TabToggle extends StatelessWidget {
  const _TabToggle({required this.showUpcoming, required this.onChanged});

  final bool showUpcoming;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Expanded(child: _Segment(label: 'Upcoming', selected: showUpcoming, onTap: () => onChanged(true))),
            Expanded(child: _Segment(label: 'Past', selected: !showUpcoming, onTap: () => onChanged(false))),
          ],
        ),
      );
}

class _Segment extends StatelessWidget {
  const _Segment({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected ? const [BoxShadow(color: Color(0x14000000), blurRadius: 6)] : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: selected ? AppColors.textDark : AppColors.textMuted,
            ),
          ),
        ),
      );
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking, required this.avatarColor, this.onCancel});

  final Booking booking;
  final Color avatarColor;
  final VoidCallback? onCancel;

  String get _initials => booking.providerName
      .split(RegExp(r'\s+'))
      .where((name) => name.isNotEmpty)
      .take(2)
      .map((name) => name[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    final date = MaterialLocalizations.of(context).formatMediumDate(booking.scheduledAt);
    final startTime = MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(booking.scheduledAt));
    final endsAt = booking.endsAt;
    final timeLabel = endsAt != null
        ? '$startTime – ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(endsAt))}'
        : startTime;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEEEEE)),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: avatarColor, borderRadius: BorderRadius.circular(12)),
                child: Text(_initials.isEmpty ? 'CP' : _initials, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(booking.providerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(booking.serviceCategory, style: AppTextTheme.textTheme.bodySmall),
                  ],
                ),
              ),
              _StatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text(date, style: AppTextTheme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.access_time_rounded, size: 13, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text(timeLabel, style: AppTextTheme.textTheme.bodySmall),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (booking.hourlyRate > 0)
                Expanded(
                  child: Text(
                    'Rs ${booking.hourlyRate}',
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.accentRed),
                  ),
                )
              else
                const Spacer(),
              if (onCancel != null) ...[
                OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentRed,
                    side: const BorderSide(color: AppColors.accentRed),
                    minimumSize: const Size(0, 34),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
              ],
              FilledButton(
                onPressed: () => _showDetails(context),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                child: const Text('View'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        final date = MaterialLocalizations.of(sheetContext).formatMediumDate(booking.scheduledAt);
        final startTime = MaterialLocalizations.of(sheetContext).formatTimeOfDay(TimeOfDay.fromDateTime(booking.scheduledAt));
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(booking.providerName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17))),
                    _StatusBadge(status: booking.status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(booking.serviceCategory, style: AppTextTheme.textTheme.bodyMedium),
                const Divider(height: 28),
                _DetailLine(icon: Icons.calendar_today_outlined, text: date),
                const SizedBox(height: 8),
                _DetailLine(icon: Icons.access_time_rounded, text: startTime),
                if (booking.location != null && booking.location!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _DetailLine(icon: Icons.location_on_outlined, text: booking.location!),
                ],
                if (booking.hourlyRate > 0) ...[
                  const SizedBox(height: 8),
                  _DetailLine(icon: Icons.payments_outlined, text: 'Rs ${booking.hourlyRate}'),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: AppTextTheme.textTheme.bodyMedium)),
        ],
      );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final BookingStatus status;

  (String, Color, Color) get _display => switch (status) {
        BookingStatus.accepted => ('Confirmed', const Color(0xFFE2F5E6), const Color(0xFF287A40)),
        BookingStatus.pending => ('Pending', const Color(0xFFD6ECFC), const Color(0xFF1E6FA8)),
        BookingStatus.declined => ('Declined', const Color(0xFFFFE1E1), AppColors.accentRed),
        BookingStatus.cancelled => ('Cancelled', const Color(0xFFEFEFEF), AppColors.textMuted),
      };

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = _display;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}