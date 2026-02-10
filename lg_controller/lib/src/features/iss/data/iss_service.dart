
import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lg_controller/src/features/home/data/kml_service.dart';

class ISSService {
  final Dio _dio;
  final KMLService _kmlService;
  Timer? _timer;
  bool _isTracking = false;

  ISSService(this._dio, this._kmlService);

  bool get isTracking => _isTracking;

  Future<void> startTracking() async {
    if (_isTracking) return;
    _isTracking = true;
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      await _updatePosition();
    });
    // Immediate first update
    await _updatePosition();
  }

  Future<void> stopTracking() async {
    _timer?.cancel();
    _isTracking = false;
  }

  Future<void> _updatePosition() async {
    try {
      final response = await _dio.get('http://api.open-notify.org/iss-now.json');
      if (response.statusCode == 200) {
        final data = response.data;
        final pos = data['iss_position'];
        final double lat = double.parse(pos['latitude']);
        final double lon = double.parse(pos['longitude']);

        debugPrint('ISS Position: $lat, $lon');
        
        // Fly to ISS location
        // Altitude 400km (400000 meters)
        await _kmlService.flyTo(lat, lon, 400000, 0, 0); 
      }
    } catch (e) {
      debugPrint('Error fetching ISS position: $e');
    }
  }
}

final dioProvider = Provider<Dio>((ref) => Dio());

final issServiceProvider = Provider<ISSService>((ref) {
  final dio = ref.watch(dioProvider);
  final kmlService = ref.watch(kmlServiceProvider);
  return ISSService(dio, kmlService);
});
