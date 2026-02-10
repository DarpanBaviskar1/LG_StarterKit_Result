# 3D Colored Pyramid KML Feature

## Overview

This feature allows you to send a 3D colored pyramid KML (Keyhole Markup Language) to a specified location on the Liquid Galaxy display. The pyramid is fully customizable in terms of:
- **Location** (latitude, longitude)
- **Dimensions** (peak altitude, base size)
- **Color** (8 predefined colors + custom AABBGGRR format)
- **Name** (for identification in KML)

## Architecture

### Files Created

```
lib/src/features/pyramid/
├── data/
│   ├── pyramid_model.dart           # PyramidConfig data class
│   └── pyramid_provider.dart        # Riverpod state management
└── presentation/
    └── pyramid_builder_screen.dart  # UI for pyramid customization
```

### Files Modified

- [lg_controller/lib/src/features/home/data/kml_service.dart](lg_controller/lib/src/features/home/data/kml_service.dart) - Added `sendColoredPyramid()` method
- [lg_controller/lib/src/features/dashboard/presentation/dashboard_screen.dart](lg_controller/lib/src/features/dashboard/presentation/dashboard_screen.dart) - Added pyramid button

## How to Use

### From the Dashboard

1. Open the LG Controller app
2. Navigate to the Dashboard
3. Click the **"3D Pyramid (NY)"** button
4. The Pyramid Builder screen opens

### Pyramid Builder Screen

The Pyramid Builder provides the following controls:

#### 📍 Location Presets
Quick access to common locations:
- **New York** (40.7128°N, 74.0060°W)
- **London** (51.5074°N, 0.1278°W)
- **Paris** (48.8566°N, 2.3522°E)
- **Tokyo** (35.6762°N, 139.6503°E)
- **Sydney** (33.8688°S, 151.2093°E)

#### 📍 Manual Location
- **Latitude** slider (-90° to 90°)
- **Longitude** slider (-180° to 180°)

#### 📏 Pyramid Dimensions
- **Peak Altitude**: 100m to 10,000m (determines pyramid height)
- **Base Size**: 0.001° to 0.1° (controls base width/length)
  - ~0.001° ≈ 100m
  - ~0.01° ≈ 1km
  - ~0.1° ≈ 10km

#### 🎨 Color
Predefined colors in AABBGGRR format:
- **Red**: `ff0000ff`
- **Green**: `ff00ff00`
- **Blue**: `ffff0000`
- **Yellow**: `ff00ffff`
- **Magenta**: `ffff00ff`
- **Cyan**: `ffffff00`
- **White**: `ffffffff`
- **Black**: `ff000000`

Note: Color codes use AABBGGRR format where:
- `AA` = Alpha (FF = opaque, 7F = semi-transparent)
- `BB` = Blue channel
- `GG` = Green channel
- `RR` = Red channel

#### 📝 Name
Custom pyramid name for identification in KML files

### Configuration Preview
The screen displays a summary of all settings before sending

### Action Buttons
- **Reset**: Restore to default New York blue pyramid
- **Send Pyramid**: Upload to Liquid Galaxy display

## Technical Details

### KML Structure

The pyramid is generated as a valid KML document containing 5 placemarks:
1. **Base** - Square base at ground level
2. **North Face** - Triangular face pointing north
3. **South Face** - Triangular face pointing south
4. **East Face** - Triangular face pointing east
5. **West Face** - Triangular face pointing west

Each face is a `<Polygon>` element with:
- Altitude mode set to `relativeToGround`
- Coordinates representing the triangle vertices
- Shared style for consistent coloring

```xml
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>NYC Pyramid</name>
    <Style id="pyramidStyle">
      <PolyStyle>
        <color>ff0000ff</color>
        ...
      </PolyStyle>
    </Style>
    <Placemark>
      <!-- Base polygon -->
    </Placemark>
    <Placemark>
      <!-- North face -->
    </Placemark>
    <!-- ... other faces ... -->
  </Document>
</kml>
```

