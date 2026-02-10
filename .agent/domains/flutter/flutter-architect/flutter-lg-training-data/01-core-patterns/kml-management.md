---
title: KML Management Architecture
folder: 01-core-patterns
tags: [kml, google-earth, xml, generation]
related:
  - ../02-implementation-guides/fly-to-location.md
  - ../02-implementation-guides/tour-feature.md
  - ../03-code-templates/kml-builder.dart
  - ../07-troubleshooting/kml-validation-errors.md
  - ../04-anti-patterns/kml-mistakes.md
difficulty: intermediate
time-to-read: 12 min
---

# KML Management Architecture 🗺️

KML (Keyhole Markup Language) is the language Google Earth speaks. It's how you tell LG what to display and where to fly.

## ⚠️ CRITICAL: File Path Standard

**Always use: `/var/www/html/kml/master.kml`**

❌ DO NOT use:
- `/var/www/html/kml/master_1.kml` (old pattern, avoid)
- `/var/www/html/kml/slave_*.kml` (for static overlays only)

✅ `master.kml` is the standard injection point for:
- Flying to locations
- Running tours
- Clearing displays
- Any interactive KML content

**Clearing KML also uses master.kml:**
```dart
await execute('echo "<blank>" > /var/www/html/kml/master.kml');
```

## What is KML?

KML is XML format for geospatial data:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <!-- Your content here -->
  </Document>
</kml>
```

## Core Patterns

### 1. FlyTo (Navigation)
Move camera to a location:

```dart
class KMLBuilder {
  static String buildFlyTo({
    required double latitude,
    required double longitude,
    required double range,      // Distance from point in meters
    double tilt = 60,          // Camera angle
    double heading = 0,        // Compass heading
    double duration = 5.0,     // Seconds to fly
  }) {
    // Validate coordinates
    assert(latitude >= -90 && latitude <= 90, 'Invalid lat');
    assert(longitude >= -180 && longitude <= 180, 'Invalid lng');
    
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" 
     xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <gx:Tour>
      <gx:Playlist>
        <gx:FlyTo>
          <gx:duration>$duration</gx:duration>
          <gx:flyToMode>smooth</gx:flyToMode>
          <LookAt>
            <longitude>$longitude</longitude>
            <latitude>$latitude</latitude>
            <range>$range</range>
            <tilt>$tilt</tilt>
            <heading>$heading</heading>
            <gx:altitudeMode>relativeToGround</gx:altitudeMode>
          </LookAt>
        </gx:FlyTo>
      </gx:Playlist>
    </gx:Tour>
  </Document>
</kml>''';
  }
}
```

**Usage:**
```dart
final kml = KMLBuilder.buildFlyTo(
  latitude: 48.8584,
  longitude: 2.2945,
  range: 5000,
);
await lgService.sendKML(kml);
```

### 2. Placemark (Point of Interest)
Mark a location:

```dart
static String buildPlacemark({
  required String name,
  required double latitude,
  required double longitude,
  String? description,
  String? iconUrl,
}) {
  final desc = description != null 
    ? '<description><![CDATA[$description]]></description>'
    : '';
  
  final style = iconUrl != null ? '''
    <Style>
      <IconStyle>
        <Icon>
          <href>$iconUrl</href>
        </Icon>
      </IconStyle>
    </Style>
''' : '';
  
  return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <Placemark>
      <name>$name</name>
      $desc
      $style
      <Point>
        <coordinates>$longitude,$latitude,0</coordinates>
      </Point>
    </Placemark>
  </Document>
</kml>''';
}
```

### 3. Tour (Multi-point Animation)
Animated sequence of locations:

```dart
class TourPoint {
  final double latitude;
  final double longitude;
  final double range;
  final double tilt;
  final double heading;
  final double flyDuration;
  final double waitDuration;
  
