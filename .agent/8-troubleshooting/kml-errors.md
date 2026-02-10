---
title: KML Validation Errors
folder: 07-troubleshooting
tags: [troubleshooting, kml, xml, validation]
related:
  - ../01-core-patterns/kml-management.md
  - ../04-anti-patterns/kml-mistakes.md
difficulty: intermediate
time-to-read: 8 min
---

# KML Validation & Errors 🐛

Debug KML generation and validation issues.

## KML Not Loading (Silent Failure)

**Symptom**: KML sent to LG but nothing happens

**Most Common Cause**: Invalid XML or coordinates out of range

**Debug Steps**:

1. Save KML to file to inspect:
```dart
// In your code
final kml = KMLBuilder.buildFlyTo(...);
print(kml); // Copy output
// Save to test.kml and open in text editor
```

2. Validate XML structure:
```dart
// Check essential elements
if (!kml.contains('<?xml')) print('❌ Missing XML declaration');
if (!kml.contains('<kml')) print('❌ Missing kml tag');
if (!kml.contains('<Document>')) print('❌ Missing Document');
if (!kml.contains('</kml>')) print('❌ Unclosed kml tag');
```

3. Check coordinates:
```dart
// Validate ranges
if (latitude < -90 || latitude > 90) {
  print('❌ Invalid latitude: $latitude');
}
if (longitude < -180 || longitude > 180) {
  print('❌ Invalid longitude: $longitude');
}
```

4. Test locally:
- Save KML as `test.kml`
- Open in Google Earth Desktop
- If Google Earth rejects it, so will LG

**Solutions**:
- ✅ Always validate coordinates before generating KML
- ✅ Add XML declaration
- ✅ Wrap description in CDATA
- ✅ Test with Google Earth first

## XML Parsing Errors

**Symptom**: "XML parsing error" in LG logs

**Common Issues**:

### Missing/Wrong Namespace
```dart
// BAD - gx namespace not declared
<kml xmlns="http://www.opengis.net/kml/2.2">
  <gx:Tour>...</gx:Tour>
</kml>

// GOOD - Declare gx namespace
<kml xmlns="http://www.opengis.net/kml/2.2"
     xmlns:gx="http://www.google.com/kml/ext/2.2">
  <gx:Tour>...</gx:Tour>
</kml>
```

### Unescaped Characters
```dart
// BAD - & not escaped
<description>Location & Description</description>

// GOOD - Use CDATA for safety
<description><![CDATA[Location & Description]]></description>

// Or escape characters
<description>Location &amp; Description</description>
```

### Unclosed Tags
```dart
// BAD - Missing </kml>
<?xml version="1.0"?>
<kml>
  <Document>
    ...
  <!-- Missing </Document> and </kml> -->

// GOOD - All tags closed
<?xml version="1.0"?>
<kml>
  <Document>
    ...
  </Document>
</kml>
```

## Coordinates Not Working

**Symptom**: Camera goes to wrong location or (0,0)

**Coordinate Order**:
```dart
// WRONG - Latitude first
<coordinates>$latitude,$longitude,0</coordinates>
// Result: Wrong location!

// CORRECT - Longitude first
<coordinates>$longitude,$latitude,0</coordinates>
// Result: Right location!
```

**Out of Range**:
```dart
// Check coordinate ranges
if (lat < -90 || lat > 90) {
  print('❌ Latitude $lat is out of range [-90, 90]');
}
if (lng < -180 || lng > 180) {
  print('❌ Longitude $lng is out of range [-180, 180]');
}

// Test data
final validLocations = [
  (lat: 40.6892, lng: -74.0445),  // ✅ Statue of Liberty
  (lat: 51.5074, lng: -0.1278),   // ✅ Big Ben
  (lat: 200.0, lng: 500.0),       // ❌ Invalid!
];
```

**Altitude Issues**:
```dart
// BAD - Very high altitude in Camera but 0 in coordinates
<Camera>
  <altitude>1000000</altitude>
</Camera>

// GOOD - Consistent altitude
<Camera>
  <altitude>0</altitude>
  <longitude>$longitude</longitude>
  <latitude>$latitude</latitude>
</Camera>
```

## Camera Not Positioning Correctly

**Symptom**: Camera moves to location but angle/zoom is wrong

**Check These**:

### Tilt Value (0-90)
```dart
// BAD - Tilt outside range
final kml = KMLBuilder.buildFlyTo(tilt: 120); // ❌

// GOOD - Tilt 0-90
final kml = KMLBuilder.buildFlyTo(tilt: 45); // ✅ Default
```

### Range (Zoom Distance)
```dart
// Range is meters from location
// Small range = zoomed in
// Large range = zoomed out

// Around building (50 meters)
range: 50

// Whole city (5000 meters)
range: 5000

// Continent (500000 meters)
range: 500000
```

