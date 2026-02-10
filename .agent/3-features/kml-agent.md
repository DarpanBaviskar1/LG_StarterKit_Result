# KML Agent - Natural Language to KML Generator

## Overview
The KML Agent feature allows users to generate KML (Keyhole Markup Language) files from natural language prompts using Google's Gemini AI. Users can describe what they want to visualize on Liquid Galaxy, and the AI generates the appropriate KML code.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Flutter App (UI)                        │
│  ┌────────────────────────────────────────────────────┐    │
│  │         KML Agent Screen (Dart/Flutter)            │    │
│  │  - Text input for natural language prompts         │    │
│  │  - Quick example chips                              │    │
│  │  - View/Edit KML preview                            │    │
│  │  - Send to Liquid Galaxy                            │    │
│  │  - Play tour, Copy, Clear actions                   │    │
│  └────────────────────────────────────────────────────┘    │
│                          ↓ HTTP POST                        │
│  ┌────────────────────────────────────────────────────┐    │
│  │         Agent Service (Dart HTTP Client)           │    │
│  │  - Handles API communication                        │    │
│  │  - Platform-specific URLs (Android/iOS/Web)        │    │
│  │  - Error handling and timeouts                      │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│              Flask HTTP Server (Python)                     │
│  ┌────────────────────────────────────────────────────┐    │
│  │              flask_server.py                        │    │
│  │  - /health - Health check endpoint                  │    │
│  │  - /generate-kml - Single KML generation            │    │
│  │  - /generate-kml-batch - Batch generation           │    │
│  │  - /validate-kml - KML validation                   │    │
│  └────────────────────────────────────────────────────┘    │
│                          ↓                                  │
│  ┌────────────────────────────────────────────────────┐    │
│  │              kml_agent.py                           │    │
│  │  - KMLAgent class with Gemini integration           │    │
│  │  - System prompt engineering                        │    │
│  │  - KML validation logic                             │    │
│  └────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│              Google Gemini API                              │
│  - Model: gemini-1.5-flash-002                              │
│  - Converts natural language → KML                          │
│  - Returns pure KML XML (no markdown)                       │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. Flutter UI Layer

#### File: `lib/src/features/kml_agent/presentation/kml_agent_screen.dart`

**Purpose:** User interface for KML generation and management

**Features:**
- Text input field for natural language prompts
- Quick example chips for common queries
- KML preview with syntax highlighting
- Edit mode for manual KML modifications
- Action buttons:
  - **Generate KML** - Send prompt to AI
  - **View** - Show KML in read-only mode
  - **Edit** - Enable KML editing
  - **Send to LG** - Send KML to Liquid Galaxy
  - **Play Tour** - Execute tour animations
  - **Copy** - Copy KML to clipboard
  - **Clear** - Delete current KML

**Key State Management:**
```dart
- _controller: TextEditingController for prompt input
- _kmlController: TextEditingController for KML display/edit
- _isLoading: Loading state indicator
- _isEditMode: Toggle between view/edit modes
```

#### File: `lib/src/features/dashboard/presentation/dashboard_screen.dart`

**Purpose:** Dashboard integration

**Changes:**
- Added "KML Agent" card to dashboard grid
- Navigation to `KmlAgentScreen`
- Icon: `Icons.psychology` (AI brain icon)

### 2. Service Layer

#### File: `lib/services/agent_service.dart`

**Purpose:** HTTP client for Flask server communication

**Key Methods:**

```dart
// Generate KML from natural language
Future<String> generateKmlFromPrompt(String userPrompt)

// Check server health
Future<bool> checkHealth()

// Validate KML format
Future<bool> validateKml(String kml)
```

**Platform-Specific URLs:**
- Android Emulator: `http://10.0.2.2:8000`
- iOS Simulator: `http://localhost:8000`
- Web/Desktop: `http://localhost:8000`

**Error Handling:**
- `SocketException`: Server not reachable
- `TimeoutException`: Request timeout (60s)
- `ClientException`: HTTP client errors
- HTTP status codes: 200 (success), 500 (server error)

### 3. Python Backend

#### File: `flask_server.py`

