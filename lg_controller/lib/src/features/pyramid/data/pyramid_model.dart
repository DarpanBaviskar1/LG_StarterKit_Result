/// Model for pyramid configuration
class PyramidConfig {
  final double latitude;
  final double longitude;
  final double altitude;
  final double baseSize;
  final String color; // AABBGGRR format
  final String name;

  const PyramidConfig({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    this.baseSize = 0.01,
    this.color = 'ff0000ff', // Default: Blue
    this.name = 'Colored Pyramid',
  });

  /// Predefined color presets (AABBGGRR format)
  static const Map<String, String> colorPresets = {
    'Red': 'ff0000ff',
    'Green': 'ff00ff00',
    'Blue': 'ffff0000',
    'Yellow': 'ff00ffff',
    'Magenta': 'ffff00ff',
    'Cyan': 'ffffff00',
    'White': 'ffffffff',
    'Black': 'ff000000',
  };

  /// Common location presets (latitude, longitude, altitude, name)
  static const Map<String, (double, double, double, String)> locationPresets = {
    'New York': (40.7128, -74.0060, 2000, 'NYC Pyramid'),
    'London': (51.5074, -0.1278, 1500, 'London Pyramid'),
    'Paris': (48.8566, 2.3522, 1500, 'Paris Pyramid'),
    'Tokyo': (35.6762, 139.6503, 2000, 'Tokyo Pyramid'),
    'Sydney': (-33.8688, 151.2093, 1500, 'Sydney Pyramid'),
  };

  PyramidConfig copyWith({
    double? latitude,
    double? longitude,
    double? altitude,
    double? baseSize,
    String? color,
    String? name,
  }) {
    return PyramidConfig(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      baseSize: baseSize ?? this.baseSize,
      color: color ?? this.color,
      name: name ?? this.name,
    );
  }

  @override
  String toString() => 'PyramidConfig(lat: $latitude, lon: $longitude, alt: $altitude, size: $baseSize, color: $color, name: $name)';
}
