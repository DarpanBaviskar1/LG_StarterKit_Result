# KML Templates

This directory contains ready-to-use KML templates for common Liquid Galaxy visualizations.

---

## Available Templates

### 1. [placemark-template.kml](placemark-template.kml)
**Use Case:** Display a single location marker

**Features:**
- Basic point marker
- Name and description
- Configurable style
- Pop-up balloon

**When to use:**
- Marking a specific location
- Search result display
- POI (Point of Interest)

**Customization:**
- Change coordinates
- Update name/description
- Modify icon style
- Add custom balloon content

---

### 2. [tour-template.kml](tour-template.kml)
**Use Case:** Create animated camera movements

**Features:**
- FlyTo animation
- Camera positioning (LookAt)
- Configurable duration and speed
- Smooth transitions

**When to use:**
- Flying to a location
- Guided tours
- Location highlighting
- Cinematic presentations

**Customization:**
- Set target coordinates
- Adjust flight duration
- Change camera angle (tilt, heading)
- Set viewing distance (range)

---

### 3. [overlay-template.kml](overlay-template.kml)
**Use Case:** Display UI elements on screen

**Features:**
- ScreenOverlay for HUD elements
- Positioning (corners, center)
- Image/text display
- Transparency support

**When to use:**
- Logos and branding
- Information panels
- Control interfaces
- Weather widgets

**Customization:**
- Change overlay position
- Update image URL
- Adjust size and transparency
- Set visibility

---

## Usage Pattern

### Step 1: Copy Template
```dart
// Read template from assets or copy code below
final template = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <!-- Template content -->
</kml>
''';
```

### Step 2: Replace Variables
```dart
// Example: Placemark
String createPlacemark(String name, double lat, double lng) {
  return template
      .replaceAll('{{NAME}}', name)
      .replaceAll('{{LAT}}', lat.toString())
      .replaceAll('{{LNG}}', lng.toString());
}
```

### Step 3: Send to LG
```dart
final sshService = ref.read(sshServiceProvider);
await sshService.sendKml(kml, targetFile: 'master.kml');
```

---

## Template Variables Convention

**Placeholders use double braces:** `{{VARIABLE_NAME}}`

**Common variables:**
- `{{NAME}}` - Display name
- `{{DESCRIPTION}}` - Text description
- `{{LAT}}` - Latitude (-90 to 90)
- `{{LNG}}` - Longitude (-180 to 180)
- `{{ALT}}` - Altitude in meters
- `{{HEADING}}` - Camera heading (0-360°)
- `{{TILT}}` - Camera tilt (0-90°)
- `{{RANGE}}` - Distance from point (meters)
- `{{DURATION}}` - Animation duration (seconds)
- `{{COLOR}}` - Color in AABBGGRR format
- `{{ICON_URL}}` - URL to icon image
- `{{IMAGE_URL}}` - URL to overlay image

---

## Color Format (AABBGGRR)

KML uses hexadecimal color format: **AABBGGRR**
- **AA:** Opacity (00 = transparent, FF = opaque)
- **BB:** Blue (00-FF)
- **GG:** Green (00-FF)
- **RR:** Red (00-FF)

**Examples:**
```
ff0000ff = Opaque Red
ff00ff00 = Opaque Green
ff00ffff = Opaque Yellow
ff0000ff = Opaque Blue
7f0000ff = Semi-transparent Red
```

**Dart helper:**
```dart
String colorToKml(Color color) {
  final alpha = color.alpha.toRadixString(16).padLeft(2, '0');
  final blue = color.blue.toRadixString(16).padLeft(2, '0');
  final green = color.green.toRadixString(16).padLeft(2, '0');
  final red = color.red.toRadixString(16).padLeft(2, '0');
  
  return '$alpha$blue$green$red';
}

// Usage:
final kmlColor = colorToKml(Colors.red);  // "ff0000ff"
```

---

## Best Practices

