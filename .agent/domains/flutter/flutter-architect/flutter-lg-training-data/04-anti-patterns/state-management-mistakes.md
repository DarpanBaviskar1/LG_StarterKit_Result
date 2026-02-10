---
title: KML Generation Anti-Patterns
folder: 04-anti-patterns
tags: [anti-patterns, kml, mistakes, xml]
related:
  - ../01-core-patterns/kml-management.md
  - ../07-troubleshooting/kml-validation-errors.md
difficulty: intermediate
time-to-read: 8 min
---

# KML Generation Anti-Patterns 🚫

Common KML mistakes that break your navigation.

## 1. ❌ Invalid Coordinates

```dart
// BAD - Out of range coordinates
KMLBuilder.buildFlyTo(
  latitude: 200.0, // Invalid! Must be -90 to 90
  longitude: 500.0, // Invalid! Must be -180 to 180
);
```

**Problem**: KML won't load, silent failure  
**Fix**:
```dart
// GOOD - Validate first
if (lat < -90 || lat > 90) {
  throw Exception('Invalid latitude');
}
if (lng < -180 || lng > 180) {
  throw Exception('Invalid longitude');
}
```

## 2. ❌ Missing XML Declaration

```dart
// BAD - No XML header
final kml = '''<kml>
  <Document>
    <LookAt>...</LookAt>
  </Document>
</kml>''';
```

**Problem**: LG may not recognize it  
**Fix**:
```dart
// GOOD - Always include XML declaration
final kml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <LookAt>...</LookAt>
  </Document>
</kml>''';
```

## 3. ❌ Unescaped Special Characters

```dart
// BAD - Special characters in strings
final name = 'Location & Description';
KMLBuilder.buildPlacemark(
  name: name, // Unescaped &!
  latitude: 40.0,
  longitude: 74.0,
);
```

**Problem**: XML parsing fails  
**Fix**:
```dart
// GOOD - Use CDATA for safety
static String escapeXML(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}

// Or use CDATA
final kml = '''<Placemark>
  <description><![CDATA[$rawText]]></description>
</Placemark>''';
```

## 4. ❌ Wrong Coordinate Order

```dart
// BAD - Latitude before longitude
final kml = '''<Point>
  <coordinates>$latitude,$longitude,0</coordinates>
</Point>''';
```

**Problem**: Location appears at wrong place  
**Fix**:
```dart
// GOOD - Always longitude, latitude
final kml = '''<Point>
  <coordinates>$longitude,$latitude,0</coordinates>
</Point>''';
```

## 5. ❌ No Altitude in Tour

```dart
// BAD - Missing altitude in Camera
final kml = '''<Camera>
  <longitude>$lng</longitude>
  <latitude>$lat</latitude>
  <!-- Missing altitude! -->
  <heading>0</heading>
  <tilt>45</tilt>
</Camera>''';
```

**Problem**: Camera positioning fails  
**Fix**:
```dart
// GOOD - Always include altitude
final kml = '''<Camera>
  <longitude>$lng</longitude>
  <latitude>$lat</latitude>
  <altitude>0</altitude>
  <heading>0</heading>
  <tilt>45</tilt>
  <roll>0</roll>
</Camera>''';
```

## 6. ❌ Invalid Tilt Values

```dart
// BAD - Tilt outside valid range
KMLBuilder.buildFlyTo(
  latitude: 40.0,
  longitude: 74.0,
  tilt: 120.0, // Invalid! Must be 0-90
);
```

**Problem**: Camera doesn't show what you expect  
**Fix**:
```dart
// GOOD - Tilt between 0-90
KMLBuilder.buildFlyTo(
  latitude: 40.0,
  longitude: 74.0,
  tilt: 45.0, // Good default
);
```

## 7. ❌ Hardcoding Namespace

```dart
// BAD - Different namespaces in same file
final kml = '''<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <!-- But later using different namespace -->
    <gx:Tour>
      <gx:FlyTo>...</gx:FlyTo>
    </gx:Tour>
  </Document>
</kml>''';
```

**Problem**: Namespaces not recognized  
**Fix**:
```dart
// GOOD - Declare all namespaces
final kml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2"
     xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <gx:Tour>
      <gx:FlyTo>...</gx:FlyTo>
    </gx:Tour>
  </Document>
</kml>''';
```

## 8. ❌ Duration as Integer

```dart
// BAD - Duration as integer
<gx:duration>3</gx:duration>
```

**Problem**: May be parsed as milliseconds  
**Fix**:
```dart
// GOOD - Duration as float with decimal
<gx:duration>3.0</gx:duration>
```

## 9. ❌ Forgetting Document Wrapper

```dart
// BAD - No Document element
<kml>
  <LookAt>...</LookAt>
</kml>
```

**Problem**: KML not valid  
**Fix**:
```dart
// GOOD - Document wrapper required
<kml>
  <Document>
    <LookAt>...</LookAt>
  </Document>
</kml>
```

## 10. ❌ Not Validating Before Sending

```dart
// BAD - Send without checking
await _ssh.run('echo \'$kml\' > /tmp/flyto.kml');
```

**Problem**: Invalid KML fails silently  
**Fix**:
```dart
// GOOD - Validate first
try {
  _validateKML(kml);
  await _ssh.run('echo \'$kml\' > /tmp/flyto.kml');
} catch (e) {
  debugPrint('❌ Invalid KML: $e');
  rethrow;
}
```

## KML Validation Checklist

```dart
bool isValidKML(String kml) {
  // Must have XML declaration
  if (!kml.startsWith('<?xml')) return false;
  
  // Must have kml tag
  if (!kml.contains('<kml')) return false;
  
  // Must have Document
  if (!kml.contains('<Document>')) return false;
  
  // Balanced tags
  final opens = '<kml'.allMatches(kml).length;
  final closes = '</kml>'.allMatches(kml).length;
  if (opens != closes) return false;
  
  return true;
}
```

## Common XML Mistakes

| Mistake | Wrong | Right |
|---------|-------|-------|
| Order | `<lat>,<lng>` | `<lng>,<lat>` |
| Namespace | `<Tour>` | `<gx:Tour>` |
| Altitude | Missing | Always include |
| Tilt | 120 | 45 |
| Duration | `3` | `3.0` |
| Quotes | `"text"` | `'text'` |
| Ampersand | `&` | `&amp;` |

## Next Steps

1. Read [KML Management](../01-core-patterns/kml-management.md)
2. Check [KML Validation Errors](../07-troubleshooting/kml-validation-errors.md)
3. Use [Code Templates](../03-code-templates/kml-builder.dart)

---

**Rule of Thumb**: If KML is invalid, LG fails silently. Always validate and test locally first.
