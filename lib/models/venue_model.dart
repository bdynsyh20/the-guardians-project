class VenueModel {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? openHours;

  VenueModel({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.openHours,
  });

  factory VenueModel.fromJson(Map<String, dynamic> json) {
    return VenueModel(
      id: json['id'],
      name: json['name'],
      address: json['address'],
      phone: json['phone'],
      openHours: json['open_hours'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'phone': phone,
      'open_hours': openHours,
    };
  }
}