**Purpose:** HTTP server wrapping the KML Agent

**Endpoints:**

| Method | Endpoint | Description | Request Body | Response |
|--------|----------|-------------|--------------|----------|
| GET | `/health` | Server health check | None | `{"status": "healthy", "service": "kml-agent"}` |
| POST | `/generate-kml` | Generate single KML | `{"query": "string"}` | `{"kml": "string", "query": "string"}` |
| POST | `/generate-kml-batch` | Batch generation | `{"queries": ["string"]}` | `{"results": [{"kml": "string"}]}` |
| POST | `/validate-kml` | Validate KML | `{"kml": "string"}` | `{"valid": boolean, "error": "string"}` |

**Configuration:**
```python
host='0.0.0.0'  # Accept connections from network
port=8000       # Default port
debug=False     # Production mode
```

#### File: `kml_agent.py`

**Purpose:** Core AI logic for KML generation

**Class: KMLAgent**

```python
def __init__(self, api_key: Optional[str] = None)
    # Initialize Gemini API with API key
    
def generate_kml(self, prompt: str) -> str
    # Generate KML from natural language prompt
    # Returns: Pure KML XML string
    
@staticmethod
def _build_system_prompt() -> str
    # Constructs system prompt for Gemini
    
@staticmethod
def _is_valid_kml(kml: str) -> bool
    # Validates KML format
```

**System Prompt Engineering:**

The system prompt is carefully crafted to ensure Gemini returns **only** KML XML:

```
You are a KML (Keyhole Markup Language) generator for Liquid Galaxy.

CRITICAL: Output ONLY the KML XML code. Do NOT include:
- Any explanations or markdown
- Code block markers (```)
- Comments outside the KML
- Any text before or after the KML

Generate valid KML that includes:
1. Proper XML declaration
2. KML namespace declarations
3. Placemarks, Points, LineStrings as needed
4. gx:Tour for animations (flyTo, wait)
5. Coordinates in longitude,latitude,altitude format
6. Descriptive names and descriptions
```

**Model Configuration:**
- Model: `gemini-1.5-flash-002`
- Provider: Google Generative AI
- Temperature: Default (balanced creativity/accuracy)

## Setup Instructions

### Prerequisites

1. **Python 3.8+**
2. **Flutter SDK**
3. **Google Gemini API Key** - Get from [Google AI Studio](https://aistudio.google.com/app/apikey)
4. **Dependencies:**
   ```bash
   pip install flask google-generativeai python-dotenv
   ```

### Installation Steps

#### 1. Set API Key (Windows PowerShell)

```powershell
# Temporary (current session)
$env:GOOGLE_API_KEY = "your-api-key-here"

# Permanent (user environment)
[System.Environment]::SetEnvironmentVariable('GOOGLE_API_KEY', 'your-api-key', 'User')
```

#### 2. Start Flask Server

```powershell
cd c:\Users\darpa\OneDrive\Desktop\Work\antigravity\LGWebStarterKit
python flask_server.py
```

**Expected Output:**
```
============================================================
KML Agent Flask Server
============================================================

Endpoints:
  GET  http://localhost:8000/health
  POST http://localhost:8000/generate-kml
  POST http://localhost:8000/generate-kml-batch
  POST http://localhost:8000/validate-kml

