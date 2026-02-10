import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// USGS Earthquake Hazards Program Service
/// 100% FREE - Real-time earthquake data
class EarthquakeService {
  static const String _baseUrl = 'https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary';

  /// Get recent earthquakes (all magnitudes from past month)
  Future<List<Earthquake>> getRecentEarthquakes({int hours = 168}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/all_month.geojson'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final features = data['features'] as List<dynamic>;
        
        return features
            .map((feature) => Earthquake.fromGeoJson(feature))
            .toList();
      }

      throw Exception('Failed to fetch earthquakes: ${response.statusCode}');
    } catch (e) {
      throw Exception('Earthquake fetch failed: $e');
    }
  }

  /// Get earthquakes above minimum magnitude
  Future<List<Earthquake>> getEarthquakesByMagnitude({double minMagnitude = 4.5}) async {
    try {
      String summaryType = 'all_month';
      
      if (minMagnitude >= 7.0) {
        summaryType = 'significant_month';
      } else if (minMagnitude >= 6.0) {
        summaryType = '6.5_month';
      } else if (minMagnitude >= 5.5) {
        summaryType = '5.5_month';
      } else if (minMagnitude >= 4.5) {
        summaryType = '4.5_week';
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/$summaryType.geojson'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final features = data['features'] as List<dynamic>;
        
        List<Earthquake> quakes = features
            .map((feature) => Earthquake.fromGeoJson(feature))
            .toList();
        
        // Filter by magnitude and sort by magnitude descending
        return quakes
            .where((q) => q.magnitude >= minMagnitude)
            .toList()
          ..sort((a, b) => b.magnitude.compareTo(a.magnitude));
      }

      throw Exception('Failed to fetch earthquakes');
    } catch (e) {
      throw Exception('Magnitude filter failed: $e');
    }
  }

  /// Get earthquakes near a specific location
  Future<List<Earthquake>> getEarthquakesNearLocation(
    double lat,
    double lng, {
    double radiusKm = 500,
  }) async {
    try {
      final quakes = await getRecentEarthquakes();
      
      List<Earthquake> nearby = [];
      for (var quake in quakes) {
        final distance = _calculateDistance(lat, lng, quake.lat, quake.lng);
        if (distance < radiusKm) {
          nearby.add(quake);
        }
      }
      
      return nearby..sort((a, b) => b.magnitude.compareTo(a.magnitude));
    } catch (e) {
      throw Exception('Nearby earthquake search failed: $e');
    }
  }

  /// Calculate distance between two coordinates using Haversine formula
  static double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const R = 6371; // Earth radius in km
    final dLat = _toRad(lat2 - lat1);
    final dLng = _toRad(lng2 - lng1);
    final a = (sin(dLat / 2) * sin(dLat / 2)) +
        cos(_toRad(lat1)) *
            cos(_toRad(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  static double _toRad(double degree) => degree * pi / 180;
}

/// Earthquake Model
class Earthquake {
  final String id;
  final double magnitude;
  final double lat;
  final double lng;
  final double depth;
  final DateTime time;
  final String place;
  final String? tsunami;

  Earthquake({
    required this.id,
    required this.magnitude,
    required this.lat,
    required this.lng,
    required this.depth,
    required this.time,
    required this.place,
    this.tsunami,
  });

  /// Get earthquake severity level
  String get severity {
    if (magnitude >= 8.0) return '🟣 Major';
    if (magnitude >= 7.0) return '🔴 Strong';
    if (magnitude >= 6.0) return '🟠 Moderate';
    if (magnitude >= 5.0) return '🟡 Moderate';
    if (magnitude >= 4.0) return '🟢 Light';
    return '⚪ Minor';
  }

  /// Check if tsunami warning exists
  bool hasTsunamiWarning() => tsunami?.toLowerCase() == 'true';

  /// Format for display
  String get displayText =>
      'M$magnitude - $place (${time.toString().split('.')[0]})';

  factory Earthquake.fromGeoJson(Map<String, dynamic> json) {
    final props = json['properties'] as Map<String, dynamic>;
    final geom = json['geometry'] as Map<String, dynamic>;
    final coords = geom['coordinates'] as List<dynamic>;

    // Handle tsunami - USGS returns as int (0/1) or string
    String? tsunamiValue;
    final tsunamiProp = props['tsunami'];
    if (tsunamiProp != null) {
      if (tsunamiProp is int) {
        tsunamiValue = tsunamiProp == 1 ? 'true' : 'false';
      } else if (tsunamiProp is String) {
        tsunamiValue = tsunamiProp;
      }
    }

    return Earthquake(
      id: json['id'] ?? '',
      magnitude: (props['mag'] as num?)?.toDouble() ?? 0.0,
      lat: (coords[1] as num).toDouble(),
      lng: (coords[0] as num).toDouble(),
      depth: coords.length > 2 ? (coords[2] as num).toDouble() : 0.0,
      time: DateTime.fromMillisecondsSinceEpoch(props['time'] as int),
      place: props['place'] ?? 'Unknown location',
      tsunami: tsunamiValue,
    );
  }

  @override
  String toString() => displayText;
}
