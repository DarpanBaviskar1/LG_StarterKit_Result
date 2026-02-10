import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:xml/xml.dart' as xml;
import '../domain/models/tour.dart';
import '../domain/models/waypoint.dart';

class TourService {
  final SharedPreferences _prefs;

  TourService(this._prefs);

  static const _tourKey = 'tours';

  Future<List<Tour>> getAllTours() async {
    try {
      final json = _prefs.getString(_tourKey) ?? '[]';
      final parsed = jsonDecode(json) as List;
      return parsed
          .map((t) => Tour.fromJson(t as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading tours: $e');
      return [];
    }
  }

  Future<void> saveTour(Tour tour) async {
    try {
      final tours = await getAllTours();
      final index = tours.indexWhere((t) => t.id == tour.id);

      if (index >= 0) {
        tours[index] = tour;
      } else {
        tours.add(tour);
      }

      final json = jsonEncode(tours.map((t) => t.toJson()).toList());
      await _prefs.setString(_tourKey, json);
    } catch (e) {
      debugPrint('Error saving tour: $e');
      rethrow;
    }
  }

  Future<void> deleteTour(String tourId) async {
    try {
      final tours = await getAllTours();
      tours.removeWhere((t) => t.id == tourId);

      final json = jsonEncode(tours.map((t) => t.toJson()).toList());
      await _prefs.setString(_tourKey, json);
    } catch (e) {
      debugPrint('Error deleting tour: $e');
      rethrow;
    }
  }

  String generateKML(Tour tour) {
    final waypoints = [...tour.waypoints]
      ..sort((a, b) => a.order.compareTo(b.order));
    if (waypoints.isEmpty) {
      throw Exception('Tour has no waypoints');
    }

    const tourAltitudeMeters = 1000;
    const tourTilt = 45;
    const tourHeading = 0;
    const flyToSeconds = 3;

    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln(
        '<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">');
    buffer.writeln('<Document>');
    buffer.writeln('<name>${_escapeXml(tour.name)}</name>');
    buffer.writeln('<description>${_escapeXml(tour.description)}</description>');

    buffer.writeln('<Folder>');
    buffer.writeln('<name>Waypoints</name>');

    for (final wp in waypoints) {
      buffer.writeln('<Placemark>');
      buffer.writeln('<name>${_escapeXml(wp.name)}</name>');
      buffer.writeln('<description>${_escapeXml(wp.description)}</description>');
      buffer.writeln('<Point>');
      buffer
          .writeln('<coordinates>${wp.longitude},${wp.latitude},0</coordinates>');
      buffer.writeln('</Point>');
      buffer.writeln('</Placemark>');
    }

    buffer.writeln('</Folder>');

    buffer.writeln('<gx:Tour>');
    buffer.writeln('<name>${_escapeXml(tour.name)}</name>');
    buffer.writeln('<gx:Playlist>');

    for (final wp in waypoints) {
      final holdSeconds = wp.durationSeconds < 1 ? 1 : wp.durationSeconds;

      buffer.writeln('<gx:FlyTo>');
      buffer.writeln('<gx:duration>$flyToSeconds</gx:duration>');
      buffer.writeln('<gx:flyToMode>smooth</gx:flyToMode>');
      buffer.writeln('<Camera>');
      buffer.writeln('<longitude>${wp.longitude}</longitude>');
      buffer.writeln('<latitude>${wp.latitude}</latitude>');
      buffer.writeln('<altitude>$tourAltitudeMeters</altitude>');
      buffer.writeln('<heading>$tourHeading</heading>');
      buffer.writeln('<tilt>$tourTilt</tilt>');
      buffer.writeln('<roll>0</roll>');
      buffer.writeln('<altitudeMode>relativeToGround</altitudeMode>');
      buffer.writeln('</Camera>');
      buffer.writeln('</gx:FlyTo>');

      buffer.writeln('<gx:Wait>');
      buffer.writeln('<gx:duration>$holdSeconds</gx:duration>');
      buffer.writeln('</gx:Wait>');
    }

    buffer.writeln('</gx:Playlist>');
    buffer.writeln('</gx:Tour>');

    buffer.writeln('</Document>');
    buffer.writeln('</kml>');

    return buffer.toString();
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  List<Waypoint> parseKML(String kmlString) {
    try {
      final document = xml.XmlDocument.parse(kmlString);
      final waypoints = <Waypoint>[];
      int order = 0;

      // Find all Placemark elements
      final placemarks = document.findAllElements('Placemark');

      for (final placemark in placemarks) {
        final nameElement = placemark.findElements('name').firstOrNull;
        final descElement = placemark.findElements('description').firstOrNull;
        final pointElement = placemark.findElements('Point').firstOrNull;
        final coordElement = pointElement?.findElements('coordinates').firstOrNull;

        if (coordElement != null) {
          final coordText = coordElement.innerText.trim();
          // KML format: longitude,latitude,altitude
          final parts = coordText.split(',');
          if (parts.length >= 2) {
            try {
              final longitude = double.parse(parts[0].trim());
              final latitude = double.parse(parts[1].trim());

              waypoints.add(Waypoint(
                id: 'kml_wp_$order',
                name: nameElement?.innerText ?? 'Waypoint ${order + 1}',
                description: descElement?.innerText ?? '',
                latitude: latitude,
                longitude: longitude,
                durationSeconds: 5,
                order: order,
              ));
              order++;
            } catch (e) {
              debugPrint('Error parsing coordinate: $e');
            }
          }
        }
      }

      if (waypoints.isEmpty) {
        throw Exception('No waypoints found in KML');
      }

      return waypoints;
    } catch (e) {
      debugPrint('KML parse error: $e');
      rethrow;
    }
  }
}
