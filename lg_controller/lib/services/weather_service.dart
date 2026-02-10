import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Open-Meteo Weather Service
/// 100% FREE - No API key required!
/// Provides current weather and forecast data
class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1';

  /// Get current weather at coordinates
  Future<CurrentWeather> getCurrentWeather(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/forecast')
            .replace(queryParameters: {
          'latitude': lat.toString(),
          'longitude': lng.toString(),
          'current': 'temperature_2m,weather_code,wind_speed_10m,relative_humidity_2m,apparent_temperature',
          'timezone': 'auto',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return CurrentWeather.fromJson(data['current']);
      }

      throw Exception('Failed to fetch weather: ${response.statusCode}');
    } catch (e) {
      throw Exception('Weather fetch failed: $e');
    }
  }

  /// Get weather forecast for next 7 days
  Future<List<ForecastDay>> getForecast(double lat, double lng, {int days = 7}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/forecast')
            .replace(queryParameters: {
          'latitude': lat.toString(),
          'longitude': lng.toString(),
          'daily': 'temperature_2m_max,temperature_2m_min,precipitation_sum,weather_code',
          'timezone': 'auto',
          'forecast_days': days.toString(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final daily = data['daily'] as Map<String, dynamic>;
        
        List<ForecastDay> forecast = [];
        for (int i = 0; i < (daily['time'] as List).length; i++) {
          forecast.add(ForecastDay(
            date: daily['time'][i],
            maxTemp: daily['temperature_2m_max'][i],
            minTemp: daily['temperature_2m_min'][i],
            precipitation: daily['precipitation_sum'][i],
            weatherCode: daily['weather_code'][i],
          ));
        }
        return forecast;
      }

      throw Exception('Failed to fetch forecast');
    } catch (e) {
      throw Exception('Forecast fetch failed: $e');
    }
  }

  /// Get air quality data
  Future<AirQuality> getAirQuality(double lat, double lng) async {
    try {
      final response = await http.get(
        Uri.parse('https://air-quality-api.open-meteo.com/v1/air-quality')
            .replace(queryParameters: {
          'latitude': lat.toString(),
          'longitude': lng.toString(),
          'current': 'pm10,pm2_5,ozone,nitrogen_dioxide',
          'timezone': 'auto',
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AirQuality.fromJson(data['current']);
      }

      return AirQuality.empty();
    } catch (e) {
      debugPrint('Air quality fetch failed: $e');
      return AirQuality.empty();
    }
  }

  /// Convert weather code to readable description
  static String getWeatherDescription(int code) {
    const weatherCodes = {
      0: 'Clear sky',
      1: 'Mainly clear',
      2: 'Partly cloudy',
      3: 'Overcast',
      45: 'Foggy',
      48: 'Depositing rime fog',
      51: 'Light drizzle',
      53: 'Moderate drizzle',
      55: 'Dense drizzle',
      61: 'Slight rain',
      63: 'Moderate rain',
      65: 'Heavy rain',
      71: 'Slight snow',
      73: 'Moderate snow',
      75: 'Heavy snow',
      77: 'Snow grains',
      80: 'Slight rain showers',
      81: 'Moderate rain showers',
      82: 'Violent rain showers',
      85: 'Slight snow showers',
      86: 'Heavy snow showers',
      95: 'Thunderstorm',
      96: 'Thunderstorm with slight hail',
      99: 'Thunderstorm with heavy hail',
    };
    return weatherCodes[code] ?? 'Unknown';
  }
}

/// Current Weather Model
class CurrentWeather {
  final double temperature;
  final int weatherCode;
  final double windSpeed;
  final int humidity;
  final double apparentTemperature;

  CurrentWeather({
    required this.temperature,
    required this.weatherCode,
    required this.windSpeed,
    required this.humidity,
    required this.apparentTemperature,
  });

  String get description => WeatherService.getWeatherDescription(weatherCode);

  factory CurrentWeather.fromJson(Map<String, dynamic> json) {
    return CurrentWeather(
      temperature: (json['temperature_2m'] as num).toDouble(),
      weatherCode: json['weather_code'] as int,
      windSpeed: (json['wind_speed_10m'] as num).toDouble(),
      humidity: json['relative_humidity_2m'] as int,
      apparentTemperature: (json['apparent_temperature'] as num).toDouble(),
    );
  }

  @override
  String toString() =>
      'Temp: ${temperature.toStringAsFixed(1)}°C, Wind: ${windSpeed.toStringAsFixed(1)} km/h, Humidity: $humidity%';
}

/// Forecast Day Model
class ForecastDay {
  final String date;
  final double maxTemp;
  final double minTemp;
  final double precipitation;
  final int weatherCode;

  ForecastDay({
    required this.date,
    required this.maxTemp,
    required this.minTemp,
    required this.precipitation,
    required this.weatherCode,
  });

  String get description => WeatherService.getWeatherDescription(weatherCode);
}

/// Air Quality Model
class AirQuality {
  final double? pm10;
  final double? pm25;
  final double? ozone;
  final double? nitrogenDioxide;

  AirQuality({
    this.pm10,
    this.pm25,
    this.ozone,
    this.nitrogenDioxide,
  });

  factory AirQuality.fromJson(Map<String, dynamic> json) {
    return AirQuality(
      pm10: json['pm10'],
      pm25: json['pm2_5'],
      ozone: json['ozone'],
      nitrogenDioxide: json['nitrogen_dioxide'],
    );
  }

  factory AirQuality.empty() {
    return AirQuality();
  }

  String getAQIStatus() {
    if (pm25 == null) return 'No data';
    if (pm25! < 12) return '🟢 Good';
    if (pm25! < 35.4) return '🟡 Moderate';
    if (pm25! < 55.4) return '🟠 Unhealthy for Sensitive Groups';
    if (pm25! < 150.4) return '🔴 Unhealthy';
    return '🟣 Very Unhealthy';
  }
}
