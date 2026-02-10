# 🔧 Service Layer Pattern

## Overview

The service layer encapsulates business logic and external communication, keeping UI components clean and focused on presentation.

---

## Why Service Layer?

### Without Service Layer (❌ Bad)
```dart
class MyScreen extends StatefulWidget {
  Future<void> _loadData() async {
    // Business logic mixed with UI
    final response = await http.get(Uri.parse('https://api.com/data'));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      // Parse and transform data...
      setState(() {
        data = transformed;
      });
    }
  }
}
```

**Problems:**
- UI class knows about HTTP details
- Hard to test (no mocking)
- Can't reuse logic in other screens
- Difficult to maintain

### With Service Layer (✅ Good)
```dart
// Service (testable, reusable)
class MyService {
  Future<List<MyModel>> fetchData() async {
    final response = await http.get(Uri.parse('$_baseUrl/data'));
    if (response.statusCode == 200) {
      return parseData(response.body);
    }
    throw Exception('Failed to load');
  }
}

// UI (clean, focused)
class MyScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(myServiceProvider);
    // Use service.fetchData()
  }
}
```

**Benefits:**
- ✅ Separation of concerns
- ✅ Easy to test
- ✅ Reusable across features
- ✅ Single responsibility principle

---

## Service Types in LG Controller

### 1. HTTP API Services (`lib/services/`)

**Purpose:** Communicate with external HTTP APIs

**Location:** `lib/services/`

**Examples:**
- `agent_service.dart` - Flask/Gemini AI
- `nominatim_service.dart` - OpenStreetMap geocoding
- `weather_service.dart` - Open-Meteo weather
- `earthquake_service.dart` - USGS earthquakes

**Pattern:**
```dart
class MyApiService {
  // Base URL constant
  static const String _baseUrl = 'https://api.example.com';
  
  // Public methods
  Future<List<MyModel>> fetchData() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/endpoint'),
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parse Data(data);
      }
      
      throw Exception('HTTP ${response.statusCode}');
    } catch (e) {
      throw Exception('Failed to fetch: $e');
    }
  }
  
  // Private helper methods
  List<MyModel> _parseData(dynamic json) {
    return (json as List)
        .map((item) => MyModel.fromJson(item))
        .toList();
  }
}
```

### 2. SSH Services (`lib/src/features/home/data/`)

**Purpose:** Core infrastructure for Liquid Galaxy communication

**Location:** `lib/src/features/home/data/`

**Examples:**
- `ssh_service.dart` - Low-level SSH connection
- `lg_service.dart` - LG control commands
- `kml_service.dart` - KML file management

**Pattern:**
```dart
class LgService {
  final SshService _sshService;
  
  LgService(this._sshService);
  
  Future<void> relaunch({required int rigs, required String password}) async {
    for (int i = 1; i <= rigs; i++) {
      final screenNum = (i == 1) ? '' : '_$i';
      final command = 'echo "$password" | sudo -S exportLAYER="earth" '
          'exportSCREEN=$screenNum /home/lg/bin/lg-relaunch';
      await _sshService.client!.run(command);
    }
  }
}
```

**Why separate from HTTP services?**
- SSH services are core to the entire app (every feature needs them)
- HTTP services are feature-specific (only used by certain features)
- Different lifecycle management
- Different error handling strategies

---

## Service Creation Template

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for [Purpose Description]
/// Uses [API Name] - Free/Paid, Auth Required: Yes/No
class MyService {
  // Base URL
  static const String _baseUrl = 'https://api.example.com/v1';
  
  // Optional: Headers
  static const Map<String, String> _headers = {
    'User-Agent': 'LG-Controller/1.0',
    'Accept': 'application/json',
  };
 
