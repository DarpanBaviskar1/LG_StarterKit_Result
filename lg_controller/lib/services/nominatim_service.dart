import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Nominatim Geocoding Service
/// FREE API for converting location names to coordinates and vice versa
class NominatimService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  static const String _userAgent = 'LGController/1.0';

  /// Search for location by name (Forward Geocoding)
  /// Returns list of matching locations with coordinates
  Future<List<LocationResult>> searchLocation(String locationName) async {
    if (locationName.trim().isEmpty) {
      throw Exception('Location name cannot be empty');
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/search')
            .replace(queryParameters: {
          'q': locationName,
          'format': 'json',
          'limit': '10',
        }),
        headers: {'User-Agent': _userAgent},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data
            .map((item) => LocationResult.fromJson(item))
            .toList();
      }

      throw Exception('Failed to search location: ${response.statusCode}');
    } catch (e) {
      throw Exception('Location search failed: $e');
    }
  }

  /// Get address from coordinates (Reverse Geocoding)
  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/reverse')
            .replace(queryParameters: {
          'lat': lat.toString(),
          'lon': lng.toString(),
          'format': 'json',
        }),
        headers: {'User-Agent': _userAgent},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['address'] ?? 'Unknown location';
      }

      throw Exception('Failed to get address');
    } catch (e) {
      throw Exception('Reverse geocoding failed: $e');
    }
  }

  /// Get nearby POIs (Points of Interest)
  Future<List<POI>> getNearbyPOIs(double lat, double lng, {int radiusKm = 1}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/reverse')
            .replace(queryParameters: {
          'lat': lat.toString(),
          'lon': lng.toString(),
          'format': 'json',
          'zoom': '18',
          'addressdetails': '1',
        }),
        headers: {'User-Agent': _userAgent},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] as Map<String, dynamic>;
        
        return [
          POI(
            name: address['name'] ?? 'Location',
            type: address['amenity'] ?? address['building'] ?? 'landmark',
            lat: lat,
            lng: lng,
          ),
        ];
      }

      return [];
    } catch (e) {
      debugPrint('POI search failed: $e');
      return [];
    }
  }
}

/// Location Result Model
class LocationResult {
  final String name;
  final double lat;
  final double lng;
  final String displayName;
  final String? type;

  LocationResult({
    required this.name,
    required this.lat,
    required this.lng,
    required this.displayName,
    this.type,
  });

  factory LocationResult.fromJson(Map<String, dynamic> json) {
    return LocationResult(
      name: json['name'] ?? '',
      lat: double.parse(json['lat'].toString()),
      lng: double.parse(json['lon'].toString()),
      displayName: json['display_name'] ?? '',
      type: json['type'],
    );
  }

  @override
  String toString() => '$name ($lat, $lng)';
}

/// Point of Interest Model
class POI {
  final String name;
  final String type;
  final double lat;
  final double lng;

  POI({
    required this.name,
    required this.type,
    required this.lat,
    required this.lng,
  });
}
