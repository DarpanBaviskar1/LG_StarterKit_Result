import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:lg_controller/src/features/settings/data/settings_service.dart';
import '../domain/models/tour.dart';
import 'tour_service.dart';
import 'gemini_service.dart';

final tourServiceProvider = Provider<TourService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TourService(prefs);
});

final geminiServiceProvider = Provider<GeminiService>((ref) {
  // IMPORTANT: Replace with your actual Gemini API key
  const apiKey = 'AIzaSyAc09uhbYU7vZm3RixbVeHoPJ3KskqIXPU';
  return GeminiService(apiKey: apiKey);
});

final toursProvider =
    StateNotifierProvider<ToursNotifier, AsyncValue<List<Tour>>>(
  (ref) {
    final service = ref.watch(tourServiceProvider);
    return ToursNotifier(service);
  },
);

class ToursNotifier extends StateNotifier<AsyncValue<List<Tour>>> {
  final TourService _service;

  ToursNotifier(this._service) : super(const AsyncValue.loading()) {
    loadTours();
  }

  Future<void> loadTours() async {
    state = const AsyncValue.loading();
    try {
      final tours = await _service.getAllTours();
      state = AsyncValue.data(tours);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addTour(Tour tour) async {
    try {
      await _service.saveTour(tour);
      await loadTours();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> updateTour(Tour tour) async {
    try {
      await _service.saveTour(tour);
      await loadTours();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> deleteTour(String tourId) async {
    try {
      await _service.deleteTour(tourId);
      await loadTours();
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