### API Implementation

#### `KMLService.sendColoredPyramid()`

```dart
Future<void> sendColoredPyramid({
  required double latitude,
  required double longitude,
  required double altitude,
  double baseSize = 0.01,
  String color = 'ffff0000', // AABBGGRR
  String name = 'Colored Pyramid',
})
```

**Steps**:
1. Generate KML with pyramid geometry
2. Escape special characters for shell command
3. Upload to `/var/www/html/kml/master.kml` via SSH
4. Force refresh of myplaces.kml
5. Pyramid becomes visible in Google Earth on Liquid Galaxy

### State Management

Uses Riverpod's `StateNotifierProvider` for reactive state:

```dart
final pyramidConfigProvider = StateNotifierProvider<_PyramidConfigNotifier, PyramidConfig>
```

State mutations available:
- `setLatitude(double)` - Update latitude
- `setLongitude(double)` - Update longitude
- `setAltitude(double)` - Update peak altitude
- `setBaseSize(double)` - Update base dimensions
- `setColor(String)` - Update color (AABBGGRR format)
- `setName(String)` - Update pyramid name
- `reset()` - Reset to default configuration
- `loadPreset(String, String)` - Load location + color preset

## Examples

### Quick Send to New York (Blue Pyramid)
```dart
await kmlService.sendColoredPyramid(
  latitude: 40.7128,
  longitude: -74.0060,
  altitude: 2000,
  baseSize: 0.01,
  color: 'ffff0000', // Blue
  name: 'NYC Pyramid',
);
```

### Large Red Pyramid in London
```dart
await kmlService.sendColoredPyramid(
  latitude: 51.5074,
  longitude: -0.1278,
  altitude: 5000,
  baseSize: 0.05,
  color: 'ff0000ff', // Red
  name: 'London Landmark',
);
```

### Custom Green Pyramid at Coordinates
```dart
await kmlService.sendColoredPyramid(
  latitude: 35.6895,
  longitude: 139.6917,
  altitude: 1500,
  baseSize: 0.015,
  color: 'ff00ff00', // Green
  name: 'Custom Location Pyramid',
);
```

## Features

✅ **Easy-to-use UI** - Intuitive sliders and buttons
✅ **Preset Locations** - Quick access to major world cities
✅ **Multiple Colors** - 8 predefined color options
✅ **Real-time Preview** - See configuration before sending
✅ **Custom Parameters** - Full control over dimensions
✅ **Responsive Design** - Works on different screen sizes
✅ **SSH Integration** - Seamless deployment to Liquid Galaxy
✅ **Error Handling** - User feedback on success/failure

## Troubleshooting

### Pyramid Not Appearing
1. Verify SSH connection is active
2. Check that coordinates are valid (lat: -90 to 90, lon: -180 to 180)
3. Ensure altitude is between 100m and 10,000m
4. Wait a few seconds for Google Earth to parse the KML

### Color Not Displaying Correctly
- Verify color format is AABBGGRR (8 hex digits)
- Check that alpha channel (AA) is `ff` for full opacity
- Try a predefined color from the dropdown

### Pyramid Too Small/Large
- Adjust the **Base Size** slider
- Increase **Peak Altitude** for a taller pyramid
- Smaller base sizes (0.001-0.005) work well for city-scale features
- Larger base sizes (0.05-0.1) work well for regional features

## Future Enhancements

Potential improvements could include:
- Multiple pyramid shapes (tetrahedron, hexagonal pyramid)
- Model import from external 3D files
- Animation/tour generation around the pyramid
- Real-time geometry editor with preview
- More color palettes and gradients
- Pyramid clustering for multiple shapes at once

## References

- [Liquid Galaxy Documentation](https://liquidgalaxy.github.io/)
- [KML Reference](https://developers.google.com/kml/documentation)
- [Flutter Riverpod](https://riverpod.dev/)
- [LG Controller Project](../../README.md)
