# 🌍 Earthquake Tracker Feature (USGS Integration)

## Overview

The Earthquake Tracker feature displays real-time earthquake data from the USGS (United States Geological Survey) API. Users can filter earthquakes by magnitude, view detailed information including location, depth, and tsunami warnings, and visualize up to 50 earthquakes on Liquid Galaxy.

**Service File:** `lib/services/usgs_service.dart`
**UI Screen:** `lib/src/features/earthquake_tracker/presentation/earthquake_tracker_screen.dart`  
**Dashboard:** Accessible via "Earthquake Tracker" card

---

## Key Features

1. **Real-Time Data** - Live earthquake feeds from USGS
2. **Magnitude Filtering** - M1.0+, M2.5+, M4.5+, or All earthquakes
3. **Severity Classification** - Color-coded by magnitude (Minor → Major)
4. **Tsunami Warnings** - Highlight earthquakes with tsunami risk
5. **Global Coverage** - Worldwide earthquake monitoring
6. **Time Ranges** - Past hour, day, week, or month
7. **KML Visualization** - Display up to 50 earthquakes on LG
8. **Free API** - No API key required

---

## API Integration

### API Provider
**USGS Earthquake Hazards Program**
- **Base URL:** `https://earthquake.usgs.gov`
- **Documentation:** https://earthquake.usgs.gov/earthquakes/feed/v1.0/geojson.php
- **License:** Public domain (US Government data)
- **Cost:** FREE (no API key required)
- **Rate Limit:** No published limit, but be respectful
- **Update Frequency:** Every 1-5 minutes

### Data Feeds

USGS provides pre-filtered GeoJSON feeds:

#### Magnitude + Time Combinations

| Feed | URL Endpoint | Description |
|------|-------------|-------------|
| **Significant (All Time)** | `/earthquakes/feed/v1.0/summary/significant_month.geojson` | Major earthquakes, past month |
| **M4.5+ (Past Week)** | `/earthquakes/feed/v1.0/summary/4.5_week.geojson` | M4.5+, past 7 days |
| **M4.5+ (Past Month)** | `/earthquakes/feed/v1.0/summary/4.5_month.geojson` | M4.5+, past 30 days |
| **M2.5+ (Past Day)** | `/earthquakes/feed/v1.0/summary/2.5_day.geojson` | M2.5+, past 24 hours |
| **M2.5+ (Past Week)** | `/earthquakes/feed/v1.0/summary/2.5_week.geojson` | M2.5+, past 7 days |
| **M1.0+ (Past Hour)** | `/earthquakes/feed/v1.0/summary/1.0_hour.geojson` | M1.0+, past hour |
| **M1.0+ (Past Day)** | `/earthquakes/feed/v1.0/summary/1.0_day.geojson` | M1.0+, past 24 hours |
| **All (Past Hour)** | `/earthquakes/feed/v1.0/summary/all_hour.geojson` | All magnitudes, past hour |
| **All (Past Day)** | `/earthquakes/feed/v1.0/summary/all_day.geojson` | All magnitudes, past 24 hours |

### GeoJSON Response Structure

**Format:** GeoJSON FeatureCollection

**Example Response:**
```json
{
  "type": "FeatureCollection",
  "metadata": {
    "generated": 1707579600000,
    "url": "https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/4.5_week.geojson",
    "title": "USGS Magnitude 4.5+ Earthquakes, Past Week",
    "status": 200,
    "api": "1.10.3",
    "count": 87
  },
  "features": [
    {
      "type": "Feature",
      "properties": {
        "mag": 5.2,
        "place": "53 km SW of Hualien City, Taiwan",
        "time": 1707575423000,
        "updated": 1707576123000,
        "tz": null,
        "url": "https://earthquake.usgs.gov/earthquakes/eventpage/us7000m123",
        "detail": "https://earthquake.usgs.gov/fdsnws/event/1/query?eventid=us7000m123&format=geojson",
        "felt": 234,
        "cdi": 6.3,
        "mmi": null,
        "alert": null,
        "status": "reviewed",
        "tsunami": 1,
        "sig": 432,
        "net": "us",
        "code": "7000m123",
        "ids": ",us7000m123,",
        "sources": ",us,",
        "types": ",origin,phase-data,",
        "nst": 87,
        "dmin": 0.567,
        "rms": 0.89,
        "gap": 23,
        "magType": "mb",
        "type": "earthquake",
        "title": "M 5.2 - 53 km SW of Hualien City, Taiwan"
      },
      "geometry": {
        "type": "Point",
        "coordinates": [121.2345, 23.5678, 15.23]
      },
      "id": "us7000m123"
    }
  ],
  "bbox": [-180.0, -90.0, -10.0, 180.0, 90.0, 700.0]
}
```

