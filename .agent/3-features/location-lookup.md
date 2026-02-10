# 📍 Location Lookup Feature (Nominatim Integration)

## Overview

The Location Lookup feature allows users to search for any location worldwide using the OpenStreetMap Nominatim geocoding API. Users can search by address, city, landmark, or coordinates, view detailed location information, and send the location directly to Liquid Galaxy.

**Service File:** `lib/services/nominatim_service.dart`
**UI Screen:** `lib/src/features/location_lookup/presentation/location_lookup_screen.dart`
**Dashboard:** Accessible via "Location Lookup" card

---

## Key Features

1. **Free Geocoding** - No API key required
2. **Global Coverage** - Worldwide location database
3. **Search by Address** - Street address, city, country
4. **Detailed Results** - Display name, coordinates, type
5. **Fly To Location** - Send to Liquid Galaxy instantly
6. **Export to KML** - Generate KML files for locations

---

## API Integration

### API Provider
**Nominatim** by OpenStreetMap Foundation
- **Base URL:** `https://nominatim.openstreetmap.org`
- **Documentation:** https://nominatim.org/release-docs/latest/api/Overview/
- **License:** ODbL (Open Database License)
- **Cost:** FREE (no API key required)
- **Rate Limit:** 1 request per second (enforced by User-Agent)

### Endpoints Used

#### 1. Search Endpoint
```
GET https://nominatim.openstreetmap.org/search
```

**Query Parameters:**
- `q` (string, required): Search query (e.g., "Berlin", "Eiffel Tower")
- `format` (string): Response format (use "json")
- `addressdetails` (int): Include address breakdown (0 or 1)
- `limit` (int): Max number of results (default: 10, max: 50)

**Example Request:**
```
https://nominatim.openstreetmap.org/search?q=Berlin&format=json&addressdetails=1&limit=10
```

**Example Response:**
```json
[
  {
    "place_id": 285277248,
    "licence": "Data © OpenStreetMap contributors, ODbL 1.0",
    "osm_type": "relation",
    "osm_id": 62422,
    "boundingbox": ["52.3382448", "52.6755087", "13.0883450", "13.7611609"],
    "lat": "52.5170365",
    "lon": "13.3888599",
    "display_name": "Berlin, Germany",
    "class": "place",
    "type": "city",
    "importance": 0.9654895080477081,
    "icon": "https://nominatim.openstreetmap.org/ui/mapicons/poi_place_city.p.20.png",
    "address": {
      "city": "Berlin",
      "state": "Berlin",
      "ISO3166-2-lvl4": "DE-BE",
      "country": "Germany",
      "country_code": "de"
    }
  }
]
```

### Rate Limiting Requirements

**CRITICAL:** Nominatim requires a User-Agent header identifying your application.

**Correct Implementation:**
```dart
final response = await http.get(
  uri,
  headers: {
    'User-Agent': 'LGController/1.0 (your-email@example.com)',
  },
).timeout(const Duration(seconds: 15));
```

**Without User-Agent:** Requests will be blocked (403 Forbidden)

**Rate Limit:** Maximum 1 request per second
- For bulk searches, add delays between requests
- Consider caching results

---

## Service Implementation

### File Structure
```
lib/services/nominatim_service.dart (87 lines)
```

### Core Methods

#### 1. `searchLocation(String query)`
Searches for locations matching the query string.

**Parameters:**
- `query` (String): Search term (e.g., "Paris", "1600 Pennsylvania Ave")

**Returns:** `Future<List<LocationResult>>`

**Example Usage:**
```dart
final service = NominatimService();
final results = await service.searchLocation('Tokyo');

for (final result in results) {
  print('${result.displayName}: ${result.lat}, ${result.lng}');
}
```

**Error Handling:**
```dart
try {
  final results = await service.searchLocation(query);
  if (results.isEmpty) {
    // No results found
  }
} on TimeoutException {
  // Request timed out
} on SocketException {
  // No internet connection
} catch (e) {
  // Other errors
}
```

### Data Models

#### `LocationResult` Class
```dart
class LocationResult {
  final String displayName;  // Full formatted address
  final double lat;          // Latitude (-90 to 90)
  final double lng;          // Longitude (-180 to 180)
  final String type;         // Place type (city, building, etc.)
  final String? placeId;     // Unique identifier (optional)
  
  LocationResult({
    required this.displayName,
    required this.lat,
    required this.lng,
    required this.type,
    this.placeId,
  });
  
  factory LocationResult.fromJson(Map<String, dynamic> json) {
    return LocationResult(
      displayName: json['display_name'] as String,
      lat: double.parse(json['lat'] as String),
      lng: double.parse(json['lon'] as String),
      type: json['type'] as String,
      placeId: json['place_id']?.toString(),
    );
  }
}
```

**Field Details:**
- `displayName`: Human-readable address (e.g., "Berlin, Germany")
- `lat/lng`: Coordinates in decimal degrees format
- `type`: Classification (city, town, village, building, road, etc.)
- `placeId`: OSM place identifier for detailed lookups

