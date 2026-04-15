class PaymentModel {
  final String id;
  final String bookingId;
  final String method;
  final String status;
  final double amount;
  final DateTime? paidAt;

  PaymentModel({
    required this.id,
    required this.bookingId,
    required this.method,
    required this.status,
    required this.amount,
    this.paidAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: json['id'],
      bookingId: json['booking_id'],
      method: json['method'],
      status: json['status'],
      amount: (json['amount'] as num).toDouble(),
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'booking_id': bookingId,
      'method': method,
      'status': status,
      'amount': amount,
      'paid_at': paidAt?.toIso8601String(),
    };
  }
}