### Key Properties

**From `properties` object:**
- `mag` (float): Magnitude (Richter scale)
- `place` (string): Human-readable location description
- `time` (long): Unix timestamp in milliseconds
- `tsunami` (int): 0 = no, 1 = yes (⚠️ NOTE: Returns integer, not string!)
- `alert` (string or null): Alert level ("green", "yellow", "orange", "red")
- `url` (string): Link to USGS event page
- `felt` (int or null): Number of "Did You Feel It?" reports
- `title` (string): Full earthquake title

**From `geometry.coordinates` array:**
- `[0]` (float): Longitude (-180 to 180)
- `[1]` (float): Latitude (-90 to 90)  
- `[2]` (float, optional): Depth in kilometers (⚠️ NOTE: May be missing!)

---

## Service Implementation

### File Structure
```
lib/services/usgs_service.dart (120 lines)
```

### Core Methods

#### 1. `getEarthquakes({required String feed})`
Fetches earthquakes from specified USGS feed.

**Parameters:**
- `feed` (String): Feed identifier
  - Options: `"4.5_week"`, `"2.5_day"`, `"1.0_hour"`, `"all_day"`, etc.

**Returns:** `Future<List<Earthquake>>`

**Example Usage:**
```dart
final service = USGSService();
final earthquakes = await service.getEarthquakes(feed: '4.5_week');

for (final eq in earthquakes) {
  print('M${eq.magnitude} - ${eq.place}');
}
```

**Error Handling:**
```dart
try {
  final earthquakes = await service.getEarthquakes(feed: '4.5_week');
} on TimeoutException {
  // Request timed out
} on SocketException {
  // No internet connection
} on FormatException {
  // JSON parsing error
} catch (e) {
  // Other errors
}
```

### Data Models

#### `Earthquake` Class
```dart
class Earthquake {
  final double magnitude;        // Richter scale (0.0 - 10.0)
  final String place;            // Location description
  final DateTime time;           // When it occurred
  final double lat;              // Latitude
  final double lng;              // Longitude
  final double depth;            // Depth in km (0 if unknown)
  final String tsunami;          // "true" or "false"
  final String? url;             // USGS event page
  final String severity;         // "Minor", "Light", etc.
  final Color severityColor;     // Color indicator
  
  Earthquake({
    required this.magnitude,
    required this.place,
    required this.time,
    required this.lat,
    required this.lng,
    required this.depth,
    required this.tsunami,
    this.url,
    required this.severity,
    required this.severityColor,
  });
  
  factory Earthquake.fromJson(Map<String, dynamic> json) {
    final props = json['properties'];
    final coords = json['geometry']['coordinates'] as List;
    
    // ⚠️ CRITICAL: Handle tsunami as int or string
    final tsunamiRaw = props['tsunami'];
    String tsunamiValue;
    if (tsunamiRaw is int) {
      tsunamiValue = tsunamiRaw == 1 ? 'true' : 'false';
    } else if (tsunamiRaw is String) {
      tsunamiValue = tsunamiRaw;
    } else {
      tsunamiValue = 'false';
    }
    
    final magnitude = (props['mag'] as num?)?.toDouble() ?? 0.0;
    final (severity, color) = _getSeverity(magnitude);
    
    return Earthquake(
      magnitude: magnitude,
      place: props['place'] as String? ?? 'Unknown',
      time: DateTime.fromMillisecondsSinceEpoch(props['time'] as int),
      lat: (coords[1] as num).toDouble(),
      lng: (coords[0] as num).toDouble(),
      // ⚠️ CRITICAL: coords[2] (depth) may be missing!
      depth: coords.length > 2 ? (coords[2] as num?)?.toDouble() ?? 0.0 : 0.0,
      tsunami: tsunamiValue,
      url: props['url'] as String?,
      severity: severity,
      severityColor: color,
    );
  }
  
  static (String, Color) _getSeverity(double magnitude) {
    if (magnitude < 3.0) return ('Minor', Colors.green);
    if (magnitude < 4.0) return ('Light', Colors.lightGreen);
    if (magnitude < 5.0) return ('Moderate', Colors.yellow);
    if (magnitude < 6.0) return ('Strong', Colors.orange);
    if (magnitude < 7.0) return ('Major', Colors.deepOrange);
    return ('Great', Colors.red);
  }
}
```