Server starting on http://localhost:8000
Press Ctrl+C to stop
============================================================
```

#### 3. Run Flutter App

```bash
cd lg_controller
flutter run
```

Or for specific platform:
```bash
flutter run -d chrome          # Web
flutter run -d windows         # Windows desktop
flutter run -d emulator-5554   # Android emulator
```

#### 4. Test the Feature

1. Navigate to Dashboard
2. Tap "KML Agent" card
3. Enter prompt: `"Fly to Eiffel Tower"`
4. Tap "Generate KML"
5. View generated KML
6. Send to Liquid Galaxy or edit as needed

## Example Prompts

### Simple Fly-To
```
"Fly to Taj Mahal"
"Show the Sydney Opera House"
"Display Big Ben in London"
```

### Multi-Stop Tours
```
"Create a tour: London, Paris, Rome"
"Tour of wonders: Taj Mahal, Great Wall, Machu Picchu"
"European capitals tour"
```

### Specific Coordinates
```
"Fly to coordinates 40.7128,-74.0060 at 1000m altitude"
"Show location 51.5074,-0.1278"
```

### Custom Tours with Descriptions
```
"Create a tour of UNESCO World Heritage sites in India with descriptions"
"Show earthquake locations in Japan with magnitude markers"
```

## API Response Examples

### Successful KML Generation

**Request:**
```json
POST /generate-kml
{
  "query": "Fly to Eiffel Tower"
}
```

**Response:**
```json
{
  "kml": "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<kml xmlns=\"http://www.opengis.net/kml/2.2\" xmlns:gx=\"http://www.google.com/kml/ext/2.2\">\n  <Document>\n    <name>Eiffel Tower</name>\n    <Placemark>\n      <name>Eiffel Tower</name>\n      <description>Iconic iron lattice tower in Paris, France</description>\n      <Point>\n        <coordinates>2.2945,48.8584,324</coordinates>\n      </Point>\n    </Placemark>\n    <gx:Tour>\n      <name>Fly to Eiffel Tower</name>\n      <gx:Playlist>\n        <gx:FlyTo>\n          <gx:duration>5.0</gx:duration>\n          <gx:flyToMode>smooth</gx:flyToMode>\n          <LookAt>\n            <longitude>2.2945</longitude>\n            <latitude>48.8584</latitude>\n            <altitude>0</altitude>\n            <range>1000</range>\n            <tilt>60</tilt>\n            <heading>0</heading>\n          </LookAt>\n        </gx:FlyTo>\n        <gx:Wait>\n          <gx:duration>3.0</gx:duration>\n        </gx:Wait>\n      </gx:Playlist>\n    </gx:Tour>\n  </Document>\n</kml>",
  "query": "Fly to Eiffel Tower"
}
```

### Health Check

**Request:**
```
GET /health
```

**Response:**
```json
{
  "status": "healthy",
  "service": "kml-agent",
  "timestamp": "2026-02-10T09:14:00.123456"
}
```

### Error Responses

**API Key Missing:**
```json
{
  "error": "Google API key required. Set GOOGLE_API_KEY environment variable."
}
```

**Invalid Query:**
```json
{
  "error": "Query parameter is required and must be a non-empty string"
}
```

**Generation Failed:**
```json
{
  "error": "Failed to generate KML: <error details>"
}
```

## Testing

### Manual Testing

#### 1. Test Flask Server Health
```powershell
curl http://localhost:8000/health
```

#### 2. Test KML Generation
```powershell
curl -X POST http://localhost:8000/generate-kml `
  -H "Content-Type: application/json" `
  -d '{"query": "Fly to Big Ben"}'
```

#### 3. Test from Android Emulator
```powershell
adb shell curl http://10.0.2.2:8000/health
```

### Automated Testing

Create `test_server.py`:
```python
import requests

def test_generate_kml():
    response = requests.post(
        'http://localhost:8000/generate-kml',
        json={'query': 'Fly to Eiffel Tower'},
        timeout=60
    )
    assert response.status_code == 200
    data = response.json()
    assert 'kml' in data
    assert '<?xml' in data['kml']
    print('✓ KML generation test passed')

if __name__ == '__main__':
    test_generate_kml()
```

Run: `python test_server.py`

## Troubleshooting

### Common Issues

#### 1. "Connection refused" or "Cannot reach server"

**Cause:** Flask server not running or wrong URL

**Solutions:**
- Ensure `flask_server.py` is running
- Check port 8000 is not blocked
- For Android emulator, use `10.0.2.2` instead of `localhost`
- Update `flask_server.py` to use `host='0.0.0.0'`

#### 2. "Request timed out"

**Cause:** Gemini API taking too long or network issues

**Solutions:**
- Check internet connection
- Verify API key is valid
- Increase timeout in `agent_service.dart` (default: 60s)
- Try simpler prompts first

#### 3. "API key not set"

**Cause:** Environment variable not configured

