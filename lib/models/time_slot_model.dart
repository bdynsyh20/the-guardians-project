class TimeSlotModel {
  final String id;
  final String courtId;
  final String startTime;
  final String endTime;
  final double price;
  final bool isAvailable;
  final String dayType; // tambah ini

  TimeSlotModel({
    required this.id,
    required this.courtId,
    required this.startTime,
    required this.endTime,
    required this.price,
    required this.isAvailable,
    required this.dayType, // tambah ini
  });

  factory TimeSlotModel.fromJson(Map<String, dynamic> json) {
    return TimeSlotModel(
      id: json['id'],
      courtId: json['court_id'],
      startTime: json['start_time'],
      endTime: json['end_time'],
      price: (json['price'] as num).toDouble(),
      isAvailable: json['is_available'],
      dayType: json['day_type'] ?? 'weekday', // tambah ini
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'court_id': courtId,
      'start_time': startTime,
      'end_time': endTime,
      'price': price,
      'is_available': isAvailable,
      'day_type': dayType, // tambah ini
    };
  }
}