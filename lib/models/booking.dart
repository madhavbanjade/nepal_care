import 'package:cloud_firestore/cloud_firestore.dart';

enum BookingStatus { pending, accepted, declined }

extension BookingStatusValue on BookingStatus {
  String get value => name;
}

class Booking {
  const Booking({
    required this.id,
    required this.providerId,
    required this.providerName,
    required this.customerId,
    required this.customerName,
    required this.serviceCategory,
    required this.scheduledAt,
    required this.hourlyRate,
    required this.status,
  });

  final String id;
  final String providerId;
  final String providerName;
  final String customerId;
  final String customerName;
  final String serviceCategory;
  final DateTime scheduledAt;
  final int hourlyRate;
  final BookingStatus status;

  factory Booking.fromDocument(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data()!;
    return Booking(
      id: document.id,
      providerId: data['providerId'] as String? ?? '',
      providerName: data['providerName'] as String? ?? 'Care provider',
      customerId: data['customerId'] as String? ?? '',
      customerName: data['customerName'] as String? ?? 'Customer',
      serviceCategory: data['serviceCategory'] as String? ?? 'Care service',
      scheduledAt: (data['scheduledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      hourlyRate: (data['hourlyRate'] as num?)?.toInt() ?? 0,
      status: BookingStatus.values.firstWhere(
        (status) => status.value == data['status'],
        orElse: () => BookingStatus.pending,
      ),
    );
  }
}
