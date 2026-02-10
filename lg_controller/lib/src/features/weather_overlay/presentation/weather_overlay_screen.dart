import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lg_controller/services/nominatim_service.dart';
import 'package:lg_controller/services/weather_service.dart';

class WeatherOverlayScreen extends ConsumerStatefulWidget {
  const WeatherOverlayScreen({super.key});

  @override
  ConsumerState<WeatherOverlayScreen> createState() => _WeatherOverlayScreenState();
}

class _WeatherOverlayScreenState extends ConsumerState<WeatherOverlayScreen> {
  final TextEditingController _locationController = TextEditingController();
  final NominatimService _nominatimService = NominatimService();
  final WeatherService _weatherService = WeatherService();

  CurrentWeather? _currentWeather;
  List<ForecastDay>? _forecast;
  AirQuality? _airQuality;
  bool _isLoading = false;
  double? _selectedLat;
  double? _selectedLng;

  static const List<String> popularLocations = [
    'New York',
    'Paris',
    'Tokyo',
    'London',
    'Sydney',
    'Rio de Janeiro',
    'Dubai',
    'Singapore',
  ];

  @override
  void dispose() {
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Overlay'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location Search
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Get Weather for a Location:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _locationController,
                      decoration: InputDecoration(
                        hintText: 'Enter city name',
                        prefixIcon: const Icon(Icons.cloud),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabled: !_isLoading,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _getWeather,
                      icon: const Icon(Icons.cloud_download),
                      label: const Text('Get Weather'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Popular Cities
            if (_currentWeather == null && !_isLoading) ...[
              const Text(
                'Popular Cities:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final city in popularLocations)
                    ActionChip(
                      label: Text(city),
                      onPressed: () {
                        _locationController.text = city;
                        _getWeather();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Loading
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(),
              ),

            // Current Weather
            if (_currentWeather != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Weather',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_currentWeather!.temperature.toStringAsFixed(1)}°C',
                                style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                '${_currentWeather!.apparentTemperature.toStringAsFixed(1)}° feels like',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentWeather!.description,
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '💨 ${_currentWeather!.windSpeed.toStringAsFixed(1)} km/h',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                '💧 ${_currentWeather!.humidity}%',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Air Quality
              if (_airQuality != null) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Air Quality',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _airQuality!.getAQIStatus(),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        if (_airQuality!.pm25 != null)
                          Text(
                            'PM2.5: ${_airQuality!.pm25!.toStringAsFixed(1)} µg/m³',
                          ),
                        if (_airQuality!.pm10 != null)
                          Text(
                            'PM10: ${_airQuality!.pm10!.toStringAsFixed(1)} µg/m³',
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Forecast
              if (_forecast != null && _forecast!.isNotEmpty) ...[
                const Text(
                  '7-Day Forecast',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _forecast!.length,
                    itemBuilder: (context, index) {
                      final day = _forecast![index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                day.date.split('T')[0],
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${day.maxTemp.toStringAsFixed(0)}° / ${day.minTemp.toStringAsFixed(0)}°',
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                day.description,
                                style: const TextStyle(fontSize: 10),
                                textAlign: TextAlign.center,
                              ),
                              if (day.precipitation > 0) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '🌧️ ${day.precipitation.toStringAsFixed(1)}mm',
                                  style: const TextStyle(fontSize: 10),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _getWeather() async {
    final location = _locationController.text.trim();
    if (location.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Get coordinates from location name
      final results = await _nominatimService.searchLocation(location);
      if (results.isEmpty) {
        throw Exception('Location not found');
      }

      final selectedLocation = results.first;
      _selectedLat = selectedLocation.lat;
      _selectedLng = selectedLocation.lng;

      // Fetch weather data
      final weather = await _weatherService.getCurrentWeather(
        selectedLocation.lat,
        selectedLocation.lng,
      );

      final forecast = await _weatherService.getForecast(
        selectedLocation.lat,
        selectedLocation.lng,
        days: 7,
      );

      final airQuality = await _weatherService.getAirQuality(
        selectedLocation.lat,
        selectedLocation.lng,
      );

      setState(() {
        _currentWeather = weather;
        _forecast = forecast;
        _airQuality = airQuality;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
