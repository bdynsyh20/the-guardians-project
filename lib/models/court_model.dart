class CourtModel {
  final String id;
  final String venueId;
  final String name;
  final String sportType;
  final String? description;
  final bool isActive;

  CourtModel({
    required this.id,
    required this.venueId,
    required this.name,
    required this.sportType,
    this.description,
    required this.isActive,
  });

  factory CourtModel.fromJson(Map<String, dynamic> json) {
    return CourtModel(
      id: json['id'],
      venueId: json['venue_id'],
      name: json['name'],
      sportType: json['sport_type'],
      description: json['description'],
      isActive: json['is_active'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'venue_id': venueId,
      'name': name,
      'sport_type': sportType,
      'description': description,
      'is_active': isActive,
    };
  }
}