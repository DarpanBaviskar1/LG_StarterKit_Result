# Enhanced LG Controller - Implementation Plan
**Date:** February 7, 2026  
**Project:** Liquid Galaxy Controller with System Control, Logo Management, and ISS Integration

---

## 📋 Project Overview

An enhanced Flutter app extending the existing `lg_controller` with:
1. **System Control**: Shutdown, Reboot, Relaunch operations on Liquid Galaxy rig
2. **Logo Management**: Send/Clear logo on slave_3 screen
3. **Geographic Navigation**: Fly to New York with animated KML transitions
4. **ISS Integration**: Fetch ISS real-time location via API and fly there
5. **State Management**: Riverpod-based state for connectivity & operations

**Key Principle**: All SSH operations use `await _sshService.client!.run(command)` per GOLDEN_RULES.md

---

## 🏗 Architecture

### Folder Structure
```
lib/
├── src/
│   ├── features/
│   │   ├── system_control/
│   │   │   ├── models/
│   │   │   │   └── system_operation.dart
│   │   │   ├── providers/
│   │   │   │   └── system_control_provider.dart
│   │   │   ├── screens/
│   │   │   │   └── system_control_screen.dart
│   │   │   └── services/
│   │   │       └── lg_system_service.dart
│   │   ├── logo_management/
│   │   │   ├── providers/
│   │   │   │   └── logo_provider.dart
│   │   │   ├── screens/
│   │   │   │   └── logo_screen.dart
│   │   │   └── services/
│   │   │       └── logo_service.dart
│   │   ├── navigation/
│   │   │   ├── models/
│   │   │   │   └── location.dart
│   │   │   ├── providers/
│   │   │   │   └── navigation_provider.dart
│   │   │   ├── screens/
│   │   │   │   └── navigation_screen.dart
│   │   │   └── services/
│   │   │       └── navigation_service.dart
│   │   ├── iss_tracker/
│   │   │   ├── models/
│   │   │   │   └── iss_location.dart
│   │   │   ├── providers/
│   │   │   │   └── iss_provider.dart
│   │   │   ├── screens/
│   │   │   │   └── iss_tracker_screen.dart
│   │   │   └── services/
│   │   │       └── iss_service.dart
│   │   └── home/
│   │       ├── screens/
│   │       │   └── home_screen.dart
│   │       └── widgets/
│   │           └── feature_cards.dart
│   ├── shared/
│   │   ├── services/
│   │   │   ├── ssh_service.dart (Enhanced)
│   │   │   └── kml_builder.dart
│   │   ├── utils/
│   │   │   └── result.dart (Success/Failure wrapper)
│   │   ├── models/
│   │   │   └── app_connection_state.dart
│   │   └── providers/
│   │       └── connection_provider.dart
│   └── constants/
│       ├── lg_constants.dart
│       └── iss_api_constants.dart
├── main.dart
└── app.dart
```

---

## 🔧 Core Services

### 1. Enhanced SSH Service
**File**: `lib/src/shared/services/ssh_service.dart`

Features:
- Connection management (connect/disconnect)
- Command execution with proper error handling
- Follows GOLDEN_RULE: `await _sshService.client!.run(command)`
- Timeout handling and logging

```dart
class SSHService {
  SSHClient? _client;
  bool _isConnected = false;
  
  // Core methods:
  Future<bool> connect(String host, String username, String password)
  Future<void> disconnect()
  Future<String> run(String command)  // Uses client!.run()
}
```

### 2. LG System Service
**File**: `lib/src/features/system_control/services/lg_system_service.dart`

Operations:
- `shutdown()`: Powers off all LG machines
- `reboot()`: Restarts all LG machines
- `relaunch()`: Restarts the LG controller application

Each operation:
1. Validates SSH connection
2. Executes via `client!.run()`
3. Includes 1-2 sec delays between commands (for parsing)
4. Returns boolean success/failure

### 3. Logo Service
**File**: `lib/src/features/logo_management/services/logo_service.dart`

Operations:
- `sendLogo(imageData, slaveId)`: Uploads image to slave_3 KML
- `clearLogo(slaveId)`: Removes logo from slave_3 KML

Uses KML Generator to create overlay KML with image path.

### 4. Navigation Service
**File**: `lib/src/features/navigation/services/navigation_service.dart`

Operations:
- `flyToNewYork()`: Generates NYC KML with coordinates
- `flyToLocation(lat, lng, name)`: Generic fly-to operation
- Uses KML Master file pattern per GOLDEN_RULES

### 5. ISS Service
**File**: `lib/src/features/iss_tracker/services/iss_service.dart`

Operations:
- `fetchISSLocation()`: Calls ISS API (e.g., api.open-notify.org/iss-now.json)
- Returns latitude/longitude
- Integrates with Navigation Service to auto-fly

---

## 📡 State Management (Riverpod)