### Service Code Template
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class NominatimService {
  static const String _baseUrl = 'nominatim.openstreetmap.org';
  
  Future<List<LocationResult>> searchLocation(String query) async {
    if (query.isEmpty) {
      return [];
    }
    
    try {
      final uri = Uri.https(_baseUrl, '/search', {
        'q': query,
        'format': 'json',
        'addressdetails': '1',
        'limit': '10',
      });
      
      final response = await http.get(
        uri,
        headers: {
          'User-Agent': 'LGController/1.0',
        },
      ).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => LocationResult.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search location: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Nominatim error: $e');
      rethrow;
    }
  }
}
```

---

## UI Implementation

### Screen File
`lib/src/features/location_lookup/presentation/location_lookup_screen.dart` (280 lines)

### UI Components

#### 1. Search Bar
```dart
TextField(
  controller: _searchController,
  decoration: InputDecoration(
    hintText: 'Search for a location...',
    prefixIcon: const Icon(Icons.search),
    suffixIcon: IconButton(
      icon: const Icon(Icons.clear),
      onPressed: () => _searchController.clear(),
    ),
  ),
  onSubmitted: (value) => _searchLocation(),
)
```

#### 2. Results List
```dart
ListView.builder(
  itemCount: _results.length,
  itemBuilder: (context, index) {
    final result = _results[index];
    return Card(
      child: ListTile(
        leading: Icon(_getIconForType(result.type)),
        title: Text(result.displayName),
        subtitle: Text('${result.lat}, ${result.lng}'),
        trailing: IconButton(
          icon: const Icon(Icons.map),
          onPressed: () => _flyToLocation(result),
        ),
      ),
    );
  },
)
```

#### 3. Loading State
```dart
if (_isLoading)
  const Center(
    child: CircularProgressIndicator(),
  )
```

#### 4. Empty State
```dart
if (_results.isEmpty && !_isLoading)
  const Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text('Search for any location worldwide'),
      ],
    ),
  )
