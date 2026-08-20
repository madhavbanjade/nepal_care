import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nepal_care/models/provider_prrofile.dart';
import 'package:nepal_care/repositories/booking_repository.dart';

class BookingRequestDialog extends StatefulWidget {
  const BookingRequestDialog({super.key, required this.provider});
  final ProviderProfile provider;

  @override
  State<BookingRequestDialog> createState() => _BookingRequestDialogState();
}

class _BookingRequestDialogState extends State<BookingRequestDialog> {
  final _repository = BookingRepository();
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 10, minute: 0);
  bool _submitting = false;

  Future<void> _pickDate() async {
    final value = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)));
    if (value != null) setState(() => _date = value);
  }

  Future<void> _pickTime() async {
    final value = await showTimePicker(context: context, initialTime: _time);
    if (value != null) setState(() => _time = value);
  }

  Future<void> _submit() async {
    final customer = FirebaseAuth.instance.currentUser;
    if (customer == null) {
      _showMessage('Please log in before booking a provider.');
      return;
    }
    setState(() => _submitting = true);
    try {
      await _repository.createBooking(
        provider: widget.provider,
        customerId: customer.uid,
        customerName: customer.displayName ?? customer.email?.split('@').first ?? 'Customer',
        scheduledAt: DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking request sent to the provider.')));
    } catch (error) {
      _showMessage(error is StateError ? error.message : 'Could not send the booking request.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showMessage(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text('Book ${widget.provider.fullName}'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.calendar_today_outlined), title: const Text('Date'), subtitle: Text(MaterialLocalizations.of(context).formatMediumDate(_date)), onTap: _pickDate),
          ListTile(contentPadding: EdgeInsets.zero, leading: const Icon(Icons.access_time_rounded), title: const Text('Time'), subtitle: Text(_time.format(context)), onTap: _pickTime),
          Padding(padding: const EdgeInsets.only(top: 8), child: Text(widget.provider.hourlyRate > 0 ? 'Rate: Rs ${widget.provider.hourlyRate} / hour' : 'Rate will be confirmed by the provider.')),
        ]),
        actions: [
          TextButton(onPressed: _submitting ? null : () => Navigator.of(context).pop(), child: const Text('Cancel')),
          FilledButton(onPressed: _submitting ? null : _submit, child: Text(_submitting ? 'Sending...' : 'Send request')),
        ],
      );
}