### 1. Escape Special Characters
```dart
String escapeXml(String text) {
  return text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
```

### 2. Validate Coordinates
```dart
void validateCoordinates(double lat, double lng) {
  if (lat < -90 || lat > 90) {
    throw Exception('Invalid latitude: $lat');
  }
  if (lng < -180 || lng > 180) {
    throw Exception('Invalid longitude: $lng');
  }
}
```

### 3. Use CDATA for HTML Content
```xml
<description>
  <![CDATA[
    <h3>Title with <HTML></h3>
    <p>No need to escape < > & here</p>
  ]]>
</description>
```

### 4. Always Send to master.kml
```dart
// ✅ CORRECT
await sshService.sendKml(kml, targetFile: 'master.kml');

// ❌ WRONG
await sshService.sendKml(kml, targetFile: 'custom.kml');
```

---

## Advanced Templates

### Multiple Placemarks
```xml
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document>
  <name>Multiple Locations</name>
  
  <Style id="style1">
    <IconStyle><color>ff0000ff</color></IconStyle>
  </Style>
  
  <Placemark>
    <name>Location 1</name>
    <styleUrl>#style1</styleUrl>
    <Point><coordinates>-122.0822,37.4220,0</coordinates></Point>
  </Placemark>
  
  <Placemark>
    <name>Location 2</name>
    <styleUrl>#style1</styleUrl>
    <Point><coordinates>-118.2437,34.0522,0</coordinates></Point>
  </Placemark>
</Document>
</kml>
```

### Path/Line
```xml
<Placemark>
  <name>Flight Path</name>
  <LineString>
    <coordinates>
      -122.0822,37.4220,0
      -118.2437,34.0522,0
      -73.9857,40.7484,0
    </coordinates>
  </LineString>
</Placemark>
```

### Polygon
```xml
<Placemark>
  <name>Area</name>
  <Polygon>
    <outerBoundaryIs>
      <LinearRing>
        <coordinates>
          -122.0,37.4,0
          -122.0,37.5,0
          -121.9,37.5,0
          -121.9,37.4,0
          -122.0,37.4,0
        </coordinates>
      </LinearRing>
    </outerBoundaryIs>
  </Polygon>
</Placemark>
```

---

## Testing Templates

### 1. Validate XML
```bash
# Linux/Mac
xmllint --noout template.kml

# Or use online validator
https://www.xmlvalidation.com/
```

### 2. Test in Google Earth
1. Open Google Earth
2. File → Open → Select KML file
3. Verify display

### 3. Test on LG
```dart
void testTemplate() async {
  final kml = File('template.kml').readAsStringSync();
  final sshService = ref.read(sshServiceProvider);
  await sshService.sendKml(kml, targetFile: 'master.kml');
}
```

---

## Troubleshooting

### Template not displaying
**Check:**
- [ ] Valid XML syntax (all tags closed)
- [ ] Coordinates in correct order (lng, lat, alt)
- [ ] Namespace declaration present
- [ ] Special characters escaped
- [ ] Sent to master.kml

### Colors not showing
**Check:**
- [ ] Color format is AABBGGRR (not RRGGBB)
- [ ] Alpha channel set (FF for opaque)
- [ ] Style applied with `<styleUrl>`

### Tour not animating
**Check:**
- [ ] Using `gx:Tour` and `gx:FlyTo` (with namespace)
- [ ] Duration > 0
- [ ] Valid camera parameters
- [ ] Tour must be played (not automatic)

---

**See also:**
- [2-patterns/kml-patterns.md](../../2-patterns/kml-patterns.md) - KML best practices
- [8-troubleshooting/kml-errors.md](../../8-troubleshooting/kml-errors.md) - KML debugging
- [3-features/](../../3-features/) - Feature examples using KML

**KML Specification:** 
https://developers.google.com/kml/documentation/kmlreference

**Last Updated:** 2026-02-10
