import 'waypoint.dart';

class Tour {
  final String id;
  final String name;
  final String description;
  final List<Waypoint> waypoints;
  final DateTime createdAt;
  final DateTime updatedAt;

  Tour({
    required this.id,
    required this.name,
    required this.description,
    required this.waypoints,
    required this.createdAt,
    required this.updatedAt,
  });

  int get totalDurationSeconds =>
      waypoints.fold(0, (sum, wp) => sum + wp.durationSeconds);

  Tour copyWith({
    String? id,
    String? name,
    String? description,
    List<Waypoint>? waypoints,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Tour(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      waypoints: waypoints ?? this.waypoints,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'waypoints': waypoints.map((w) => w.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Tour.fromJson(Map<String, dynamic> json) => Tour(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        waypoints: (json['waypoints'] as List)
            .map((w) => Waypoint.fromJson(w as Map<String, dynamic>))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