**Solutions:**
```powershell
# Set for current session
$env:GOOGLE_API_KEY = "your-key"

# Verify it's set
echo $env:GOOGLE_API_KEY

# Or create .env file
echo "GOOGLE_API_KEY=your-key" > .env
```

#### 4. "Invalid KML generated"

**Cause:** Gemini returned text instead of pure KML

**Solutions:**
- Check system prompt in `kml_agent.py`
- Verify prompt emphasizes "Output ONLY the KML XML code"
- Try regenerating with clearer prompt

#### 5. Emulator won't connect

**Cause:** Emulator timeout

**Solutions:**
```bash
# Start emulator first
flutter emulators --launch Pixel_7_2

# Wait 30-60 seconds, then run app
flutter run --device-timeout=120
```

### Debug Checklist

- [ ] `GOOGLE_API_KEY` environment variable is set
- [ ] Flask server is running on port 8000
- [ ] No firewall blocking port 8000
- [ ] Internet connection is active
- [ ] Correct URL for platform (Android: `10.0.2.2`, others: `localhost`)
- [ ] Flutter app has network permissions
- [ ] API key has sufficient quota

## Performance Considerations

### Response Times
- Simple fly-to: 2-5 seconds
- Multi-stop tour: 5-10 seconds
- Complex tours: 10-30 seconds

### Optimization Tips
1. Use Gemini Flash model for faster responses
2. Cache common queries on Flutter side
3. Implement request debouncing for text input
4. Show progress indicators during generation
5. Batch multiple queries when possible

## Security Best Practices

### API Key Management
```python
# ✓ DO: Use environment variables
api_key = os.getenv('GOOGLE_API_KEY')

# ✗ DON'T: Hardcode in source
api_key = "AIza..."  # Never do this!
```

### Input Validation
```dart
// Validate user input before sending
if (prompt.trim().isEmpty) {
  throw Exception('Prompt cannot be empty');
}

// Sanitize prompt (remove dangerous characters)
final sanitized = prompt.replaceAll(RegExp(r'[<>]'), '');
```

### CORS Configuration
```python
# For production, restrict origins
from flask_cors import CORS
CORS(app, origins=['https://yourdomain.com'])
```

## File Structure

```
LGWebStarterKit/
├── kml_agent.py                    # Core AI logic
├── flask_server.py                 # HTTP server wrapper
├── test_server.py                  # Test suite
├── .env                            # Environment variables (gitignored)
│
└── lg_controller/
    ├── lib/
    │   ├── main.dart
    │   ├── services/
    │   │   └── agent_service.dart  # HTTP client
    │   └── src/
    │       └── features/
    │           ├── dashboard/
    │           │   └── presentation/
    │           │       └── dashboard_screen.dart
    │           └── kml_agent/
    │               └── presentation/
    │                   └── kml_agent_screen.dart
    └── pubspec.yaml
```

## Dependencies

### Python
```txt
flask==3.0.0
google-generativeai==0.3.2
python-dotenv==1.0.0
```

### Flutter (pubspec.yaml)
```yaml
dependencies:
  http: ^1.1.0
  flutter_riverpod: ^2.4.9
  shared_preferences: ^2.2.2
```

## Free Data APIs Integration

The LG Controller extends the KML Agent by integrating real-world data from three powerful FREE APIs, each with its own feature module. No API keys required!

### 1. Nominatim (OpenStreetMap) - Location Lookup

**Purpose:** Geocoding - Convert location names to coordinates and vice versa

**Service File:** `lib/services/nominatim_service.dart`

**Features:**
- Forward Geocoding: Search location by name → returns lat/lng
- Reverse Geocoding: Get address from coordinates
- Nearby POI (Points of Interest) search

**API Endpoint:**
```
https://nominatim.openstreetmap.org
```

**Key Methods:**
```dart
// Search location by name
Future<List<LocationResult>> searchLocation(String query)
// Returns: lat, lng, name, address

// Get address from coordinates
Future<String> getAddressFromCoordinates(double lat, double lng)
// Returns: human-readable address string

// Find nearby points of interest
Future<List<POI>> getNearbyPOIs(double lat, double lng, double radiusKm)
// Returns: nearby locations with names, types, distances
```