  /// Fetch [resource] from API
  /// Returns: List of [ModelName]
  /// Throws: Exception if request fails
  Future<List<MyModel>> fetchResource({
    required String query,
    int limit = 10,
  }) async {
    try {
      // Build URI with query parameters
      final uri = Uri.parse('$_baseUrl/endpoint').replace(queryParameters: {
        'q': query,
        'limit': limit.toString(),
      });
      
      // Make HTTP request with timeout
      final response = await http.get(uri, headers: _headers)
          .timeout(const Duration(seconds: 15));
      
      // Check status code
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _parseResponse(data);
      }
      
      // Handle specific status codes
      if (response.statusCode == 404) {
        return []; // Empty list for not found
      }
      
      throw Exception('API returned ${response.statusCode}');
      
    } on FormatException {
      throw Exception('Invalid JSON response');
    } on TimeoutException {
      throw Exception('Request timed out');
    } catch (e) {
      throw Exception('Failed to fetch resource: $e');
    }
  }
  
  /// Parse API response into models
  List<MyModel> _parseResponse(dynamic json) {
    if (json is List) {
      return json
          .map((item) => MyModel.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    
    if (json is Map && json.containsKey('results')) {
      return (json['results'] as List)
          .map((item) => MyModel.fromJson(item))
          .toList();
    }
    
    throw FormatException('Unexpected JSON structure');
  }
}

/// Model class
class MyModel {
  final String id;
  final String name;
  final double value;
  
  MyModel({
    required this.id,
    required this.name,
    required this.value,
  });
  
  factory MyModel.fromJson(Map<String, dynamic> json) {
    return MyModel(
      id: json['id'] as String,
      name: json['name'] as String,
      value: (json['value'] as num).toDouble(),
    );
  }
  
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'value': value,
  };
}
```

---

## Provider Integration

### Step 1: Define Provider

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final myServiceProvider = Provider<MyService>((ref) {
  return MyService();
});
```

### Step 2: Use in Widget

```dart
class MyScreen extends ConsumerStatefulWidget {
  const MyScreen({super.key});
  
  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  List<MyModel> _data = [];
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final service = ref.read(myServiceProvider);
      final data = await service.fetchResource(query: 'example');
      
      setState(() {
        _data = data;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return ListView.builder(
      itemCount: _data.length,
      itemBuilder: (context, index) {
        final item = _data[index];
        return ListTile(
          title: Text(item.name),
          subtitle: Text(item.value.toString()),
        );
      },
    );
  }
}
```

---

## Best Practices

### 1. Error Handling

```dart
// ✅ GOOD: Specific error types
try {
  await service.fetchData();
} on TimeoutException {
  // Handle timeout
} on FormatException {
  // Handle JSON parsing errors
} on SocketException {
  // Handle network errors
} catch (e) {
  // Handle unknown errors
}

// ❌ BAD: Generic catch-all
try {
  await service.fetchData();
} catch (e) {
  // What kind of error? Unknown!
}
```

### 2. Timeouts

```dart
// ✅ GOOD: Always set timeouts
final response = await http.get(uri)
    .timeout(const Duration(seconds: 15));

// ❌ BAD: No timeout (can hang forever)
final response = await http.get(uri);
```

### 3. Null Safety

```dart
// ✅ GOOD: Handle missing fields
factory MyModel.fromJson(Map<String, dynamic> json) {
  return MyModel(
    id: json['id'] as String? ?? 'unknown',
    name: json['name'] as String? ?? 'Unknown',
    value: (json['value'] as num?)?.toDouble() ?? 0.0,
  );
}

// ❌ BAD: Assume fields exist
factory MyModel.fromJson(Map<String, dynamic> json) {
  return MyModel(
    id: json['id'],  // Crashes if missing!
    name: json['name'],
    value: json['value'].toDouble(),
  );
}
```

### 4. Logging

```dart
import 'package:flutter/foundation.dart';

Future<List<MyModel>> fetchData() async {
  debugPrint('MyService: Fetching data...');
  
  try {
    final response = await http.get(uri);
    debugPrint('MyService: Response ${response.statusCode}');
    
    final data = _parseResponse(response.body);
    debugPrint('MyService: Parsed ${data.length} items');
    
    return data;
  } catch (e) {
    debugPrint('MyService: Error - $e');
    rethrow;
  }
}
```

