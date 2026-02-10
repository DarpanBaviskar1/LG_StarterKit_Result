# Smart Tour Builder Feature

## Overview
The Smart Tour Builder is an AI-powered feature that allows users to create and manage tours with:
- **Visual map-based waypoint placement** using flutter_map
- **AI-powered tour suggestions** via Gemini API
- **KML export** for Liquid Galaxy playback
- **Tour persistence** in SharedPreferences
- **Full CRUD operations** on tours

## Setup Instructions

### 1. Get Gemini API Key
1. Go to https://ai.google.dev
2. Click "Get API Key" in Google AI Studio
3. Select or create a Google Project
4. Copy your API Key

### 2. Configure API Key in the App
Update `lib/src/features/tour_builder/data/tour_provider.dart`:

```dart
final geminiServiceProvider = Provider<GeminiService>((ref) {
  const apiKey = 'YOUR_GEMINI_API_KEY_HERE'; // ← Replace here
  return GeminiService(apiKey: apiKey);
});
```

### 3. Dependencies Added
The feature requires these packages (already in pubspec.yaml):
- `flutter_map: ^6.1.0` - Map UI with OpenStreetMap tiles
- `latlong2: ^0.9.1` - Latitude/Longitude utilities
- `uuid: ^4.0.0` - Unique ID generation
- `dio: ^5.9.1` - HTTP client (already in project)

## Features

### 1. Manual Tour Builder
1. Tap "Smart Tours" on Dashboard
2. Tap "New Tour" FAB
3. Enter tour name and description
4. **Tap on map to place waypoints** (red pins)
5. Edit each waypoint with name, description, duration
6. Save tour

### 2. AI-Powered Suggestions
1. Tap "Smart Tours" on Dashboard
2. Tap "AI Suggest" FAB
3. Enter description: "Roman Empire historical sites"
4. Gemini generates 3-5 waypoints with real coordinates
5. Review and edit in the builder, then save

### 3. Tour Management
- **View**: List of all saved tours with waypoint counts and duration
- **Edit**: Tap tour → modify waypoints/metadata → Save
- **Delete**: Popup menu → Delete
- **Export**: Tap tour → Export KML → Copy to clipboard

### 4. KML Export
Tours are exported as standard KML files ready for Liquid Galaxy:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Tour Name</name>
    <Placemark>
      <name>Waypoint 1</name>
      <coordinates>lat,lon,0</coordinates>
    </Placemark>
    ...
  </Document>
</kml>
```

## Architecture

```
tour_builder/
├── domain/
│   └── models/
│       ├── waypoint.dart       # Single waypoint in tour
│       └── tour.dart           # Complete tour with metadata
├── data/
│   ├── gemini_service.dart     # AI generation via Gemini
│   ├── tour_service.dart       # CRUD + KML export
│   └── tour_provider.dart      # Riverpod providers
└── presentation/
    ├── tours_screen.dart       # Tour list & management
    ├── tour_builder_screen.dart # Map-based editor
    └── ai_tour_dialog.dart     # AI suggestion dialog
```

## Data Models

### Waypoint
```dart
Waypoint(
  id: 'wp_uuid',
  latitude: 40.7128,
  longitude: -74.0060,
  name: 'New York',
  description: 'The Big Apple',
  durationSeconds: 5,
  order: 0,
)
```

### Tour
```dart
Tour(
  id: 'tour_uuid',
  name: 'US Tour',
  description: 'Famous US landmarks',
  waypoints: [wp1, wp2, wp3],
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
)
```

## Integration with Liquid Galaxy

After saving a tour and exporting KML:

1. Copy KML content
2. Send to LG master via SSH:
   ```bash
   echo "$KML_CONTENT" > /var/www/html/kml/tour.kml
   echo "playtour=TourName" > /tmp/query.txt
   ```
3. Tour plays on Liquid Galaxy display

## Troubleshooting

### "API key invalid" Error
- Check Gemini API key in `tour_provider.dart`
- Ensure API key has quota remaining
- Visit https://ai.google.dev/pricing to check free tier limits

### Map not loading
- Check internet connection (uses OpenStreetMap tiles)
- Ensure `flutter_map` and `latlong2` are installed
- Run `flutter pub get`

### Tours not persisting
- Check SharedPreferences permissions (Android/iOS)
- Ensure app has write permission to device storage

## Future Enhancements
- [ ] Route optimization (shortest path between waypoints)
- [ ] Elevation/altitude profiles
- [ ] Tour playback with animation
- [ ] Cloud sync via Firebase
- [ ] Offline map support
- [ ] Tour templates (famous routes pre-built)
- [ ] Real-time ISS tracking integration

## Examples

### Create tour programmatically:
```dart
final tour = Tour(
  id: 'tour-1',
  name: 'Europe Trip',
  description: 'A 7-day European tour',
  waypoints: [
    Waypoint(
      id: 'wp-1',
      name: 'Paris',
      latitude: 48.8566,
      longitude: 2.3522,
      description: 'Eiffel Tower',
      durationSeconds: 5,
      order: 0,
    ),
    // ...
  ],
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

await ref.read(toursProvider.notifier).addTour(tour);
```

### Generate KML:
```dart
final tourService = ref.read(tourServiceProvider);
final kml = tourService.generateKML(tour);
print(kml); // XML string ready for LG
```
