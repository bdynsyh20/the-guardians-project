class BookingModel {
  final String id;
  final String userId;
  final String courtId;
  final String slotId;
  final DateTime bookingDate;
  final String status;
  final double totalPrice;
  final DateTime createdAt;

  // Data join dari tabel lain
  final String? courtName;
  final String? sportType;
  final String? startTime;
  final String? endTime;

  // Data payment
  final String? paymentStatus;
  final String? paymentMethod;
  final String? paymentProof;

  BookingModel({
    required this.id,
    required this.userId,
    required this.courtId,
    required this.slotId,
    required this.bookingDate,
    required this.status,
    required this.totalPrice,
    required this.createdAt,
    this.courtName,
    this.sportType,
    this.startTime,
    this.endTime,
    this.paymentStatus,
    this.paymentMethod,
    this.paymentProof,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final payment = json['payments'];
    Map<String, dynamic>? paymentData;

    if (payment is List && payment.isNotEmpty) {
      paymentData = payment[0] as Map<String, dynamic>;
    } else if (payment is Map<String, dynamic>) {
      paymentData = payment;
    }

    return BookingModel(
      id: json['id'],
      userId: json['user_id'],
      courtId: json['court_id'],
      slotId: json['slot_id'],
      bookingDate: DateTime.parse(json['booking_date']),
      status: json['status'],
      totalPrice: (json['total_price'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at']),
      courtName: json['courts'] != null ? json['courts']['name'] : null,
      sportType: json['courts'] != null ? json['courts']['sport_type'] : null,
      startTime: json['time_slots'] != null ? json['time_slots']['start_time'] : null,
      endTime: json['time_slots'] != null ? json['time_slots']['end_time'] : null,
      paymentStatus: paymentData?['status'],
      paymentMethod: paymentData?['payment_method_detail'],
      paymentProof: paymentData?['payment_proof'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'court_id': courtId,
      'slot_id': slotId,
      'booking_date': bookingDate.toIso8601String(),
      'status': status,
      'total_price': totalPrice,
      'created_at': createdAt.toIso8601String(),
    };
  }
}