### Heading (0-360)
```dart
// 0 = North
// 90 = East
// 180 = South
// 270 = West

// North view
heading: 0

// East view
heading: 90
```

## Tour/Animation Not Playing

**Symptom**: `<gx:Tour>` sent but animation doesn't run

**Check**:

1. Tour needs `gx:` namespace:
```dart
// BAD - gx namespace not declared
<kml xmlns="http://www.opengis.net/kml/2.2">
  <gx:Tour>...</gx:Tour>
</kml>

// GOOD
<kml xmlns="http://www.opengis.net/kml/2.2"
     xmlns:gx="http://www.google.com/kml/ext/2.2">
  <gx:Tour>...</gx:Tour>
</kml>
```

2. Duration must be float:
```dart
// BAD
<gx:duration>3</gx:duration>

// GOOD
<gx:duration>3.0</gx:duration>
```

3. FlyTo structure:
```dart
// GOOD format
<gx:FlyTo>
  <gx:duration>3.0</gx:duration>
  <Camera>
    <longitude>...</longitude>
    <latitude>...</latitude>
    <altitude>0</altitude>
    <heading>0</heading>
    <tilt>45</tilt>
    <roll>0</roll>
  </Camera>
</gx:FlyTo>
```

## Placemark Not Showing

**Symptom**: Placemark data sent but doesn't show on map

**Check**:

1. Coordinates format:
```dart
// Placemark uses LngLatAlt in <Point>
<Point>
  <coordinates>$longitude,$latitude,0</coordinates>
</Point>
```

2. Valid structure:
```dart
<Placemark>
  <name>Location Name</name>
  <description>Details</description>
  <Point>
    <coordinates>-74.0445,40.6892,0</coordinates>
  </Point>
</Placemark>
```

3. Valid longitude/latitude
```dart
// Must be in valid range
final lat = 40.6892;  // ✅
final lng = -74.0445; // ✅ (negative in Western Hemisphere)

// Not like this
final lat = 200.0;    // ❌
final lng = 500.0;    // ❌
```

## KML Validation Checklist

Use this before sending KML:

```dart
bool validateKML(String kml) {
  bool valid = true;

  // 1. XML declaration
  if (!kml.startsWith('<?xml')) {
    print('❌ Missing XML declaration');
    valid = false;
  }

  // 2. KML root element
  if (!kml.contains('<kml')) {
    print('❌ Missing <kml> element');
    valid = false;
  }

  // 3. Document wrapper
  if (!kml.contains('<Document>')) {
    print('❌ Missing <Document> element');
    valid = false;
  }

  // 4. Balanced tags
  final kmlOpen = '<kml'.allMatches(kml).length;
  final kmlClose = '</kml>'.allMatches(kml).length;
  if (kmlOpen != kmlClose) {
    print('❌ Unbalanced <kml> tags');
    valid = false;
  }

  // 5. Namespace declarations
  if (kml.contains('<gx:')) {
    if (!kml.contains('xmlns:gx')) {
      print('❌ Missing gx namespace declaration');
      valid = false;
    }
  }

  // 6. Check for special characters not in CDATA
  if (kml.contains('<description>') && kml.contains('&')) {
    if (!kml.contains('CDATA')) {
      print('⚠️  May need CDATA for special characters');
    }
  }

  return valid;
}
```

## Testing KML Locally

Before sending to LG:

1. **Google Earth Desktop**:
   - File → Open → test.kml
   - If it loads, it should work on LG

2. **Online KML Viewer**:
   - https://kml-samples.googlecode.com/files/KML_Samples.kml
   - Paste your KML and check

3. **LG Web Interface**:
   - Upload KML via web interface
   - Test before app integration

## Quick Debug Script

```dart
final kml = KMLBuilder.buildFlyTo(
  latitude: 40.6892,
  longitude: -74.0445,
  altitude: 0,
);

debugPrint('=== KML DEBUG ===');
debugPrint('Length: ${kml.length}');
debugPrint('Has XML: ${kml.contains('<?xml')}');
debugPrint('Has KML: ${kml.contains('<kml')}');
debugPrint('Has Document: ${kml.contains('<Document')}');
debugPrint('Balanced: ${kml.split('<kml').length == kml.split('</kml>').length}');
debugPrint('=== KML Content ===');
debugPrint(kml);
```

## Next Steps

1. Review [KML Management](../01-core-patterns/kml-management.md)
2. Check [KML Mistakes](../04-anti-patterns/kml-mistakes.md)
3. Test with [KML Builder Template](../03-code-templates/kml-builder.dart)

---

**Rule of Thumb**: Always test KML in Google Earth Desktop before sending to LG. If Google Earth rejects it, LG will too.
