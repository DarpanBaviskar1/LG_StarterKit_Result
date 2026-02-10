# 🏗️ LG Controller Architecture

## System Overview

The LG Controller is a Flutter application that controls Liquid Galaxy installations via SSH. It follows a feature-first architecture with clear separation of concerns.

---

## High-Level Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                      Flutter UI Layer                         │
│  ┌────────────────────────────────────────────────────┐      │
│  │    Screens (ConsumerStatefulWidget)                │      │
│  │    - User interaction                              │      │
│  │    - State management with Riverpod 3.x            │      │
│  └────────────────────────────────────────────────────┘      │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│                    Service Layer                             │
│  ┌────────────────────────────────────────────────────┐      │
│  │  Services (Business Logic)                         │      │
│  │  - lib/services/ (HTTP APIs)                       │      │
│  │  - src/features/home/data/ (SSH/LG core)          │      │
│  └────────────────────────────────────────────────────┘      │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│                  Communication Layer                          │
│  ┌────────────────────────────────────────────────────┐      │
│  │  SSH Service (dartssh2)                            │      │
│  │  HTTP Service (http package)                       │      │
│  └────────────────────────────────────────────────────┘      │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│                   External Systems                            │
│  ┌──────────┐  ┌──────────┐  ┌─────────┐  ┌──────────┐     │
│  │ Liquid   │  │ Gemini   │  │  Free   │  │  Other   │     │
│  │ Galaxy   │  │   AI     │  │  APIs   │  │  APIs    │     │
│  │  (SSH)   │  │ (Flask)  │  │         │  │          │     │
│  └──────────┘  └──────────┘  └─────────┘  └──────────┘     │
└──────────────────────────────────────────────────────────────┘
```

---

## Core Principles

### 1. Feature-First Organization

```
lib/src/features/
├── dashboard/          ← Navigation hub
├── kml_agent/          ← AI KML generation
├── location_lookup/    ← Geocoding
├── weather_overlay/    ← Weather data
└── earthquake_tracker/ ← Seismic data

Each feature contains:
├── models/       ← Data structures
├── providers/    ← State management
├── presentation/ ← UI screens
└── data/         ← Data sources (if needed)
```

**Benefits:**
- ✅ Related code stays together
- ✅ Easy to understand feature scope
- ✅ Can delete entire features cleanly
- ✅ Enables code reuse between projects

### 2. Service Layer Pattern

**Two types of services:**

```
lib/services/               ← HTTP API services
├── agent_service.dart      ← Gemini AI via Flask
├── nominatim_service.dart  ← OpenStreetMap Geocoding
├── weather_service.dart    ← Open-Meteo Weather
└── earthquake_service.dart ← USGS Earthquakes

lib/src/features/home/data/ ← Core LG services
├── ssh_service.dart        ← SSH communication
├── lg_service.dart         ← LG commands
└── kml_service.dart        ← KML management
```

**Why separate?**
- HTTP services are independent, feature-specific
- SSH/LG services are core infrastructure, shared by all features

### 3. State Management with Riverpod 3.x

**Pattern:**
```dart
// 1. Define Provider
final myServiceProvider = Provider((ref) => MyService());

// 2. Use in Widget
class MyScreen extends ConsumerStatefulWidget {
  // Widget implementation
}

class _MyScreenState extends ConsumerState<MyScreen> {
  @override
  Widget build(BuildContext context) {
    final service = ref.read(myServiceProvider);
    // Use service
  }
}
```

**Why Riverpod 3.x?**
- ✅ Type-safe
- ✅ Compile-time error checking
- ✅ Better testing support
- ✅ No BuildContext required for providers

### 4. SSH Communication Pattern

**CRITICAL: Always use `client!.run()`**

```dart
// ✅ CORRECT
await _sshService.client!.run(command);

// ❌ WRONG
await _sshService.execute(command); // Method doesn't exist properly
```

**Why?**
- `client!.run()` is the dartssh2 standard API
- Ensures commands are properly awaited
- Returns CommandResult with stdout/stderr
- Prevents silent failures

### 5. KML Management

**Always send to master, never to numbered slaves:**

```dart
// ✅ CORRECT
await kmlService.sendKmlToMaster(kmlContent);

// ❌ WRONG  
await kmlService.sendKml(kmlContent, slave: 1);
```

**Why?**
- Master (`master.kml`) distributes to all screens automatically
- Direct slave writing causes sync issues
- Follows Liquid Galaxy best practices

---

## Technology Stack

### Frontend
- **Framework:** Flutter 3.x
- **Language:** Dart 3.x
- **State Management:** Riverpod 3.x
- **UI:** Material Design 3

### Backend Services
- **Python Flask** (KML Agent AI wrapper)
- **Google Gemini API** (AI KML generation)

### Communication
- **SSH:** dartssh2 package
- **HTTP:** http package
- **Secure Storage:** shared_preferences

### External APIs (Free)
- **Nominatim** (OpenStreetMap) - Geocoding
- **Open-Meteo** - Weather data
- **USGS** - Earthquake data
- **Gemini AI** - Natural language to KML

---

## Data Flow Examples

### Example 1: User Generates KML with AI

```
User → KmlAgentScreen (UI)
  ↓
ref.read(agentServiceProvider)
  ↓