**KML Generation Example:**
```dart
// User searches "Eiffel Tower"
final locations = await nominatimService.searchLocation('Eiffel Tower');
// Returns: [LocationResult(lat: 48.8584, lng: 2.2945, name: 'Eiffel Tower')]

// Generate KML to fly to location
final kml = _generateLocationKML(locations[0]);
// Output KML with Placemark and FlyTo tour
```

**Generated KML:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>Eiffel Tower</name>
    <Placemark>
      <name>Eiffel Tower, Paris</name>
      <description>Location: 48.8584°N, 2.2945°E</description>
      <Point>
        <coordinates>2.2945,48.8584,324</coordinates>
      </Point>
    </Placemark>
    <gx:Tour>
      <gx:Playlist>
        <gx:FlyTo>
          <gx:duration>5.0</gx:duration>
          <LookAt>
            <latitude>48.8584</latitude>
            <longitude>2.2945</longitude>
            <range>1000</range>
            <tilt>60</tilt>
          </LookAt>
        </gx:FlyTo>
      </gx:Playlist>
    </gx:Tour>
  </Document>
</kml>
```

**Rate Limiting:** 1 request per second (respects OSM usage policy)

**UI Implementation:** `lib/src/features/location_lookup/presentation/location_lookup_screen.dart`
- Search field with autocomplete
- Results list with coordinates
- Quick chips for popular locations (Eiffel Tower, Big Ben, Taj Mahal, etc.)
- Fly-to action sends KML to Liquid Galaxy
- Copy coordinates to clipboard

---

### 2. Open-Meteo - Weather Overlay

**Purpose:** Real-time weather data visualization with no authentication required

**Service File:** `lib/services/weather_service.dart`

**Features:**
- Current weather conditions
- 7-day forecast
- Air quality data (PM2.5, PM10, NO2, O3)
- Weather code interpretation (sunny, rainy, cloudy, etc.)

**API Endpoints:**
```
https://api.open-meteo.com/v1/forecast
https://air-quality-api.open-meteo.com/v1/air-quality
```

**Key Methods:**
```dart
// Get current weather for location
Future<CurrentWeather> getCurrentWeather(double lat, double lng)
// Returns: temperature, wind speed, humidity, weather code

// Get 7-day forecast
Future<List<ForecastDay>> getForecast(double lat, double lng, int days)
// Returns: daily min/max temp, precipitation, weather codes

// Get air quality data
Future<AirQuality> getAirQuality(double lat, double lng)
// Returns: PM2.5, PM10, NO2, O3 levels and AQI status

// Convert weather code to description
static String getWeatherDescription(int code)
// Returns: "Sunny", "Cloudy", "Rainy", etc.
```

**KML Generation Example:**
```dart
// Get weather for Paris
final weather = await weatherService.getCurrentWeather(48.8584, 2.2945);
final forecast = await weatherService.getForecast(48.8584, 2.2945, 7);
final airQuality = await weatherService.getAirQuality(48.8584, 2.2945);

// Generate KML with weather data visualization
final kml = _generateWeatherKML(weather, forecast, airQuality);
```

**Generated KML:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Weather Overlay - Paris</name>
    <description>Temperature: 12°C | Wind: 15 km/h | Humidity: 65%</description>
    <Placemark>
      <name>Paris Weather Station</name>
      <description>
        Current: 12°C, Cloudy
        Wind Speed: 15 km/h
        Humidity: 65%
        Air Quality: Good (PM2.5: 18 µg/m³)
        
        7-Day Forecast:
        Today: 12°C (Cloudy)
        Tomorrow: 14°C (Rainy)
      </description>
      <Point>
        <coordinates>2.3522,48.8566,0</coordinates>
      </Point>
    </Placemark>
  </Document>
</kml>
```

**Weather Codes:** (WMO Weather Interpretation Codes)
- 0: Clear sky
- 1,2: Mostly clear / Partly cloudy
- 3: Overcast
- 45,48: Foggy
- 51-67: Drizzle / Rain
- 71-85: Snow
- 86,87: Rain + snow showers
- 80-82: Rain showers
- 95-99: Thunderstorms

