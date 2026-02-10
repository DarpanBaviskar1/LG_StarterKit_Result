/// KML Builder for Liquid Galaxy
///
/// Generates valid KML files for LG commands.
/// Always validate coordinates before generating KML.
///
/// Example:
/// ```dart
/// final kml = KMLBuilder.buildFlyTo(
///   latitude: 40.6892,
///   longitude: -74.0445,
///   altitude: 0,
/// );
/// ```
class KMLBuilder {
  /// Build FlyTo command for simple navigation
  ///
  /// Parameters:
  /// - latitude: -90 to 90
  /// - longitude: -180 to 180
  /// - altitude: height above sea level
  /// - heading: camera direction (0-360)
  /// - tilt: camera angle (0-90, 45 is good default)
  /// - range: zoom distance in meters
  static String buildFlyTo({
    required double latitude,
    required double longitude,
    required double altitude,
    double heading = 0,
    double tilt = 45,
    double range = 5000,
  }) {
    _validateCoordinates(latitude, longitude);

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <LookAt>
      <longitude>$longitude</longitude>
      <latitude>$latitude</latitude>
      <altitude>$altitude</altitude>
      <heading>$heading</heading>
      <tilt>$tilt</tilt>
      <range>$range</range>
    </LookAt>
  </Document>
</kml>''';
  }

  /// Build FlyTo with animation duration
  ///
  /// duration: animation time in seconds
  static String buildFlyToWithDuration({
    required double latitude,
    required double longitude,
    required double altitude,
    double heading = 0,
    double tilt = 45,
    double range = 5000,
    double duration = 3.0,
  }) {
    _validateCoordinates(latitude, longitude);

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2"
     xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <gx:Tour>
      <name>Fly</name>
      <gx:Playlist>
        <gx:FlyTo>
          <gx:duration>${duration.toStringAsFixed(1)}</gx:duration>
          <Camera>
            <longitude>$longitude</longitude>
            <latitude>$latitude</latitude>
            <altitude>$altitude</altitude>
            <heading>$heading</heading>
            <tilt>$tilt</tilt>
            <roll>0</roll>
          </Camera>
        </gx:FlyTo>
      </gx:Playlist>
    </gx:Tour>
  </Document>
</kml>''';
  }

  /// Build Placemark (point on map)
  ///
  /// Creates a marked point at coordinates with description
  static String buildPlacemark({
    required String name,
    required double latitude,
    required double longitude,
    String? description,
    String? color,
  }) {
    _validateCoordinates(latitude, longitude);

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <Placemark>
      <name>$name</name>
      ${description != null ? '<description><![CDATA[$description]]></description>' : ''}
      <Point>
        <coordinates>$longitude,$latitude,0</coordinates>
      </Point>
    </Placemark>
  </Document>
</kml>''';
  }

  /// Build Tour with multiple points
  ///
  /// points: list of (name, lat, lng, duration) tuples
  static String buildTour({
    required List<(String, double, double, double)> points,
  }) {
    for (var (_, lat, lng, _) in points) {
      _validateCoordinates(lat, lng);
    }

    final playlist = points
        .map((p) => '''<gx:FlyTo>
          <gx:duration>${p.$4.toStringAsFixed(1)}</gx:duration>
          <Camera>
            <longitude>${p.$3}</longitude>
            <latitude>${p.$2}</latitude>
            <altitude>0</altitude>
            <heading>0</heading>
            <tilt>45</tilt>
            <roll>0</roll>
          </Camera>
        </gx:FlyTo>''')
        .join('\n        ');

    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2"
     xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <gx:Tour>
      <name>Tour</name>
      <gx:Playlist>
        $playlist
      </gx:Playlist>
    </gx:Tour>
  </Document>
</kml>''';
  }

  /// Validate latitude and longitude
  static void _validateCoordinates(double latitude, double longitude) {
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError('Latitude must be between -90 and 90');
    }
    if (longitude < -180 || longitude > 180) {
      throw ArgumentError('Longitude must be between -180 and 180');
    }
  }

  /// Escape special XML characters
  static String escapeXML(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