  const TourPoint({
    required this.latitude,
    required this.longitude,
    this.range = 5000,
    this.tilt = 60,
    this.heading = 0,
    this.flyDuration = 3.0,
    this.waitDuration = 2.0,
  });
}

static String buildTour({
  required String name,
  required List<TourPoint> points,
}) {
  final playlist = points.map((point) => '''
    <gx:FlyTo>
      <gx:duration>${point.flyDuration}</gx:duration>
      <gx:flyToMode>smooth</gx:flyToMode>
      <LookAt>
        <longitude>${point.longitude}</longitude>
        <latitude>${point.latitude}</latitude>
        <range>${point.range}</range>
        <tilt>${point.tilt}</tilt>
        <heading>${point.heading}</heading>
        <gx:altitudeMode>relativeToGround</gx:altitudeMode>
      </LookAt>
    </gx:FlyTo>
    <gx:Wait>
      <gx:duration>${point.waitDuration}</gx:duration>
    </gx:Wait>
''').join('\n');
  
  return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" 
     xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>$name</name>
    <gx:Tour>
      <name>$name</name>
      <gx:Playlist>
        $playlist
      </gx:Playlist>
    </gx:Tour>
  </Document>
</kml>''';
}
```

## Best Practices

### 1. Always Include XML Declaration
```dart
// ✅ GOOD
return '''<?xml version="1.0" encoding="UTF-8"?>
<kml ...>...

// ❌ BAD - Missing declaration
return '''<kml ...>...
```

### 2. Validate Coordinates
```dart
// ✅ GOOD
assert(lat >= -90 && lat <= 90, 'Latitude out of range');
assert(lng >= -180 && lng <= 180, 'Longitude out of range');

// ❌ BAD - No validation
final kml = buildFlyTo(lat: 500, lng: 500);
```

### 3. Use CDATA for Text
```dart
// ✅ GOOD - Handles special characters
<description><![CDATA[$text]]></description>

// ❌ BAD - May break with special chars
<description>$text</description>
```

### 4. Escape XML Special Characters
```dart
// ✅ GOOD
String escapeXml(String text) {
  return text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
}

// ❌ BAD - May break XML
<name>$userInput</name>
```

### 5. Modularize Generation
```dart
// ✅ GOOD - Each method generates one element
static String buildPlacemark(...) { ... }
static String buildFlyTo(...) { ... }
static String buildTour(...) { ... }

// ❌ BAD - Mixing everything
String generateKml() {
  String kml = '<?xml...' + placemark + tour + ...
}
```

## Coordinate System

**Latitude**: -90 (South Pole) to 90 (North Pole)
**Longitude**: -180 (West) to 180 (East)

```
         North (90)
             |
West (-180)--+--East (180)
             |
         South (-90)

Examples:
New York: lat=40.7128, lng=-74.0060
London: lat=51.5074, lng=-0.1278
Sydney: lat=-33.8688, lng=151.2093
```

## Common Parameters

| Parameter | Range | Meaning |
|-----------|-------|---------|
| latitude | -90 to 90 | Position north/south |
| longitude | -180 to 180 | Position east/west |
| range | 0 to any | Camera distance (meters) |
| tilt | 0 to 90 | Camera angle (0=vertical, 90=horizontal) |
| heading | 0 to 360 | Compass direction |
| duration | > 0 | Seconds for animation |

## Integration with SSH

```dart
class LGService {
  final SSHService _ssh;
  
  LGService(this._ssh);
  
  Future<bool> sendKML(String kml, String filename) async {
    if (!_ssh.isConnected) return false;
    
    try {
      // Escape for shell
      final escaped = kml.replaceAll("'", "'\\''");
      
      // Write file
      final cmd = "echo '$escaped' > /var/www/html/kml/$filename.kml";
      final result = await _ssh.execute(cmd);
      
      if (result == null) return false;
      
      // Send query to display
      final query = 'echo "http://lg1:81/$filename.kml" > /tmp/query.txt';
      await _ssh.execute(query);
      
      return true;
    } catch (e) {
      debugPrint('KML send error: $e');
      return false;
    }
  }
}
```

## Testing KML

Always validate KML before sending to LG:

1. **Check syntax**: Valid XML?
2. **Check coordinates**: Within range?
3. **Check namespaces**: Correct xmlns?
4. **Check declarations**: XML declaration present?
5. **Test in Google Earth**: Does it work?

```dart
bool validateKML(String kml) {
  // Check XML declaration
  if (!kml.startsWith('<?xml')) {
    return false;
  }
  
  // Check contains kml tags
  if (!kml.contains('<kml') || !kml.contains('</kml>')) {
    return false;
  }
  
  // Check Document
  if (!kml.contains('<Document') || !kml.contains('</Document>')) {
    return false;
  }
  
  return true;
}
```

## Common Issues

**KML not showing?**
→ Check XML is valid  
→ Verify coordinates in range  
→ Confirm SSH file transfer worked

**Coordinates wrong?**
→ Check lat/lng not reversed  
→ Verify longitude sign (negative for West)  
→ Validate against known locations

**Special characters break?**
→ Use CDATA for text  
→ Escape XML characters  
→ Test with problematic input

See `07-troubleshooting/kml-validation-errors.md` for detailed debugging.

## Next Steps

- Read `02-implementation-guides/fly-to-location.md` for step-by-step
- Copy `03-code-templates/kml-builder.dart` for ready-made code
- Check `04-anti-patterns/kml-mistakes.md` for what NOT to do
- Use `06-quality-standards/code-review-checklist.md` before shipping

---

**Rule of Thumb**: KML is brittle. Always validate, always test, always use builders instead of string concatenation.
