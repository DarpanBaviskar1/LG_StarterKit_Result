# Quick Start: Flutter + Liquid Galaxy 🚀

Get building in 5 minutes.

## 1. Project Structure (30 seconds)

```
lib/src/
├── features/
│   ├── connection/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   └── widgets/
│   ├── dashboard/
│   └── settings/
├── services/
│   ├── ssh_service.dart
│   └── lg_service.dart
├── utils/
│   └── kml/
├── constants/
└── models/

main.dart
app.dart
```

**Why?** → Feature-first keeps related code together. See `01-core-patterns/project-structure.md`

## 2. The Three Core Concepts (2 minutes)

### Concept 1: SSH Service
Connect to LG and run commands:

```dart
// In services/ssh_service.dart
import 'package:dartssh2/dartssh2.dart';

class SSHService {
  SSHClient? _client;
  
  Future<bool> connect(String host, String user, String password) async {
    try {
      final socket = await SSHSocket.connect(host, 22, 
        timeout: Duration(seconds: 10));
      _client = SSHClient(socket, username: user, 
        onPasswordRequest: () => password);
      return true;
    } catch (e) {
      debugPrint('SSH Error: $e');
      return false;
    }
  }
  
  Future<String?> execute(String command) async {
    if (_client == null) return null;
    try {
      final result = await _client!.run(command);
      return utf8.decode(result);
    } catch (e) {
      return null;
    }
  }
}
```

👉 Deep dive: `01-core-patterns/ssh-communication.md`  
👉 Full template: `03-code-templates/ssh-service.dart`  
👉 Issues? `07-troubleshooting/ssh-connection-issues.md`

### Concept 2: KML Builder
Generate KML to fly/display on LG:

```dart
// In utils/kml/kml_builder.dart
class KMLBuilder {
  static String buildFlyTo({
    required double lat,
    required double lng,
    required double range,
    double tilt = 60,
    double heading = 0,
  }) {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" 
     xmlns:gx="http://www.google.com/kml/ext/2.2">
  <LookAt>
    <longitude>$lng</longitude>
    <latitude>$lat</latitude>
    <range>$range</range>
    <tilt>$tilt</tilt>
    <heading>$heading</heading>
  </LookAt>
</kml>''';
  }
}
```

👉 Deep dive: `01-core-patterns/kml-management.md`  
👉 Full template: `03-code-templates/kml-builder.dart`  
👉 Issues? `07-troubleshooting/kml-validation-errors.md`

### Concept 3: Riverpod Providers
Manage connection state globally:

```dart
// In providers/connection_provider.dart
final sshServiceProvider = Provider<SSHService>((ref) => SSHService());

final connectionStateProvider = StateNotifierProvider<
  ConnectionNotifier, ConnectionState>((ref) {
  return ConnectionNotifier(ref.watch(sshServiceProvider));
});
```

👉 Deep dive: `01-core-patterns/state-management.md`  
👉 Full template: `03-code-templates/connection-provider.dart`  
👉 Mistakes to avoid: `04-anti-patterns/state-management-mistakes.md`

## 3. Build Your First Feature (2.5 minutes)

Pick your path:

### Path A: Connection Screen
Build a screen to connect to LG.
👉 Go to: `02-implementation-guides/connection-feature.md`

### Path B: Fly to Location
Create a button that flies to coordinates.
👉 Go to: `02-implementation-guides/fly-to-location.md`

### Path C: Tour Feature
Create a multi-point guided tour.
👉 Go to: `02-implementation-guides/tour-feature.md`

### Path D: Data Visualization
Display data points on LG.
👉 Go to: `02-implementation-guides/data-visualization.md`

### Path E: Custom Feature
Not sure? Ask the agent:
- Describe what you want to build
- They'll match it to a pattern
- They'll give you step-by-step guide

## 4. Copy Template Code (30 seconds)

All ready-to-use templates in `03-code-templates/`:
- `ssh-service.dart` - Copy your SSH service
- `lg-service.dart` - Copy your LG operations
- `kml-builder.dart` - Copy KML generation
- `connection-provider.dart` - Copy Riverpod setup
- `connection-screen.dart` - Copy UI example

Just copy, adjust names, and you're good!

## 5. Check Quality Before Shipping

Before you ship, use this checklist:
👉 `06-quality-standards/code-review-checklist.md`

Quick version:
- ✅ All SSH operations have try-catch
- ✅ All operations have 10-second timeout
- ✅ KML includes XML declaration
- ✅ Coordinates validated (-90 to 90 lat, -180 to 180 lng)
- ✅ Loading states shown
- ✅ Error messages displayed
- ✅ Resources disposed properly
- ✅ No hardcoded credentials

---

## 🎯 Next Steps

**Just started?**
→ Pick a path above (A, B, C, or D)

**Want overview?**
→ Read `SKILL.md`

**Want deep knowledge?**
→ Read `best-practices.md`

**Need inspiration?**
→ Check `05-real-world-examples/`

**Stuck?**
→ Go to `07-troubleshooting/common-questions.md`

---

**Remember**: All patterns based on open-source LiquidGalaxyLAB projects.  
**References**: https://github.com/LiquidGalaxyLAB/  
**Time to first feature**: ~30 minutes with templates
