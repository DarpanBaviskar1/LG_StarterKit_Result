class Waypoint {
  final String id;
  final double latitude;
  final double longitude;
  final String name;
  final String description;
  final int durationSeconds;
  final int order;

  Waypoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.description,
    this.durationSeconds = 5,
    required this.order,
  });

  Waypoint copyWith({
    String? id,
    double? latitude,
    double? longitude,
    String? name,
    String? description,
    int? durationSeconds,
    int? order,
  }) {
    return Waypoint(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      name: name ?? this.name,
      description: description ?? this.description,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'name': name,
        'description': description,
        'durationSeconds': durationSeconds,
        'order': order,
      };

  factory Waypoint.fromJson(Map<String, dynamic> json) => Waypoint(
        id: json['id'] as String,
        latitude: json['latitude'] as double,
        longitude: json['longitude'] as double,
        name: json['name'] as String,
        description: json['description'] as String,
        durationSeconds: json['durationSeconds'] as int? ?? 5,
        order: json['order'] as int,
      );
}