### Magnitude Severity Scale

**Based on Richter Scale:**

| Magnitude | Severity | Color | Effects |
|-----------|----------|-------|---------|
| < 3.0 | Minor | 🟢 Green | Usually not felt |
| 3.0 - 3.9 | Light | 🟢 Light Green | Often felt, rarely causes damage |
| 4.0 - 4.9 | Moderate | 🟡 Yellow | Noticeable shaking, minor damage |
| 5.0 - 5.9 | Strong | 🟠 Orange | Moderate damage to buildings |
| 6.0 - 6.9 | Major | 🟠 Deep Orange | Serious damage over large area |
| 7.0+ | Great | 🔴 Red | Catastrophic damage |

### Service Code Template
```dart
import 'dart:convert';
import 'dart:math';  // ⚠️ CRITICAL: Import for distance calculations
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class USGSService {
  static const String _baseUrl = 'earthquake.usgs.gov';
  
  Future<List<Earthquake>> getEarthquakes({required String feed}) async {
    try {
      final uri = Uri.https(
        _baseUrl,
        '/earthquakes/feed/v1.0/summary/$feed.geojson',
      );
      
      debugPrint('📡 Fetching earthquakes from: $uri');
      
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final features = data['features'] as List;
        
        debugPrint('📦 Received ${features.length} earthquakes');
        
        return features
            .map((feature) => Earthquake.fromJson(feature))
            .toList();
      } else {
        throw Exception('Failed to fetch earthquakes: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('❌ USGS error: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      rethrow;
    }
  }
}
```

---

## Bug Fixes (2024-02-10)

### Critical Issues Resolved

#### Bug 1: Missing dart:math Import
**Problem:** Service used trigonometric functions but imported dummy implementations
```dart
// ❌ WRONG - Dummy implementation
static double sin(double x) => x;  // NOT REAL SINE!
static double cos(double x) => 1;
static double sqrt(double x) => x * x;  // BACKWARDS!
```

**Solution:** Import real math library
```dart
// ✅ CORRECT
import 'dart:math';

// Now sin(), cos(), sqrt() work properly
final distance = _calculateDistance(lat1, lng1, lat2, lng2);
```

#### Bug 2: Type Cast Error on `tsunami` Field
**Problem:** Code assumed `tsunami` was always a String, but USGS returns int (0 or 1)
```dart
// ❌ WRONG - Crashes when tsunami is int
final tsunami = props['tsunami'] as String;

// Error: type 'int' is not a subtype of type 'String' in type cast
```

**Solution:** Handle both int and String types
```dart
// ✅ CORRECT
final tsunamiRaw = props['tsunami'];
String tsunamiValue;
if (tsunamiRaw is int) {
  tsunamiValue = tsunamiRaw == 1 ? 'true' : 'false';
} else if (tsunamiRaw is String) {
  tsunamiValue = tsunamiRaw;
} else {
  tsunamiValue = 'false';
}
```

#### Bug 3: Null Safety on `depth` (coords[2])
**Problem:** Assumed `coords[2]` always exists, but some earthquakes lack depth data
```dart
// ❌ WRONG - Crashes when depth is missing
depth: (coords[2] as num).toDouble(),

// Error: Index out of range
```

**Solution:** Check array length before accessing
```dart
// ✅ CORRECT
depth: coords.length > 2
    ? (coords[2] as num?)?.toDouble() ?? 0.0
    : 0.0,
```

**Testing:** After these fixes, earthquake tracker successfully loads data from USGS.

---

## UI Implementation

