import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nepal_care/models/booking.dart';
import 'package:nepal_care/models/provider_prrofile.dart';

class BookingRepository {
  BookingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _bookings =>
      _firestore.collection('bookings');

  /// The deterministic id prevents two customers booking the same provider for
  /// the exact time slot. A declined request releases that slot for rebooking.
  Future<void> createBooking({
    required ProviderProfile provider,
    required String customerId,
    required String customerName,
    required DateTime scheduledAt,
  }) async {
    if (provider.uid.isEmpty) throw StateError('Provider information is incomplete.');
    final slot = DateTime(scheduledAt.year, scheduledAt.month, scheduledAt.day,
        scheduledAt.hour, scheduledAt.minute);
    final reference = _bookings.doc('${provider.uid}_${slot.millisecondsSinceEpoch}');

    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      final status = existing.data()?['status'] as String?;
      if (existing.exists &&
          (status == BookingStatus.pending.value || status == BookingStatus.accepted.value)) {
        throw StateError('This provider already has a booking request for that time.');
      }
      transaction.set(reference, {
        'providerId': provider.uid,
        'providerName': provider.fullName,
        'customerId': customerId,
        'customerName': customerName,
        'serviceCategory': provider.serviceCategory,
        'hourlyRate': provider.hourlyRate,
        'scheduledAt': Timestamp.fromDate(slot),
        'status': BookingStatus.pending.value,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Stream<List<Booking>> streamProviderBookings(String providerId) => _bookings
      .where('providerId', isEqualTo: providerId)
      .snapshots()
      .map((snapshot) {
        final bookings = snapshot.docs.map(Booking.fromDocument).toList();
        bookings.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        return bookings;
      });

  /// Powers "My Bookings" — every booking a customer has ever made, both
  /// tabs (Upcoming/Past) are filtered client-side off this single stream.
  Stream<List<Booking>> streamCustomerBookings(String customerId) => _bookings
      .where('customerId', isEqualTo: customerId)
      .snapshots()
      .map((snapshot) {
        final bookings = snapshot.docs.map(Booking.fromDocument).toList();
        bookings.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        return bookings;
      });

  Future<void> setBookingStatus(String bookingId, BookingStatus status) =>
      _bookings.doc(bookingId).update({'status': status.value});

  /// Customer-initiated cancel. NOTE: requires the Firestore rule addition
  /// that allows the *customer* (not just the provider) to move a booking's
  /// status — the current rules only let the assigned provider update
  /// status. See the updated firestore.rules shared alongside this file.
  Future<void> cancelBooking(String bookingId) =>
      _bookings.doc(bookingId).update({'status': BookingStatus.cancelled.value});
}