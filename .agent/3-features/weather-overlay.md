# ☁️ Weather Overlay Feature (Open-Meteo Integration)

## Overview

The Weather Overlay feature displays current weather conditions and forecasts for any location using the Open-Meteo free weather API. Users can view temperature, weather conditions, wind speed, humidity, air quality metrics, and 7-day forecasts—all without requiring an API key.

**Service File:** `lib/services/weather_service.dart`
**UI Screen:** `lib/src/features/weather_overlay/presentation/weather_overlay_screen.dart`
**Dashboard:** Accessible via "Weather Overlay" card

---

## Key Features

1. **Free Weather API** - No API key or authentication required
2. **Current Weather** - Real-time temperature, conditions, wind, humidity
3. **7-Day Forecast** - Daily high/low temperatures and conditions
4. **Air Quality** - PM2.5, PM10, O3, NO2, SO2, CO levels with AQI
5. **Global Coverage** - Worldwide weather data
6. **Weather Code Interpretation** - Convert WMO codes to readable descriptions
7. **Export to KML** - Generate weather overlays for Liquid Galaxy

---

## API Integration

### API Provider
**Open-Meteo** - Open-source weather API
- **Base URL:** `https://api.open-meteo.com`
- **Documentation:** https://open-meteo.com/en/docs
- **License:** CC BY 4.0 (Attribution required)
- **Cost:** FREE (no API key required)
- **Rate Limit:** No published limit, but be respectful

### Endpoints Used

#### 1. Current Weather & Forecast
```
GET https://api.open-meteo.com/v1/forecast
```

**Query Parameters:**
- `latitude` (float, required): Latitude (-90 to 90)
- `longitude` (float, required): Longitude (-180 to 180)
- `current` (string): Current weather variables (comma-separated)
  - Options: `temperature_2m`, `weathercode`, `windspeed_10m`, `winddirection_10m`, `relativehumidity_2m`
- `daily` (string): Daily forecast variables
  - Options: `temperature_2m_max`, `temperature_2m_min`, `weathercode`, `precipitation_sum`
- `timezone` (string): Timezone (default: "auto")
- `temperature_unit` (string): "celsius" or "fahrenheit" (default: celsius)
- `windspeed_unit` (string): "kmh", "ms", "mph", "kn" (default: kmh)

**Example Request:**
```
https://api.open-meteo.com/v1/forecast?latitude=52.52&longitude=13.41&current=temperature_2m,weathercode,windspeed_10m,relativehumidity_2m&daily=temperature_2m_max,temperature_2m_min,weathercode&timezone=auto
```

**Example Response:**
```json
{
  "latitude": 52.52,
  "longitude": 13.419998,
  "generationtime_ms": 0.14400482177734375,
  "utc_offset_seconds": 3600,
  "timezone": "Europe/Berlin",
  "timezone_abbreviation": "CET",
  "elevation": 38.0,
  "current_units": {
    "time": "iso8601",
    "interval": "seconds",
    "temperature_2m": "°C",
    "weathercode": "wmo code",
    "windspeed_10m": "km/h",
    "relativehumidity_2m": "%"
  },
  "current": {
    "time": "2024-02-10T15:00",
    "interval": 900,
    "temperature_2m": 8.5,
    "weathercode": 3,
    "windspeed_10m": 15.2,
    "relativehumidity_2m": 72
  },
  "daily_units": {
    "time": "iso8601",
    "temperature_2m_max": "°C",
    "temperature_2m_min": "°C",
    "weathercode": "wmo code"
  },
  "daily": {
    "time": ["2024-02-10", "2024-02-11", "2024-02-12", ...],
    "temperature_2m_max": [10.2, 11.5, 9.8, ...],
    "temperature_2m_min": [3.1, 4.2, 2.5, ...],
    "weathercode": [3, 61, 2, ...]
  }
}
```

#### 2. Air Quality
```
GET https://air-quality-api.open-meteo.com/v1/air-quality
```

**Query Parameters:**
- `latitude` (float, required): Latitude
- `longitude` (float, required): Longitude
- `current` (string): Air quality variables
  - Options: `pm10`, `pm2_5`, `carbon_monoxide`, `nitrogen_dioxide`, `sulphur_dioxide`, `ozone`, `us_aqi`, `european_aqi`
- `timezone` (string): Timezone (default: "auto")

**Example Request:**
```
https://air-quality-api.open-meteo.com/v1/air-quality?latitude=52.52&longitude=13.41&current=pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone,us_aqi&timezone=auto
```