### 5. Caching (Optional)

```dart
class MyService {
  final Map<String, List<MyModel>> _cache = {};
  
  Future<List<MyModel>> fetchData(String query) async {
    // Check cache first
    if (_cache.containsKey(query)) {
      debugPrint('Returning cached data for $query');
      return _cache[query]!;
    }
    
    // Fetch from API
    final data = await _fetchFromApi(query);
    
    // Cache result
    _cache[query] = data;
    
    return data;
  }
  
  void clearCache() => _cache.clear();
}
```

---

## Real-World Examples

### Example 1: Nominatim Service (Geocoding)

```dart
class NominatimService {
  static const String _baseUrl = 'https://nominatim.openstreetmap.org';
  
  Future<List<LocationResult>> searchLocation(String query) async {
    final uri = Uri.parse('$_baseUrl/search').replace(queryParameters: {
      'q': query,
      'format': 'json',
      'limit': '10',
    });
    
    final response = await http.get(
      uri,
      headers: {'User-Agent': 'LG-Controller/1.0'},
    ).timeout(const Duration(seconds: 10));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((item) => LocationResult.fromJson(item)).toList();
    }
    
    throw Exception('Geocoding failed');
  }
}
```

### Example 2: Weather Service (No Auth)

```dart
class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1';
  
  Future<CurrentWeather> getCurrentWeather(double lat, double lng) async {
    final uri = Uri.parse('$_baseUrl/forecast').replace(queryParameters: {
      'latitude': lat.toString(),
      'longitude': lng.toString(),
      'current_weather': 'true',
    });
    
    final response = await http.get(uri)
        .timeout(const Duration(seconds: 15));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return CurrentWeather.fromJson(data['current_weather']);
    }
    
    throw Exception('Weather fetch failed');
  }
}
```

### Example 3: Agent Service (With Auth)

```dart
class AgentService {
  static String get baseUrl {
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000'; // Android emulator
    }
    return 'http://localhost:8000';   // iOS/Web
  }
  
  Future<String> generateKmlFromPrompt(String prompt) async {
    final response = await http.post(
      Uri.parse('$baseUrl/generate-kml'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'query': prompt}),
    ).timeout(const Duration(seconds: 60));
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['kml'] as String;
    }
    
    throw Exception('KML generation failed');
  }
}
```

---

## Testing Services

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('MyService', () {
    test('fetches data successfully', () async {
      // Mock HTTP client
      final client = MockClient((request) async {
        return http.Response(
          '{"results": [{"id": "1", "name": "Test"}]}',
          200,
        );
      });
      
      final service = MyService(client: client);
      final result = await service.fetchData();
      
      expect(result, hasLength(1));
      expect(result[0].name, 'Test');
    });
    
    test('handles error responses', () async {
      final client = MockClient((request) async {
        return http.Response('Not Found', 404);
      });
      
      final service = MyService(client: client);
      
      expect(
        () => service.fetchData(),
        throwsA(isA<Exception>()),
      );
    });
  });
}
```

---

## Quick Reference

| Task | Code |
|------|------|
| Create service | `class MyService { }` |
| Make HTTP GET | `http.get(Uri.parse(url)).timeout(...)` |
| Make HTTP POST | `http.post(uri, body: json, headers: ...).timeout(...)` |
| Parse JSON | `jsonDecode(response.body)` |
| Create model | `MyModel.fromJson(json)` |
| Define provider | `final provider = Provider((ref) => MyService())` |
| Use in widget | `ref.read(myServiceProvider)` |
| Handle errors | `try-catch with specific exceptions` |
| Add logging | `debugPrint('Message')` |

---

**See also:**
- [ssh-patterns.md](ssh-patterns.md) for SSH service patterns
- [Templates](../5-templates/flutter/) for copy-paste code
- [ARCHITECTURE.md](../1-foundations/ARCHITECTURE.md) for system overview

**Last Updated:** 2026-02-10
