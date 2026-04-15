class ProfileModel {
  final String id;
  final String name;
  final String? phone;
  final String role;
  final DateTime createdAt;

  ProfileModel({
    required this.id,
    required this.name,
    this.phone,
    required this.role,
    required this.createdAt,
  });

  // Mengubah data JSON dari Supabase menjadi objek ProfileModel
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'],
      name: json['name'],
      phone: json['phone'],
      role: json['role'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  // Mengubah objek ProfileModel menjadi JSON untuk dikirim ke Supabase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'role': role,
      'created_at': createdAt.toIso8601String(),
    };
  }
}