**AQI Status Colors:**
- 🟢 Good (0-35 µg/m³)
- 🟡 Moderate (35-75)
- 🟠 Unhealthy for Sensitive Groups (75-115)
- 🔴 Unhealthy (115-150)
- 🟣 Very Unhealthy (>150)

**UI Implementation:** `lib/src/features/weather_overlay/presentation/weather_overlay_screen.dart`
- Location search powered by Nominatim
- Current weather card with temperature, condition, wind, humidity
- 7-day forecast horizontal scroll list
- Air quality status with colored badges
- Popular cities quick chips (NYC, Paris, Tokyo, London, Sydney, Rio, Dubai, Singapore)

---

### 3. USGS Earthquakes - Earthquake Tracker

**Purpose:** Real-time seismic data visualization with magnitude filtering and tsunami warnings

**Service File:** `lib/services/earthquake_service.dart`

**Features:**
- Recent earthquakes (last month of live data)
- Magnitude filtering (2.5 - 8.0+)
- Location-based search (earthquakes within radius)
- Tsunami warning indicators
- Severity classification (Light → Major)

**API Endpoint:**
```
https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/
  - all_month.geojson (all earthquakes, all magnitudes)
  - 4.5_week.geojson (M4.5+, past week)
  - 5.5_month.geojson (M5.5+, past month)
  - 6.5_month.geojson (M6.5+, past month)
  - significant_month.geojson (significant events)
```

**Key Methods:**
```dart
// Get all recent earthquakes (filters by magnitude)
Future<List<Earthquake>> getRecentEarthquakes({int hours = 168})

// Filter by minimum magnitude
Future<List<Earthquake>> getEarthquakesByMagnitude({double minMagnitude = 4.5})
// Returns: sorted by magnitude descending

// Find earthquakes near location
Future<List<Earthquake>> getEarthquakesNearLocation(
  double lat, double lng, {double radiusKm = 500}
)
// Uses Haversine distance calculation
```

**KML Generation Example:**
```dart
// Get earthquakes with magnitude >= 5.0
final quakes = await earthquakeService.getEarthquakesByMagnitude(minMagnitude: 5.0);

// Generate KML with earthquake markers (up to 50)
final kml = _generateEarthquakeKML(quakes);

// Send to Liquid Galaxy
await kmlService.sendKmlToMaster(kml);
```

**Generated KML (50 earthquake markers):**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>Earthquake Visualization</name>
    <Placemark>
      <name>6.8 - 127 km ESE of Kuril'sk, Russia</name>
      <description>
        Magnitude: 6.8
        Depth: 45.3 km
        Time: 2026-02-10 09:14:25 UTC
        ⚠️ TSUNAMI WARNING
      </description>
      <Point>
        <coordinates>163.5,49.2,45300</coordinates>
      </Point>
    </Placemark>
    <!-- Repeat for each earthquake -->
  </Document>
