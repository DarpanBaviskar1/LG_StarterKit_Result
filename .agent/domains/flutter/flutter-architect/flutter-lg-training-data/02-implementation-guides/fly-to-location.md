---
title: Implementing Fly-To Navigation
folder: 02-implementation-guides
tags: [implementation, navigation, kml, step-by-step]
related:
  - ../01-core-patterns/kml-management.md
  - ../03-code-templates/kml-builder.dart
  - ../03-code-templates/lg-service.dart
difficulty: intermediate
time-to-read: 12 min
---

# Implementing Fly-To Navigation: Step-by-Step 🚀

Fly-To is the most common LG feature. Let's implement it properly.

## What We're Building

A feature that:
1. Allows users to select locations
2. Flies camera to that location
3. Shows loading state
4. Handles errors

## Step 1: Create Location Model

**File: `lib/src/features/navigation/models/location.dart`**

```dart
import 'package:equatable/equatable.dart';

class Location extends Equatable {
  final String name;
  final double latitude;
  final double longitude;
  final double altitude;
  final double heading;
  final double tilt;
  final double range;
  final String? description;
  final String? imageUrl;

  const Location({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.altitude = 0.0,
    this.heading = 0.0,
    this.tilt = 45.0,
    this.range = 5000.0,
    this.description,
    this.imageUrl,
  });

  // Validate coordinates
  bool get isValid {
    return latitude >= -90 && latitude <= 90 &&
        longitude >= -180 && longitude <= 180;
  }

  @override
  List<Object?> get props => [
    name, latitude, longitude, altitude, heading, tilt, range
  ];
}
```

## Step 2: Create KML Builder

**File: `lib/src/utils/kml/kml_builder.dart`**

```dart
class KMLBuilder {
  // Build FlyTo command
  static String buildFlyTo({
    required double latitude,
    required double longitude,
    required double altitude,
    double heading = 0,
    double tilt = 45,
    double range = 5000,
    double duration = 3.0,
  }) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <LookAt>
      <longitude>$longitude</longitude>
      <latitude>$latitude</latitude>
      <altitude>$altitude</altitude>
      <heading>$heading</heading>
      <tilt>$tilt</tilt>
      <range>$range</range>
    </LookAt>
  </Document>
</kml>''';
  }

  // Build with duration
  static String buildFlyToWithDuration({
    required double latitude,
    required double longitude,
    required double altitude,
    double heading = 0,
    double tilt = 45,
    double range = 5000,
    double duration = 3.0,
  }) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2"
     xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <gx:Tour>
      <name>Fly</name>
      <gx:Playlist>
        <gx:FlyTo>
          <gx:duration>${duration.toStringAsFixed(1)}</gx:duration>
          <Camera>
            <longitude>$longitude</longitude>
            <latitude>$latitude</latitude>
            <altitude>$altitude</altitude>
            <heading>$heading</heading>
            <tilt>$tilt</tilt>
            <roll>0</roll>
          </Camera>
        </gx:FlyTo>
      </gx:Playlist>
    </gx:Tour>
  </Document>
</kml>''';
  }
}
```

## Step 3: Create LG Service

**File: `lib/src/services/lg_service.dart`**

```dart
import 'package:dartssh2/dartssh2.dart';
import '../utils/kml/kml_builder.dart';
import '../features/navigation/models/location.dart';

class LGService {
  final SSHClient _ssh;

  LGService(this._ssh);

  bool get isConnected => _ssh.isClosed == false;

  /// Fly to a location
  Future<void> flyTo(Location location) async {
    if (!isConnected) {
      throw Exception('SSH not connected');
    }

    if (!location.isValid) {
      throw Exception('Invalid coordinates');
    }

    final kml = KMLBuilder.buildFlyToWithDuration(
      latitude: location.latitude,
      longitude: location.longitude,
      altitude: location.altitude,
      heading: location.heading,
      tilt: location.tilt,
      range: location.range,
      duration: 3.0,
    );

    await _executeKML(kml);
  }

  /// Send KML to LG
  Future<void> _executeKML(String kml) async {
    try {
      // Write KML to file
      await _ssh.run(
        'echo \'$kml\' > /tmp/flyto.kml'
      );

      // Wait for file to be written
      await Future.delayed(Duration(milliseconds: 500));

      // Tell LG to load it
      await _ssh.run(
        'echo "http://localhost:3001/kml" > /tmp/query.txt'
      );
    } catch (e) {
      debugPrint('❌ KML execution failed: $e');
      rethrow;
    }
  }

  /// Zoom in
  Future<void> zoomIn() async {
    await _executeCommand('echo "35.0,0,45.0,1000" > /tmp/orbit_cmd');
  }

  /// Zoom out
  Future<void> zoomOut() async {
    await _executeCommand('echo "0,0,0,10000" > /tmp/orbit_cmd');
  }

  Future<void> _executeCommand(String cmd) async {
    if (!isConnected) throw Exception('Not connected');
    await _ssh.run(cmd);
  }
}
```

## Step 4: Create Navigation Provider