### Screen File
`lib/src/features/earthquake_tracker/presentation/earthquake_tracker_screen.dart` (320 lines)

### UI Components

#### 1. Filter Chips
```dart
Wrap(
  spacing: 8,
  children: [
    FilterChip(
      label: const Text('M4.5+ Week'),
      selected: _selectedFeed == '4.5_week',
      onSelected: (selected) {
        if (selected) _loadEarthquakes('4.5_week');
      },
    ),
    FilterChip(
      label: const Text('M2.5+ Day'),
      selected: _selectedFeed == '2.5_day',
      onSelected: (selected) {
        if (selected) _loadEarthquakes('2.5_day');
      },
    ),
    // ... more filters
  ],
)
```

#### 2. Earthquake List
```dart
ListView.builder(
  itemCount: _earthquakes.length,
  itemBuilder: (context, index) {
    final eq = _earthquakes[index];
    return Card(
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: eq.severityColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              'M${eq.magnitude.toStringAsFixed(1)}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(eq.place),
        subtitle: Text(
          '${_formatDate(eq.time)}\n'
          'Depth: ${eq.depth.toStringAsFixed(1)} km',
        ),
        trailing: eq.tsunami == 'true'
            ? const Icon(Icons.waves, color: Colors.red)
            : null,
      ),
    );
  },
)
```

#### 3. Summary Statistics
```dart
Row(
  mainAxisAlignment: MainAxisAlignment.spaceAround,
  children: [
    _StatCard(
      label: 'Total',
      value: _earthquakes.length.toString(),
      icon: Icons.public,
    ),
    _StatCard(
      label: 'Tsunami Risk',
      value: _earthquakes.where((eq) => eq.tsunami == 'true').length.toString(),
      icon: Icons.waves,
      color: Colors.red,
    ),
    _StatCard(
      label: 'M5.0+',
      value: _earthquakes.where((eq) => eq.magnitude >= 5.0).length.toString(),
      icon: Icons.warning,
      color: Colors.orange,
    ),
  ],
)
```

---

## KML Generation

### Multiple Earthquakes with Color-Coded Markers

```dart
String generateEarthquakeKML(List<Earthquake> earthquakes) {
  final buffer = StringBuffer();
  
  buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
  buffer.writeln('<Document>');
  buffer.writeln('  <name>Recent Earthquakes</name>');
  
  // Define color styles
  buffer.writeln('  <Style id="minorStyle">');
  buffer.writeln('    <IconStyle><color>ff00ff00</color><scale>0.8</scale></IconStyle>');
  buffer.writeln('  </Style>');
  buffer.writeln('  <Style id="moderateStyle">');
  buffer.writeln('    <IconStyle><color>ff00ffff</color><scale>1.0</scale></IconStyle>');
  buffer.writeln('  </Style>');
  buffer.writeln('  <Style id="majorStyle">');
  buffer.writeln('    <IconStyle><color>ff0000ff</color><scale>1.2</scale></IconStyle>');
  buffer.writeln('  </Style>');
  
  // Limit to 50 earthquakes
  final limited = earthquakes.take(50);
  
  for (final eq in limited) {
    final styleId = eq.magnitude < 4.0
        ? 'minorStyle'
        : eq.magnitude < 6.0
            ? 'moderateStyle'
            : 'majorStyle';
    
    buffer.writeln('  <Placemark>');
    buffer.writeln('    <name>M${eq.magnitude.toStringAsFixed(1)}</name>');
    buffer.writeln('    <description>');
    buffer.writeln('      <![CDATA[');
    buffer.writeln('        <b>${_escapeXml(eq.place)}</b><br/>');
    buffer.writeln('        Magnitude: ${eq.magnitude}<br/>');
    buffer.writeln('        Time: ${eq.time}<br/>');
    buffer.writeln('        Depth: ${eq.depth} km<br/>');
    buffer.writeln('        Tsunami: ${eq.tsunami}<br/>');
    if (eq.url != null) {
      buffer.writeln('        <a href="${eq.url}">More Info</a>');
    }
    buffer.writeln('      ]]>');
    buffer.writeln('    </description>');
    buffer.writeln('    <styleUrl>#$styleId</styleUrl>');
    buffer.writeln('    <Point>');
    buffer.writeln('      <coordinates>${eq.lng},${eq.lat},${eq.depth * 1000}</coordinates>');
    buffer.writeln('    </Point>');
    buffer.writeln('  </Placemark>');
  }
  
  buffer.writeln('</Document>');
  buffer.writeln('</kml>');
  
  return buffer.toString();
}
```