</kml>
```

**Earthquake Data:**
```dart
class Earthquake {
  final double magnitude;        // Richter scale
  final double lat, lng;         // Coordinates
  final double depth;            // km below surface
  final DateTime time;           // UTC timestamp
  final String place;            // Human-readable location
  final String severity;         // 🟢 Light → 🟣 Major
  final bool hasTsunamiWarning;  // True if M7.0+
}
```

**Severity Levels:**
- 🟢 Light (M4.0-4.9)
- 🟡 Moderate (M5.0-5.9)
- 🟠 Moderate (M6.0-6.9)
- 🔴 Strong (M7.0-7.9)
- 🟣 Major (M8.0+)

**UI Implementation:** `lib/src/features/earthquake_tracker/presentation/earthquake_tracker_screen.dart`
- Magnitude filter slider (2.5 - 8.0) with quick chips
- Earthquake list with:
  - Magnitude circle badge with color coding
  - Location name and coordinates
  - Depth indicator
  - Tsunami warning badge (⚠️) for major quakes
  - Fly-to action button (navigate to epicenter)
- Statistics cards:
  - Total earthquakes count
  - Strongest magnitude in dataset
  - Number of tsunami warnings
- Pull-to-refresh functionality
- Generate KML overlay with all earthquakes

---

## API Integration Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    Flutter Dashboard                         │
│  Grid with 13 Control Cards:                                 │
│  ├── Shutdown/Reboot/Relaunch                                │
│  ├── Logo controls                                            │
│  ├── Pyramid Builder                                          │
│  ├── ISS Tracker                                              │
│  ├── Smart Tours                                              │
│  ├── KML Agent (Gemini AI)              ← AI Generation      │
│  ├── Location Lookup (Nominatim)        ← Free API 1         │
│  ├── Weather Overlay (Open-Meteo)       ← Free API 2         │
│  └── Earthquake Tracker (USGS)          ← Free API 3         │
└──────────────────────────────────────────────────────────────┘
                         ↓
    ┌────────────────────┼────────────────────┐
    ↓                    ↓                     ↓
┌─────────────┐  ┌──────────────┐  ┌──────────────────┐
│ Nominatim   │  │ Open-Meteo   │  │ USGS Earthquakes │
│ (OSM)       │  │ (Weather)    │  │ (Seismic)        │
│ Free ✓      │  │ Free ✓       │  │ Free ✓           │
│ No API Key  │  │ No API Key   │  │ No API Key       │
└─────────────┘  └──────────────┘  └──────────────────┘
    ↓                    ↓                     ↓
    └────────────────────┼────────────────────┘
                         ↓
            ┌─────────────────────────┐
            │  KML Service (Dart)     │
            │  Combines data into KML │
            └─────────────────────────┘
                         ↓
            ┌─────────────────────────┐
            │ Liquid Galaxy (SSH/TCP) │
            │ Renders visualization   │
            └─────────────────────────┘
```

## Future Enhancements

### Completed Features ✅
- [x] KML Agent (Gemini AI generation)
- [x] Location Lookup (Nominatim geocoding)
- [x] Weather Overlay (Open-Meteo integration)
- [x] Earthquake Tracker (USGS seismic data)
- [x] Dashboard integration (13 control cards)
- [x] Free API integration (no API keys required)

### Planned Features
- [ ] KML template library (pre-built visualization templates)
- [ ] Favorite prompts saved locally (user history)
- [ ] History of generated KMLs (undo/redo)
- [ ] Real-time preview map (before sending to LG)
- [ ] Voice input for prompts (speech-to-text)
- [ ] Multi-language support for prompts
- [ ] Offline KML editing
- [ ] Export KML to file (download to device)
- [ ] Share KML via link (cloud integration)

### Advanced API Features
- [ ] Combined overlays (weather + earthquake on same map)
- [ ] Historical earthquake data (past months/years)
- [ ] Weather alerts & warnings integration
- [ ] OpenWeatherMap API integration (more detailed data)
- [ ] GeoJSON import/export
- [ ] Custom data layer creation

### Advanced KML Features
- [ ] Context-aware suggestions (location-based)
- [ ] Learn from user corrections (feedback loop)
- [ ] Auto-fix invalid KML (validation + repair)
- [ ] Style recommendations (colors, icons, animations)
- [ ] Tour optimization (smooth transitions)
- [ ] 3D building/terrain integration
- [ ] Real-time video layer streaming

### UI/UX Improvements
- [ ] Dark mode theme refinement
- [ ] Gesture controls (pinch, rotate on map)
- [ ] Bookmark favorite locations
- [ ] Comparison mode (side-by-side weather)
- [ ] Statistics dashboard for earthquake data
- [ ] Heatmap visualization of seismic activity
- [ ] AR integration for location overlays

## Support & Resources

### Quick API Reference

#### Nominatim (OpenStreetMap)
```
Base URL: https://nominatim.openstreetmap.org
Free Tier: Unlimited (respect 1 req/sec rate limit)
Auth: User-Agent header required
Endpoints:
  GET /search?q={query}&format=json
  GET /reverse?lat={lat}&lon={lon}&format=json
```