**Example Response:**
```json
{
  "latitude": 52.52,
  "longitude": 13.419998,
  "generationtime_ms": 1.2159347534179688,
  "utc_offset_seconds": 3600,
  "timezone": "Europe/Berlin",
  "timezone_abbreviation": "CET",
  "current_units": {
    "time": "iso8601",
    "pm10": "μg/m³",
    "pm2_5": "μg/m³",
    "carbon_monoxide": "μg/m³",
    "nitrogen_dioxide": "μg/m³",
    "sulphur_dioxide": "μg/m³",
    "ozone": "μg/m³",
    "us_aqi": "US AQI"
  },
  "current": {
    "time": "2024-02-10T15:00",
    "pm10": 23.5,
    "pm2_5": 12.8,
    "carbon_monoxide": 245.3,
    "nitrogen_dioxide": 35.2,
    "sulphur_dioxide": 8.1,
    "ozone": 42.6,
    "us_aqi": 52
  }
}
```

### Weather Code (WMO) Interpretation

Open-Meteo uses **WMO Weather Interpretation Codes**:

| Code | Description |
|------|-------------|
| 0 | Clear sky |
| 1, 2, 3 | Mainly clear, partly cloudy, overcast |
| 45, 48 | Fog and depositing rime fog |
| 51, 53, 55 | Drizzle: Light, moderate, dense |
| 56, 57 | Freezing drizzle: Light, dense |
| 61, 63, 65 | Rain: Slight, moderate, heavy |
| 66, 67 | Freezing rain: Light, heavy |
| 71, 73, 75 | Snow fall: Slight, moderate, heavy |
| 77 | Snow grains |
| 80, 81, 82 | Rain showers: Slight, moderate, violent |
| 85, 86 | Snow showers: Slight, heavy |
| 95 | Thunderstorm: Slight or moderate |
| 96, 99 | Thunderstorm with slight/heavy hail |

---

## Service Implementation

### File Structure
```
lib/services/weather_service.dart (155 lines)
```

### Core Methods

#### 1. `getCurrentWeather(double lat, double lng)`
Fetches current weather conditions for coordinates.

**Parameters:**
- `lat` (double): Latitude (-90 to 90)
- `lng` (double): Longitude (-180 to 180)

**Returns:** `Future<CurrentWeather>`

**Example Usage:**
```dart
final service = WeatherService();
final weather = await service.getCurrentWeather(52.52, 13.41);

print('Temperature: ${weather.temperature}°C');
print('Conditions: ${weather.weatherDescription}');
print('Wind: ${weather.windSpeed} km/h');
```

#### 2. `getWeatherForecast(double lat, double lng)`
Fetches 7-day weather forecast.

**Parameters:**
- `lat` (double): Latitude
- `lng` (double): Longitude

**Returns:** `Future<List<DailyForecast>>`

**Example Usage:**
```dart
final forecast = await service.getWeatherForecast(52.52, 13.41);

for (final day in forecast) {
  print('${day.date}: ${day.maxTemp}°C / ${day.minTemp}°C - ${day.conditions}');
}
```

#### 3. `getAirQuality(double lat, double lng)`
Fetches current air quality data.

**Parameters:**
- `lat` (double): Latitude
- `lng` (double): Longitude

**Returns:** `Future<AirQuality>`

**Example Usage:**
```dart
final airQuality = await service.getAirQuality(52.52, 13.41);

print('AQI: ${airQuality.usAqi}');
print('PM2.5: ${airQuality.pm25} μg/m³');
print('Status: ${airQuality.aqiStatus}');  // Good, Moderate, Unhealthy, etc.
```

### Data Models

#### `CurrentWeather` Class
```dart
class CurrentWeather {
  final double temperature;         // In °C
  final int weatherCode;             // WMO code
  final String weatherDescription;   // Human-readable
  final double windSpeed;            // In km/h
  final int humidity;                // Percentage (0-100)
  
  CurrentWeather({
    required this.temperature,
    required this.weatherCode,
    required this.weatherDescription,
    required this.windSpeed,
    required this.humidity,
  });
  
  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    final weatherCode = current['weathercode'] as int;
    
    return CurrentWeather(
      temperature: (current['temperature_2m'] as num).toDouble(),
      weatherCode: weatherCode,
      weatherDescription: _weatherCodeToString(weatherCode),
      windSpeed: (current['windspeed_10m'] as num).toDouble(),
      humidity: current['relativehumidity_2m'] as int,
    );
  }
  
  static String _weatherCodeToString(int code) {
    switch (code) {
      case 0: return 'Clear sky';
      case 1: return 'Mainly clear';
      case 2: return 'Partly cloudy';
      case 3: return 'Overcast';
      case 45:
      case 48: return 'Foggy';
      case 51:
      case 53:
      case 55: return 'Drizzle';
      case 61:
      case 63:
      case 65: return 'Rain';
      case 71:
      case 73:
      case 75: return 'Snow';
      case 77: return 'Snow grains';
      case 80:
      case 81:
      case 82: return 'Rain showers';
      case 85:
      case 86: return 'Snow showers';
      case 95: return 'Thunderstorm';
      case 96:
      case 99: return 'Thunderstorm with hail';
      default: return 'Unknown';
    }
  }
}
```