---

## Testing

### Manual Testing Checklist

**Basic Functionality:**
- [ ] Load M4.5+ week feed
- [ ] Verify earthquakes display with correct info
- [ ] Check magnitude colors (green → red)
- [ ] Verify tsunami warnings show red icon
- [ ] Test filter chips (switch between feeds)
- [ ] Send to LG (verify 50 markers appear)

**Edge Cases:**
- [ ] Empty feed (no recent earthquakes)
- [ ] Very large magnitude (M8.0+)
- [ ] Missing depth value
- [ ] Missing tsunami value
- [ ] Long location names

**Error Handling:**
- [ ] No internet connection
- [ ] API timeout
- [ ] Invalid feed parameter
- [ ] LG not connected

---

## Common Issues & Solutions

### Issue 1: "No earthquakes found" Error
**Symptoms:** 
- API returns 200 OK
- `features` array is empty
- Red snackbar shows "No earthquakes found"

**Causes:**
- Selected feed has no data (e.g., no M4.5+ earthquakes in past hour)
- USGS feed temporarily unavailable

**Solutions:**
1. Try different feed (e.g., "all_day" instead of "4.5_week")
2. Check USGS status: https://earthquake.usgs.gov/
3. Wait and retry (feeds update every 1-5 minutes)

### Issue 2: Type Cast Errors
**Symptoms:** `type 'X' is not a subtype of type 'Y' in type cast`

**Causes:**
- USGS API changed data types
- Null values in response

**Solutions:** See Bug Fixes section above

### Issue 3: Depth Shows 0.0 km
**Symptoms:** All earthquakes show depth 0.0

**Causes:**
- Depth data missing from API response
- `coords[2]` doesn't exist

**Solutions:** Already handled in `fromJson()` (see Bug #3 above)

### Issue 4: Too Many Markers on LG
**Symptoms:** LG performance degrades with hundreds of markers

**Solutions:**
```dart
// Limit to 50 earthquakes
final limited = earthquakes.take(50).toList();
final kml = generateEarthquakeKML(limited);
```

---

## Performance Optimization

### 1. Limit Results
```dart
// Show only top 100 earthquakes
setState(() {
  _earthquakes = earthquakes.take(100).toList();
});
```

### 2. Filter by Magnitude
``` dart
// Only show M4.0+
setState(() {
  _earthquakes = earthquakes
      .where((eq) => eq.magnitude >= 4.0)
      .toList();
});
```

### 3. Sort by Magnitude (Descending)
```dart
earthquakes.sort((a, b) => b.magnitude.compareTo(a.magnitude));
```

---

## Future Enhancements

- [ ] **Real-Time Updates:** Auto-refresh every 5 minutes
- [ ] **Magnitude Range Slider:** Custom magnitude filtering
- [ ] **Map View:** Display earthquakes on embedded map
- [ ] **Notifications:** Alert on major earthquakes (M6.0+)
- [ ] **Historical Data:** View past earthquakes by date range
- [ ] **Nearby Earthquakes:** Find earthquakes near user location
- [ ] **Felt Reports:** Show "Did You Feel It?" counts
- [ ] **Aftershock Tracking:** Group related earthquakes

---

## References

- **USGS API Docs:** https://earthquake.usgs.gov/earthquakes/feed/v1.0/geojson.php
- **GeoJSON Spec:** https://geojson.org/
- **Richter Scale:** https://earthquake.usgs.gov/learn/topics/measure.php
- **Tsunami Info:** https://www.tsunami.gov/

---

**See also:**
- [location-lookup.md](location-lookup.md) - Location search
- [weather-overlay.md](weather-overlay.md) - Weather data
- [8-troubleshooting/api-errors.md](../8-troubleshooting/api-errors.md) - API debugging
- [7-workflows/debugging.md](../7-workflows/debugging.md) - Debugging process

**Last Updated:** 2026-02-10