```

### State Management

#### State Variables
```dart
class _LocationLookupScreenState extends ConsumerState<LocationLookupScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<LocationResult> _results = [];
  bool _isLoading = false;
}
```

#### Search Method
```dart
Future<void> _searchLocation() async {
  final query = _searchController.text.trim();
  if (query.isEmpty) return;
  
  setState(() {
    _isLoading = true;
  });
  
  try {
    final service = ref.read(nominatimServiceProvider);
    final results = await service.searchLocation(query);
    
    setState(() {
      _results = results;
      _isLoading = false;
    });
    
    if (results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No locations found'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  } catch (e) {
    setState(() {
      _isLoading = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

---

## KML Generation

### Basic Location Placemark

```dart
String _generateLocationKML(LocationResult location) {
  final buffer = StringBuffer();
  
  buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
  buffer.writeln('<Document>');
  buffer.writeln('  <name>Location: ${location.displayName}</name>');
  buffer.writeln('  <Placemark>');
  buffer.writeln('    <name>${_escapeXml(location.displayName)}</name>');
  buffer.writeln('    <Point>');
  buffer.writeln('      <coordinates>${location.lng},${location.lat},0</coordinates>');
  buffer.writeln('    </Point>');
  buffer.writeln('  </Placemark>');
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
```

### Fly-To Animation

```dart
Future<void> _flyToLocation(LocationResult location) async {
  try {
    // Generate FlyTo KML
    final kml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" 
     xmlns:gx="http://www.google.com/kml/ext/2.2">
<gx:Tour>
  <name>Fly to ${location.displayName}</name>
  <gx:Playlist>
    <gx:FlyTo>
      <gx:duration>3</gx:duration>
      <gx:flyToMode>smooth</gx:flyToMode>
      <LookAt>
        <longitude>${location.lng}</longitude>
        <latitude>${location.lat}</latitude>
        <altitude>0</altitude>
        <heading>0</heading>
        <tilt>45</tilt>
        <range>5000</range>
        <gx:altitudeMode>relativeToGround</gx:altitudeMode>
      </LookAt>
    </gx:FlyTo>
  </gx:Playlist>
</gx:Tour>
</kml>''';
    
    // Send to LG
    final sshService = ref.read(sshServiceProvider);
    await sshService.sendKml(kml, targetFile: 'master.kml');
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Flying to ${location.displayName}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    debugPrint('❌ Fly-to error: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
```

### Multiple Locations KML

```dart
String generateMultiLocationKML(List<LocationResult> locations) {
  final buffer = StringBuffer();
  
  buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
  buffer.writeln('<Document>');
  buffer.writeln('  <name>Search Results</name>');
  
  for (int i = 0; i < locations.length; i++) {
    final loc = locations[i];
    buffer.writeln('  <Placemark>');
    buffer.writeln('    <name>${_escapeXml(loc.displayName)}</name>');
    buffer.writeln('    <description>Result ${i + 1}</description>');
    buffer.writeln('    <Point>');
    buffer.writeln('      <coordinates>${loc.lng},${loc.lat},0</coordinates>');
    buffer.writeln('    </Point>');
    buffer.writeln('  </Placemark>');
  }
  
  buffer.writeln('</Document>');
  buffer.writeln('</kml>');
  
  return buffer.toString();
}
```

---

## Usage Examples

### Example 1: Simple Search
```dart
// In your widget
final service = ref.read(nominatimServiceProvider);
final results = await service.searchLocation('Paris');

if (results.isNotEmpty) {
  final paris = results.first;
  print('Found: ${paris.displayName}');
  print('Coordinates: ${paris.lat}, ${paris.lng}');
}
```

### Example 2: Search with Error Handling
```dart
Future<void> searchAndDisplay(String query) async {
  try {
    final service = ref.read(nominatimServiceProvider);
    final results = await service.searchLocation(query);
    
    if (results.isEmpty) {
      showSnackBar('No results found for "$query"');
      return;
    }
    
    setState(() {
      _results = results;
    });
  } on TimeoutException {
    showSnackBar('Request timed out. Check your internet connection.');
  } on SocketException {
    showSnackBar('No internet connection.');
  } catch (e) {
    showSnackBar('Error: $e');
  }
}
```

### Example 3: Fly to First Result
```dart
Future<void> searchAndFly(String query) async {
  final service = ref.read(nominatimServiceProvider);
  final results = await service.searchLocation(query);
  
  if (results.isEmpty) {
    return;
  }
  
  final location = results.first;
  final kml = _generateFlyToKML(location);
  
  final sshService = ref.read(sshServiceProvider);
  await sshService.sendKml(kml, targetFile: 'master.kml');
}
```

---

## Testing

### Manual Testing Checklist

**Basic Functionality:**
- [ ] Search for city (e.g., "Tokyo")
- [ ] Search for address (e.g., "1600 Pennsylvania Ave")
- [ ] Search for landmark (e.g., "Eiffel Tower")
- [ ] Search for coordinates (e.g., "40.7128, -74.0060")
- [ ] Verify results display with correct info
- [ ] Test fly-to button on result
- [ ] Verify LG displays location

**Edge Cases:**
- [ ] Empty search query
- [ ] No results found (gibberish query)
- [ ] Very long location names
- [ ] Special characters in query
- [ ] Multiple results returned
- [ ] Rapid repeated searches

**Error Handling:**
- [ ] No internet connection
- [ ] API timeout (simulate slow network)
- [ ] Invalid API response
- [ ] LG not connected (fly-to fails)

### Unit Test Example
```dart
void main() {
  group('NominatimService', () {
    late NominatimService service;
    
    setUp(() {
      service = NominatimService();
    });
    
    test('searches for location successfully', () async {
      final results = await service.searchLocation('Berlin');
      
      expect(results, isNotEmpty);
      expect(results.first.displayName, contains('Berlin'));
      expect(results.first.lat, greaterThan(50.0));
      expect(results.first.lat, lessThan(55.0));
    });
    
    test('returns empty list for invalid query', () async {
      final results = await service.searchLocation('xyzabc123invalid');
      
      expect(results, isEmpty);
    });
  });
}
```

---

## Common Issues & Solutions

### Issue 1: 403 Forbidden Error
**Symptom:** All requests return 403
**Cause:** Missing User-Agent header
**Solution:** Add User-Agent to all requests (see Rate Limiting Requirements above)

### Issue 2: Empty Results
**Symptom:** API returns 200 but empty array
**Cause:** Query too specific or location doesn't exist
**Solution:** 
- Broaden search query
- Check spelling
- Try alternative names

### Issue 3: Coordinates Are Strings
**Symptom:** Type error when parsing lat/lng
**Cause:** Nominatim returns coordinates as strings, not numbers
**Solution:** Use `double.parse()` in `fromJson()`
```dart
lat: double.parse(json['lat'] as String),
lng: double.parse(json['lon'] as String),
```

### Issue 4: Display Names Too Long
**Symptom:** UI overflows with long addresses
**Solution:** Use `Text` with `overflow: TextOverflow.ellipsis`
```dart
Text(
  location.displayName,
  overflow: TextOverflow.ellipsis,
  maxLines: 2,
)
```

---

## Future Enhancements

- [ ] **Reverse Geocoding:** Convert coordinates → address
- [ ] **Search History:** Save recent searches
- [ ] **Favorites:** Bookmark frequent locations
- [ ] **Nearby Places:** Find POIs near a location
- [ ] **Batch Search:** Import CSV of locations
- [ ] **Custom Markers:** Different icons per location type
- [ ] **Detailed View:** Show full address breakdown
- [ ] **Offline Mode:** Cache results for offline access

---

## References

- **Nominatim API Docs:** https://nominatim.org/release-docs/latest/api/
- **OSM Wiki:** https://wiki.openstreetmap.org/wiki/Nominatim
- **Usage Policy:** https://operations.osmfoundation.org/policies/nominatim/
- **Service Status:** https://status.openstreetmap.org/

---

**See also:**
- [weather-overlay.md](weather-overlay.md) - Weather integration
- [earthquake-tracker.md](earthquake-tracker.md) - Earthquake data
- [2-patterns/service-layer.md](../2-patterns/service-layer.md) - Service patterns
- [8-troubleshooting/api-errors.md](../8-troubleshooting/api-errors.md) - API debugging

**Last Updated:** 2026-02-10