#### `DailyForecast` Class
```dart
class DailyForecast {
  final String date;             // ISO 8601 format (YYYY-MM-DD)
  final double maxTemp;          // Max temperature (°C)
  final double minTemp;          // Min temperature (°C)
  final int weatherCode;         // WMO code
  final String conditions;       // Human-readable
  
  DailyForecast({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.weatherCode,
    required this.conditions,
  });
}
```

#### `AirQuality` Class
```dart
class AirQuality {
  final double pm10;             // PM10 concentration (μg/m³)
  final double pm25;             // PM2.5 concentration (μg/m³)
  final double carbonMonoxide;   // CO (μg/m³)
  final double nitrogenDioxide;  // NO2 (μg/m³)
  final double sulphurDioxide;   // SO2 (μg/m³)
  final double ozone;            // O3 (μg/m³)
  final int usAqi;               // US Air Quality Index (0-500)
  final String aqiStatus;        // Good, Moderate, Unhealthy, etc.
  final Color statusColor;       // Color indicator
  
  AirQuality({
    required this.pm10,
    required this.pm25,
    required this.carbonMonoxide,
    required this.nitrogenDioxide,
    required this.sulphurDioxide,
    required this.ozone,
    required this.usAqi,
    required this.aqiStatus,
    required this.statusColor,
  });
  
  factory AirQuality.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    final aqi = current['us_aqi'] as int;
    final (status, color) = _getAqiStatus(aqi);
    
    return AirQuality(
      pm10: (current['pm10'] as num).toDouble(),
      pm25: (current['pm2_5'] as num).toDouble(),
      carbonMonoxide: (current['carbon_monoxide'] as num).toDouble(),
      nitrogenDioxide: (current['nitrogen_dioxide'] as num).toDouble(),
      sulphurDioxide: (current['sulphur_dioxide'] as num).toDouble(),
      ozone: (current['ozone'] as num).toDouble(),
      usAqi: aqi,
      aqiStatus: status,
      statusColor: color,
    );
  }
  
  static (String, Color) _getAqiStatus(int aqi) {
    if (aqi <= 50) return ('Good', Colors.green);
    if (aqi <= 100) return ('Moderate', Colors.yellow);
    if (aqi <= 150) return ('Unhealthy for Sensitive Groups', Colors.orange);
    if (aqi <= 200) return ('Unhealthy', Colors.red);
    if (aqi <= 300) return ('Very Unhealthy', Colors.purple);
    return ('Hazardous', Colors.brown);
  }
}
```

### Service Code Template
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class WeatherService {
  static const String _weatherBaseUrl = 'api.open-meteo.com';
  static const String _airQualityBaseUrl = 'air-quality-api.open-meteo.com';
  
  Future<CurrentWeather> getCurrentWeather(double lat, double lng) async {
    try {
      final uri = Uri.https(_weatherBaseUrl, '/v1/forecast', {
        'latitude': lat.toString(),
        'longitude': lng.toString(),
        'current': 'temperature_2m,weathercode,windspeed_10m,relativehumidity_2m',
        'timezone': 'auto',
      });
      
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CurrentWeather.fromJson(data);
      } else {
        throw Exception('Failed to fetch weather: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Weather error: $e');
      rethrow;
    }
  }
  
  Future<AirQuality> getAirQuality(double lat, double lng) async {
    try {
      final uri = Uri.https(_airQualityBaseUrl, '/v1/air-quality', {
        'latitude': lat.toString(),
        'longitude': lng.toString(),
        'current': 'pm10,pm2_5,carbon_monoxide,nitrogen_dioxide,sulphur_dioxide,ozone,us_aqi',
        'timezone': 'auto',
      });
      
      final response = await http.get(uri).timeout(const Duration(seconds: 15));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AirQuality.fromJson(data);
      } else {
        throw Exception('Failed to fetch air quality: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Air quality error: $e');
      rethrow;
    }
  }
}
```

---

## UI Implementation

### Screen File
`lib/src/features/weather_overlay/presentation/weather_overlay_screen.dart` (220 lines)

### UI Components

#### 1. Location Input
```dart
Row(
  children: [
    Expanded(
      child: TextField(
        controller: _latController,
        decoration: const InputDecoration(labelText: 'Latitude'),
        keyboardType: TextInputType.number,
      ),
    ),
    const SizedBox(width: 8),
    Expanded(
      child: TextField(
        controller: _lngController,
        decoration: const InputDecoration(labelText: 'Longitude'),
        keyboardType: TextInputType.number,
      ),
    ),
  ],
)
```

#### 2. Current Weather Card
```dart
if (_currentWeather != null)
  Card(
    elevation: 4,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_currentWeather!.temperature.toStringAsFixed(1)}°C',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          Text(_currentWeather!.weatherDescription),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WeatherMetric(
                icon: Icons.air,
                label: 'Wind',
                value: '${_currentWeather!.windSpeed} km/h',
              ),
              _WeatherMetric(
                icon: Icons.water_drop,
                label: 'Humidity',
                value: '${_currentWeather!.humidity}%',
              ),
            ],
          ),
        ],
      ),
    ),
  )