**File: `lib/src/features/navigation/providers/navigation_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/location.dart';
import '../../../services/lg_service.dart';
import '../../../services/ssh_service.dart';

class NavigationState {
  final bool isFlying;
  final String? errorMessage;
  final Location? currentLocation;

  const NavigationState({
    this.isFlying = false,
    this.errorMessage,
    this.currentLocation,
  });

  NavigationState copyWith({
    bool? isFlying,
    String? errorMessage,
    Location? currentLocation,
  }) {
    return NavigationState(
      isFlying: isFlying ?? this.isFlying,
      errorMessage: errorMessage,
      currentLocation: currentLocation ?? this.currentLocation,
    );
  }
}

// LG Service provider
final lgServiceProvider = Provider<LGService>((ref) {
  // This should come from your connection
  // For now, assume SSH is available
  return LGService(sshClient);
});

// Navigation notifier
class NavigationNotifier extends StateNotifier<NavigationState> {
  final LGService _lg;

  NavigationNotifier(this._lg) : super(const NavigationState());

  Future<void> flyTo(Location location) async {
    state = state.copyWith(isFlying: true, errorMessage: null);

    try {
      await _lg.flyTo(location);
      state = state.copyWith(
        isFlying: false,
        currentLocation: location,
      );
    } catch (e) {
      state = state.copyWith(
        isFlying: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final navigationProvider = StateNotifierProvider<
  NavigationNotifier, NavigationState>((ref) {
  final lg = ref.watch(lgServiceProvider);
  return NavigationNotifier(lg);
});
```

## Step 5: Create Locations List

**File: `lib/src/features/navigation/providers/locations_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/location.dart';

final locationsProvider = Provider<List<Location>>((ref) {
  return [
    Location(
      name: 'Statue of Liberty',
      latitude: 40.6892,
      longitude: -74.0445,
      altitude: 0,
      heading: 0,
      tilt: 45,
      range: 500,
      description: 'Liberty Island, New York',
      imageUrl: 'assets/liberty.jpg',
    ),
    Location(
      name: 'Eiffel Tower',
      latitude: 48.8584,
      longitude: 2.2945,
      altitude: 0,
      heading: 0,
      tilt: 45,
      range: 800,
      description: 'Paris, France',
      imageUrl: 'assets/eiffel.jpg',
    ),
    Location(
      name: 'Big Ben',
      latitude: 51.4975,
      longitude: -0.1245,
      altitude: 0,
      heading: 0,
      tilt: 45,
      range: 600,
      description: 'London, United Kingdom',
      imageUrl: 'assets/bigben.jpg',
    ),
  ];
});
```

## Step 6: Create Location Card Widget

**File: `lib/src/features/navigation/widgets/location_card.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/location.dart';
import '../providers/navigation_provider.dart';

class LocationCard extends ConsumerWidget {
  final Location location;

  const LocationCard(this.location);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navState = ref.watch(navigationProvider);
    final isActive = navState.currentLocation == location;
    final isFlying = navState.isFlying;

    return Card(
      child: InkWell(
        onTap: () {
          ref.read(navigationProvider.notifier).flyTo(location);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (location.imageUrl != null)
              Image.asset(
                location.imageUrl!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8,
                children: [
                  Text(
                    location.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (location.description != null)
                    Text(
                      location.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: isFlying
                        ? null
                        : () {
                            ref
                                .read(navigationProvider.notifier)
                                .flyTo(location);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isActive ? Colors.blue : Colors.grey.shade300,
                    ),
                    child: isFlying
                        ? SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            isActive ? 'Current Location' : 'Fly To',
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.black,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

## Step 7: Create Navigation Screen

**File: `lib/src/features/navigation/screens/navigation_screen.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/locations_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/location_card.dart';

class NavigationScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locations = ref.watch(locationsProvider);
    final navState = ref.watch(navigationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Navigate to Locations'),
      ),
      body: Column(
        children: [
          if (navState.errorMessage != null)
            Container(
              padding: EdgeInsets.all(12),
              color: Colors.red.shade100,
              child: Text(
                '❌ ${navState.errorMessage}',
                style: TextStyle(color: Colors.red),
              ),
            ),
          if (navState.currentLocation != null)
            Container(
              padding: EdgeInsets.all(12),
              color: Colors.green.shade100,
              child: Text(
                '✅ Current: ${navState.currentLocation!.name}',
                style: TextStyle(color: Colors.green.shade900),
              ),
            ),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: locations.length,
              itemBuilder: (context, index) {
                return LocationCard(locations[index]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

## Checklist ✓

- [ ] Create Location model
- [ ] Create KML builder with FlyTo
- [ ] Create LG service
- [ ] Create navigation provider
- [ ] Create locations provider with sample data
- [ ] Create LocationCard widget
- [ ] Create NavigationScreen
- [ ] Test with real LG device
- [ ] Add duration parameter
- [ ] Add coordinate validation
- [ ] Handle SSH errors

## Best Practices

✅ Always validate coordinates  
✅ Add error handling  
✅ Show loading state  
✅ Keep current location in state  
✅ Separate models, services, UI  
✅ Use providers for dependency injection  
✅ Test with real LG device early  

## Common Issues

**Coordinates are 0,0**
→ Check latitude/longitude are correct  
→ Verify units (degrees, not radians)  

**Camera doesn't move**
→ Check range is appropriate  
→ Check tilt value (45 is good start)  
→ Check heading (0 = north)  

**KML not loading**
→ Check file path is correct  
→ Check XML syntax is valid  
→ Check SSH connection is alive  

## Next Steps

1. Read [KML Management](../01-core-patterns/kml-management.md)
2. Reference [SSH Communication](../01-core-patterns/ssh-communication.md)
3. Check [Code Templates](../03-code-templates/kml-builder.dart)
4. Review [Anti-Patterns](../04-anti-patterns/)

---

**Rule of Thumb**: Fly-To is your most basic feature. Test it before adding complexity.