HTTP POST to Flask (http://localhost:8000/generate-kml)
  ↓
Flask Server → Gemini API
  ↓
Response: KML XML string
  ↓
Display in Flutter UI
  ↓
User clicks "Send to LG"
  ↓
ref.read(kmlServiceProvider).sendKmlToMaster(kml)
  ↓
SSH: echo "$kml" > /var/www/html/master.kml
  ↓
Liquid Galaxy displays visualization
```

### Example 2: User Searches Location

```
User types "Eiffel Tower" → LocationLookupScreen
  ↓
nominatimService.searchLocation("Eiffel Tower")
  ↓
HTTP GET https://nominatim.openstreetmap.org/search?q=Eiffel+Tower
  ↓
Response: [{ lat: 48.8584, lng: 2.2945, name: "Eiffel Tower" }]
  ↓
Display results in ListView
  ↓
User clicks "Fly To"
  ↓
kmlService.flyTo(48.8584, 2.2945, range, tilt, heading)
  ↓
Generate KML with FlyTo tour
  ↓
SSH: Send to master.kml
  ↓
Liquid Galaxy flies to location
```

### Example 3: Display Earthquakes

```
User opens EarthquakeTrackerScreen
  ↓
initState() → _loadEarthquakes()
  ↓
earthquakeService.getEarthquakesByMagnitude(minMagnitude: 4.5)
  ↓
HTTP GET https://earthquake.usgs.gov/earthquakes/feed/.../4.5_week.geojson
  ↓
Parse GeoJSON → List<Earthquake>
  ↓
Display in ListView with magnitude badges
  ↓
User clicks "Show on Map"
  ↓
Generate KML with 50 earthquake Placemarks
  ↓
kmlService.sendKmlToMaster(earthquakeKml)
  ↓
Liquid Galaxy displays earthquake markers
```

---

## File Organization

```
LGWebStarterKit/
├── lg_controller/                     ← Flutter app
│   ├── lib/
│   │   ├── main.dart                  ← App entry point
│   │   ├── services/                  ← HTTP API services
│   │   │   ├── agent_service.dart
│   │   │   ├── nominatim_service.dart
│   │   │   ├── weather_service.dart
│   │   │   └── earthquake_service.dart
│   │   └── src/
│   │       ├── common/theme/
│   │       ├── features/
│   │       │   ├── dashboard/
│   │       │   ├── kml_agent/
│   │       │   ├── location_lookup/
│   │       │   ├── weather_overlay/
│   │       │   ├── earthquake_tracker/
│   │       │   ├── settings/
│   │       │   └── home/
│   │       │       └── data/          ← Core services
│   │       │           ├── ssh_service.dart
│   │       │           ├── lg_service.dart
│   │       │           └── kml_service.dart
│   │       └── ...
│   └── pubspec.yaml
│
├── kml_agent.py                       ← Python AI script
├── flask_server.py                    ← HTTP wrapper for Python
├── public/                            ← Web demos (2D/3D/Snake)
└── server/                            ← Node.js demos
```

---

## Architectural Decisions

### ADR-001: Feature-First Structure
**Decision:** Organize by feature, not by type  
**Rationale:** Better scalability, easier maintenance, clearer boundaries  
**Status:** Accepted (2026-01)

### ADR-002: Service Layer Separation
**Decision:** Split HTTP services (lib/services/) from SSH services (src/features/home/data/)  
**Rationale:** HTTP services are feature-specific, SSH is core infrastructure  
**Status:** Accepted (2026-02)

### ADR-003: Riverpod 3.x for State Management
**Decision:** Use Riverpod instead of Provider  
**Rationale:** Type safety, compile-time checking, better performance  
**Status:** Accepted (2026-01)

### ADR-004: Master KML Only Pattern
**Decision:** Always write to master.kml, never directly to slaves  
**Rationale:** Prevents sync issues, follows LG best practices  
**Status:** Accepted (2025)

### ADR-005: Free APIs First Policy
**Decision:** Prefer free, no-auth APIs (Nominatim, Open-Meteo, USGS)  
**Rationale:** Lower barrier to entry, better for demos and learning  
**Status:** Accepted (2026-02)

### ADR-006: Flask Wrapper for Python AI
**Decision:** Wrap Python AI scripts with Flask HTTP server  
**Rationale:** Enables Flutter to call Python code, separates concerns  
**Status:** Accepted (2026-02)

---

## Security Considerations

### SSH Credentials
- Store in shared_preferences (encrypted by OS)
- Never hardcode in source
- Clear on logout

### API Keys
- Gemini: Environment variable only (GOOGLE_API_KEY)
- Never commit to git
- Use .env files for local development

### User Input
- Validate all user input before SSH commands
- Sanitize KML content
- Use parameterized queries where applicable

---

## Performance Patterns

### Lazy Loading
- Services created only when first accessed
- Providers initialized on-demand
- Image caching for overlays

### Async/Await
- All network calls are async
- All SSH commands use await
- Loading states for user feedback

### Error Handling
- Try-catch blocks around all network operations
- User-friendly error messages
- Retry logic for transient failures

---

## Testing Strategy

### Unit Tests
- Service layer logic
- Model transformations
- Utility functions

### Integration Tests
- SSH commands (with test rig)
- API integrations
- KML generation

### Widget Tests
- Screen rendering
- User interactions
- State updates

---

## Future Architecture Considerations

### Potential Improvements
- [ ] Offline mode with local KML cache
- [ ] Real-time WebSocket updates
- [ ] Multi-LG installation support
- [ ] Plugin architecture for custom features
- [ ] GraphQL for complex queries

### Scalability
- Current: Single Flutter app
- Future: Microservices for different LG installations
- Cloud backend for tour sharing

---

**Last Updated:** 2026-02-10  
**Version:** 2.0  
**Maintainer:** LG Web Starter Kit Team