```

#### 3. Forecast List
```dart
ListView.builder(
  shrinkWrap: true,
  physics: const NeverScrollableScrollPhysics(),
  itemCount: _forecast.length,
  itemBuilder: (context, index) {
    final day = _forecast[index];
    return ListTile(
      leading: Icon(_getWeatherIcon(day.weatherCode)),
      title: Text(day.date),
      subtitle: Text(day.conditions),
      trailing: Text(
        '${day.maxTemp.toStringAsFixed(0)}° / ${day.minTemp.toStringAsFixed(0)}°',
      ),
    );
  },
)
```

#### 4. Air Quality Indicator
```dart
if (_airQuality != null)
  Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _airQuality!.statusColor.withOpacity(0.2),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: _airQuality!.statusColor),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.air, color: _airQuality!.statusColor),
            const SizedBox(width: 8),
            Text(
              'AQI: ${_airQuality!.usAqi}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
        Text(
          _airQuality!.aqiStatus,
          style: TextStyle(
            color: _airQuality!.statusColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text('PM2.5: ${_airQuality!.pm25.toStringAsFixed(1)} μg/m³'),
        Text('PM10: ${_airQuality!.pm10.toStringAsFixed(1)} μg/m³'),
      ],
    ),
  )
```

---

## KML Generation

### Weather Overlay with ScreenOverlay
```dart
String generateWeatherKML(CurrentWeather weather, double lat, double lng) {
  return '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
<Document>
  <name>Weather at $lat, $lng</name>
  <ScreenOverlay>
    <name>Weather Info</name>
    <Icon>
      <href>http://via.placeholder.com/200x100/00BFFF/FFFFFF?text=${weather.temperature.toStringAsFixed(0)}°C</href>
    </Icon>
    <overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
    <screenXY x="0" y="1" xunits="fraction" yunits="fraction"/>
    <rotationXY x="0" y="0" xunits="fraction" yunits="fraction"/>
    <size x="0" y="0" xunits="fraction" yunits="fraction"/>
  </ScreenOverlay>
  <Placemark>
    <name>Weather: ${weather.weatherDescription}</name>
    <description>
      Temperature: ${weather.temperature}°C
      Wind: ${weather.windSpeed} km/h
      Humidity: ${weather.humidity}%
    </description>
    <Point>
      <coordinates>$lng,$lat,0</coordinates>
    </Point>
  </Placemark>
</Document>
</kml>''';
}
```

---

## Common Issues & Solutions

### Issue 1: Coordinates Out of Range
**Error:** `Status 400: latitude must be between -90 and 90`
**Solution:** Validate input before API call
```dart
if (lat < -90 || lat > 90) {
  throw Exception('Invalid latitude: $lat');
}
```

### Issue 2: Timezone Issues
**Symptom:** Times are in UTC instead of local time
**Solution:** Use `timezone: 'auto'` parameter

### Issue 3: Missing Data in Response
**Symptom:** Some fields are null
**Solution:** Add null checks in `fromJson()`
```dart
humidity: current['relativehumidity_2m'] as int? ?? 0,
```

---

## Future Enhancements

- [ ] **Historical Weather:** Past weather data
- [ ] **Hourly Forecast:** Hour-by-hour predictions
- [ ] **Weather Alerts:** Severe weather warnings
- [ ] **Weather Maps:** Radar and satellite overlays
- [ ] **Custom Units:** Fahrenheit, mph, etc.
- [ ] **Multiple Locations:** Compare weather across cities

---

**See also:**
- [location-lookup.md](location-lookup.md) - Location search
- [earthquake-tracker.md](earthquake-tracker.md) - Earthquake data
- [8-troubleshooting/api-errors.md](../8-troubleshooting/api-errors.md) - API debugging

**Last Updated:** 2026-02-10
