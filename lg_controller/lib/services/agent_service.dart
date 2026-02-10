import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class AgentService {
  // Use 10.0.2.2 for Android emulator (maps to host's localhost)
  // Use localhost for web/desktop
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else if (Platform.isIOS) {
      return 'http://localhost:8000';
    } else {
      return 'http://localhost:8000';
    }
  }

  /// Generate KML from natural language prompt using Gemini API via Python backend.
  /// 
  /// Returns the KML string directly ready to send to Liquid Galaxy.
  /// Throws exception if API call fails.
  Future<String> generateKmlFromPrompt(String userPrompt) async {
    if (userPrompt.trim().isEmpty) {
      throw Exception('Prompt cannot be empty');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate-kml'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'query': userPrompt}),
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception(
            'Request timed out. Make sure Flask server is running on port 8000',
          );
        },
      );

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final kml = data['kml'] as String?;
          
          if (kml == null || kml.isEmpty) {
            throw Exception('No KML returned from server');
          }
          
          debugPrint('✓ KML generated (${kml.length} chars)');
          return kml;
        } catch (e) {
          throw Exception('Failed to parse response: $e');
        }
      } else if (response.statusCode == 500) {
        try {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final error = data['error'] as String?;
          throw Exception('Server error: ${error ?? response.body}');
        } catch (_) {
          throw Exception('Server error (500): ${response.body}');
        }
      }

      throw Exception(
        'Server error (${response.statusCode}): ${response.body}',
      );
    } on SocketException catch (e) {
      throw Exception(
        'Connection error: Cannot reach server at $baseUrl. '
        'Make sure Flask server is running. Details: $e',
      );
    } on http.ClientException catch (e) {
      throw Exception(
        'Connection error: $e. Is Flask server running at $baseUrl?',
      );
    } on TimeoutException catch (e) {
      throw Exception(
        'Request timed out after 60 seconds. Server may be overloaded. $e',
      );
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to generate KML: $e');
    }
  }

  /// Check if the agent server is reachable
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Health check failed: $e');
      return false;
    }
  }

  /// Validate KML format
  Future<bool> validateKml(String kml) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/validate-kml'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'kml': kml}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return data['valid'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('KML validation failed: $e');
      return false;
    }
  }
}
