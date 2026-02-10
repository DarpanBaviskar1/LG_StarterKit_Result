import 'package:flutter_riverpod/legacy.dart';
import 'pyramid_model.dart';

/// Pyramid configuration state provider using StateNotifierProvider
final pyramidConfigProvider = StateNotifierProvider<_PyramidConfigNotifier, PyramidConfig>(
  (ref) => _PyramidConfigNotifier(),
);

class _PyramidConfigNotifier extends StateNotifier<PyramidConfig> {
  _PyramidConfigNotifier()
      : super(
          const PyramidConfig(
            latitude: 40.7128,
            longitude: -74.0060,
            altitude: 2000,
            baseSize: 0.01,
            color: 'ff0000ff', // Blue
            name: 'NYC Pyramid',
          ),
        );

  void setLocation(double latitude, double longitude) {
    state = state.copyWith(latitude: latitude, longitude: longitude);
  }

  void setLatitude(double latitude) {
    state = state.copyWith(latitude: latitude);
  }

  void setLongitude(double longitude) {
    state = state.copyWith(longitude: longitude);
  }

  void setAltitude(double altitude) {
    state = state.copyWith(altitude: altitude);
  }

  void setBaseSize(double baseSize) {
    state = state.copyWith(baseSize: baseSize);
  }

  void setColor(String color) {
    state = state.copyWith(color: color);
  }

  void setName(String name) {
    state = state.copyWith(name: name);
  }

  void reset() {
    state = const PyramidConfig(
      latitude: 40.7128,
      longitude: -74.0060,
      altitude: 2000,
      baseSize: 0.01,
      color: 'ff0000ff',
      name: 'NYC Pyramid',
    );
  }

  void loadPreset(String locationName, String colorName) {
    if (PyramidConfig.locationPresets.containsKey(locationName) &&
        PyramidConfig.colorPresets.containsKey(colorName)) {
      final location = PyramidConfig.locationPresets[locationName]!;
      final color = PyramidConfig.colorPresets[colorName]!;
      state = PyramidConfig(
        latitude: location.$1,
        longitude: location.$2,
        altitude: location.$3,
        baseSize: 0.01,
        color: color,
        name: location.$4,
      );
    }
  }
}