#### Open-Meteo Weather
```
Base URL: https://api.open-meteo.com/v1
Free Tier: Unlimited
Auth: None required
Endpoints:
  GET /forecast?latitude={lat}&longitude={lng}&current=true&forecast_days=7
  GET /air-quality?latitude={lat}&longitude={lng}
```

#### USGS Earthquakes
```
Base URL: https://earthquake.usgs.gov/earthquakes/feed/v1.0/summary
Free Tier: Unlimited
Auth: None required
Endpoints:
  /all_month.geojson - All earthquakes, past month
  /4.5_week.geojson - M4.5+, past week
  /5.5_month.geojson - M5.5+, past month
  /significant_month.geojson - Significant events
```

### Code Examples

#### Using Location Lookup Service
```dart
import 'package:lg_controller/services/nominatim_service.dart';

final nominatim = NominatimService();

// Search for location
final results = await nominatim.searchLocation('Statue of Liberty');
if (results.isNotEmpty) {
  final location = results[0];
  print('${location.name} at ${location.lat}, ${location.lng}');
  
  // Fly to location
  await kmlService.flyTo(location.lat, location.lng, 1000, 0, 60);
}

// Reverse geocoding
final address = await nominatim.getAddressFromCoordinates(40.7484, -73.9857);
print('Address: $address');

// Find nearby POIs
final pois = await nominatim.getNearbyPOIs(40.7484, -73.9857, radiusKm: 5);
for (var poi in pois) {
  print('${poi.name} (${poi.type}) - ${poi.distanceKm} km away');
}
```

#### Using Weather Service
```dart
import 'package:lg_controller/services/weather_service.dart';

final weather = WeatherService();

// Get current weather + 7-day forecast
final current = await weather.getCurrentWeather(48.8584, 2.2945);
print('Paris: ${current.temperature}°C, ${current.weatherDescription}');

final forecast = await weather.getForecast(48.8584, 2.2945, 7);
for (var day in forecast) {
  print('${day.date}: ${day.minTemp}°C - ${day.maxTemp}°C');
}

// Get air quality
final airQuality = await weather.getAirQuality(48.8584, 2.2945);
print('PM2.5: ${airQuality.pm25} µg/m³');
print('AQI Status: ${airQuality.aqiStatus}');
```

#### Using Earthquake Service
```dart
import 'package:lg_controller/services/earthquake_service.dart';

final earthquakes = EarthquakeService();

// Get earthquakes by magnitude
final quakes = await earthquakes.getEarthquakesByMagnitude(minMagnitude: 6.0);
print('Found ${quakes.length} earthquakes M6.0+');

for (var quake in quakes.take(5)) {
  print('${quake.severity} - ${quake.place}');
  print('  Magnitude: ${quake.magnitude}');
  print('  Depth: ${quake.depth} km');
  if (quake.hasTsunamiWarning()) {
    print('  ⚠️ TSUNAMI WARNING');
  }
}

// Find earthquakes near location
final nearby = await earthquakes.getEarthquakesNearLocation(
  -33.8688,  // Sydney latitude
  151.2093,  // Sydney longitude
  radiusKm: 500,
);
print('Found ${nearby.length} earthquakes within 500km of Sydney');
```

### Documentation
- [Google Gemini API Docs](https://ai.google.dev/)
- [KML Reference](https://developers.google.com/kml/documentation/kmlreference)
- [Liquid Galaxy Wiki](https://github.com/LiquidGalaxyLAB/liquid-galaxy/wiki)
- [Flutter Documentation](https://flutter.dev/docs)

### Quick Start Guides
- `KML_AGENT_QUICK_START.md` - 5-minute setup guide
- `KML_AGENT_FEATURE_SETUP.md` - Detailed setup instructions
- `KML_AGENT_SETUP.md` - Python script documentation

### Example Scripts
- `kml_agent.py` - Standalone CLI tool
- `test_server.py` - Automated tests
- `flask_server.py` - Production server

## License
This feature is part of the LG Web Starter Kit project.

## Contributors
- Initial implementation: February 2026
- AI Model: Google Gemini 1.5 Flash
- Framework: Flutter + Python Flask

---

**Last Updated:** February 10, 2026  
**Version:** 1.0.0  
**Status:** Production Ready ✅