### Providers Structure

```dart
// Connection state (global)
final sshServiceProvider = Provider<SSHService>(...);
final connectionStateProvider = StateNotifierProvider<ConnectionStateNotifier, ConnectionState>(...);

// Feature-specific providers
final systemControlProvider = Provider<LGSystemService>(...);
final logoProvider = StateNotifierProvider<LogoNotifier, LogoState>(...);
final navigationProvider = Provider<NavigationService>(...);
final issProvider = FutureProvider<ISSLocation>...);
```

---

## 🎯 Features Implementation Sequence

### Phase 1: Foundation
1. ✅ Enhanced SSH Service
2. ✅ Connection Management UI
3. ✅ KML Builder utility

### Phase 2: System Control
4. ✅ Shutdown operation
5. ✅ Reboot operation
6. ✅ Relaunch operation
7. ✅ System Control Screen UI

### Phase 3: Logo Management
8. ✅ Logo upload mechanism
9. ✅ Clear logo mechanism
10. ✅ Logo screen with image preview

### Phase 4: Navigation
11. ✅ KML generation for fly-to NYC
12. ✅ Navigation screen with location list
13. ✅ Animation/transition handling

### Phase 5: ISS Integration
14. ✅ ISS API service
15. ✅ Real-time location fetching (polling)
16. ✅ ISS Tracker screen with auto-fly button
17. ✅ Location display (latitude/longitude/altitude)

### Phase 6: UI Polish & Integration
18. ✅ Dashboard with all features
19. ✅ Error handling & user feedback (toasts/animations)
20. ✅ Testing & documentation

---

## 🛠 Key Implementation Details

### A. SSH Connection String (per GOLDEN_RULES)

```dart
// For shutdown (with sshpass multiscreen support)
final command = 'sshpass -p "$password" ssh -o StrictHostKeyChecking=no lg$i "(echo $password; sleep 1) | sudo -S poweroff"';
await _sshService.client!.run(command);
```

### B. KML Structure for Logo

```xml
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <ScreenOverlay id="logo_slave_3">
      <name>Logo Overlay</name>
      <Icon>
        <href>/var/www/html/images/logo.png</href>
      </Icon>
      <overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
      <screenXY x="0" y="1" xunits="fraction" yunits="fraction"/>
      <rotationXY x="0" y="0" xunits="fraction" yunits="fraction"/>
      <size x="0" y="0" xunits="pixels" yunits="pixels"/>
    </ScreenOverlay>
  </Document>
</kml>
```

### C. NYC Coordinates
- Latitude: 40.7128
- Longitude: -74.0060
- Altitude: 2000m

### D. ISS API Endpoint
- URL: `https://api.open-notify.org/iss-now.json`
- Response: `{iss_position: {latitude: "...", longitude: "..."}}`
- Poll interval: 10-30 seconds

---

## 📦 Dependencies (pubspec.yaml)

```yaml
# Already in lg_controller:
- flutter_riverpod: ^2.6.1
- dartssh2: ^2.10.0
- http: ^1.2.1
- shared_preferences: ^2.3.2

# New (add if needed):
# None expected - ISS API uses existing http package
```

---

## ✅ Testing Strategy

1. **Unit Tests**: Service layer (SSHService, LGSystemService, ISSService)
2. **Integration Tests**: SSH → KML flow
3. **Manual Tests**: Connect to test LG rig, verify operations
4. **ISS API Tests**: Mock HTTP responses

---

## 📊 Success Criteria

- ✅ All SSH operations use `client!.run()` (no race conditions)
- ✅ System control buttons work (Shutdown/Reboot/Relaunch)
- ✅ Logo upload/clear on slave_3 successful
- ✅ NYC fly-to animates smoothly
- ✅ ISS tracker fetches live location every 30 seconds
- ✅ ISS fly-to navigates to real-time ISS position
- ✅ Error handling graceful (toasts for failures)
- ✅ UI responsive on tablet (portrait/landscape)

---

## 🚀 Implementation Timeline

| Phase | Features | Estimated Time |
|-------|----------|-----------------|
| 1 | Foundation (SSH, Riverpod, KML) | 2-3 hours |
| 2 | System Control | 1-2 hours |
| 3 | Logo Management | 1-2 hours |
| 4 | Navigation/NYC | 1 hour |
| 5 | ISS Integration | 1-2 hours |
| 6 | Polish & Testing | 1-2 hours |

**Total Estimate**: 7-13 hours

---

## 🎓 Links to .agent Documentation

- **GOLDEN_RULES**: Foundation for SSH operations
- **Flutter SKILL**: Architecture and patterns
- **Best Practices**: Code organization and Riverpod usage
- **Code Templates**: Ready-to-use SSH/KML snippets

---

**Status**: Planning Complete ✅  
**Next Step**: Initialize project and implement Phase 1 (Foundation)
