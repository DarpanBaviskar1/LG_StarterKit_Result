import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'dart:async';
import '../domain/models/waypoint.dart';

class GeminiService {
  final Dio _dio;
  final String apiKey;

  GeminiService({required this.apiKey}) : _dio = Dio();

  Future<List<Waypoint>> generateTourSuggestions(String prompt) async {
    const maxRetries = 3;
    int retryCount = 0;

    while (retryCount < maxRetries) {
      try {
        const endpoint =
            'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

        final response = await _dio.post(
          '$endpoint?key=$apiKey',
          options: Options(contentType: 'application/json'),
          data: {
            'contents': [
              {
                'parts': [
                  {
                    'text': _buildPrompt(prompt),
                  }
                ]
              }
            ],
            'generationConfig': {
              'responseMimeType': 'application/json',
              'temperature': 0.7,
              'topK': 40,
              'topP': 0.95,
              'maxOutputTokens': 2048,
            },
          },
        );

        if (response.statusCode == 200) {
          final text =
              response.data['candidates'][0]['content']['parts'][0]['text']
                  as String;
          return _parseWaypoints(text);
        } else {
          throw Exception('Gemini API error: ${response.statusCode}');
        }
      } on DioException catch (e) {
        // Handle 429 (Too Many Requests) with retry logic
        if (e.response?.statusCode == 429) {
          retryCount++;
          if (retryCount >= maxRetries) {
            throw Exception(
              'API rate limit exceeded. Please wait a moment and try again.',
            );
          }

          // Exponential backoff: 2s, 4s, 8s
          final waitDuration = Duration(seconds: 2 * retryCount);
          debugPrint(
              'Rate limited. Retrying in ${waitDuration.inSeconds}s (attempt $retryCount/$maxRetries)');
          await Future.delayed(waitDuration);
          continue;
        }

        // Other errors
        throw Exception('Gemini API error: ${e.message}');
      } catch (e) {
        debugPrint('Gemini error: $e');
        rethrow;
      }
    }

    throw Exception('Failed to generate tour after $maxRetries attempts');
  }

  String _buildPrompt(String userPrompt) {
    return '''
Generate a tour with 3-5 waypoints for: "$userPrompt"

Return ONLY a JSON array with this exact format (no markdown, no extra text):
[
  {"name": "Location 1", "description": "Brief description", "latitude": 40.7128, "longitude": -74.0060, "duration": 5},
  {"name": "Location 2", "description": "Brief description", "latitude": 48.8566, "longitude": 2.3522, "duration": 5}
]

Requirements:
- Use real geographic coordinates
- latitude must be between -90 and 90
- longitude must be between -180 and 180
- durations are in seconds (3-10 recommended)
- descriptions should be 1-2 sentences
- Return valid JSON only
''';
  }

  List<Waypoint> _parseWaypoints(String jsonText) {
    try {
      // Extract JSON from response (in case there's extra text)
      final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(jsonText);
      if (jsonMatch == null) {
        throw Exception('No JSON array found in response');
      }

      final jsonString = jsonMatch.group(0)!;
      final parsed = jsonDecode(jsonString) as List;

      return parsed.asMap().entries.map((entry) {
        final data = entry.value as Map<String, dynamic>;
        final latitude = _parseDouble(data['latitude']);
        final longitude = _parseDouble(data['longitude']);
        final duration = _parseInt(data['duration']) ?? 5;
        final fixed = _sanitizeCoordinates(latitude, longitude);
        return Waypoint(
          id: 'wp_${entry.key}',
          name: data['name'] as String,
          description: data['description'] as String,
          latitude: fixed.latitude,
          longitude: fixed.longitude,
          durationSeconds: duration,
          order: entry.key,
        );
      }).toList();
    } catch (e) {
      debugPrint('Parse error: $e, raw: $jsonText');
      rethrow;
    }
  }

  double _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.parse(value.trim());
    }
    throw Exception('Invalid number: $value');
  }

  int? _parseInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.round();
    }
    if (value is String) {
      return int.tryParse(value.trim()) ?? double.tryParse(value.trim())?.round();
    }
    return null;
  }

  ({double latitude, double longitude}) _sanitizeCoordinates(
    double latitude,
    double longitude,
  ) {
    final latValid = latitude >= -90 && latitude <= 90;
    final lonValid = longitude >= -180 && longitude <= 180;

    if (!latValid && lonValid && longitude >= -90 && longitude <= 90) {
      // Gemini occasionally swaps lat/lon, fix when it is obvious.
      return (latitude: longitude, longitude: latitude);
    }

    if (!latValid || !lonValid) {
      throw Exception('Out of range coordinates: $latitude,$longitude');
    }

    return (latitude: latitude, longitude: longitude);
  }
}
