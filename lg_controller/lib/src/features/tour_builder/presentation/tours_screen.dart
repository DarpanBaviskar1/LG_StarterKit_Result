import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:lg_controller/src/features/tour_builder/data/tour_provider.dart';
import 'package:lg_controller/src/features/tour_builder/presentation/tour_builder_screen.dart';
import 'package:lg_controller/src/features/tour_builder/presentation/ai_tour_dialog.dart';
import 'package:lg_controller/src/features/tour_builder/domain/models/tour.dart';
import 'package:lg_controller/src/features/home/data/kml_service.dart';

class ToursScreen extends ConsumerWidget {
  const ToursScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toursAsync = ref.watch(toursProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Tour Builder'),
        elevation: 0,
      ),
      body: toursAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $err'),
            ],
          ),
        ),
        data: (tours) => tours.isEmpty
            ? _buildEmptyState(context)
            : _buildToursList(context, ref, tours),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: () => _importKML(context, ref),
            heroTag: 'import-fab',
            label: const Text('Import KML'),
            icon: const Icon(Icons.upload_file),
            backgroundColor: Colors.teal,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            onPressed: () => _showAISuggestions(context, ref),
            heroTag: 'ai-fab',
            label: const Text('AI Suggest'),
            icon: const Icon(Icons.auto_awesome),
            backgroundColor: Colors.purple,
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TourBuilderScreen(),
                ),
              );
            },
            heroTag: 'new-fab',
            label: const Text('New Tour'),
            icon: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.tour, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No tours yet',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Create a new tour or use AI suggestions',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildToursList(BuildContext context, WidgetRef ref, tours) {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: tours.length,
      itemBuilder: (context, index) {
        final tour = tours[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.tour, color: Colors.blue),
            title: Text(tour.name),
            subtitle: Text(
              '${tour.waypoints.length} waypoints • ${(tour.totalDurationSeconds / 60).toStringAsFixed(1)}m',
            ),
            trailing: PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: const Text('Fly To'),
                  onTap: () {
                    _flyToTour(context, ref, tour);
                  },
                ),
                PopupMenuItem(
                  child: const Text('Play'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TourBuilderScreen(initialTour: tour),
                      ),
                    ).then((_) {
                      // Trigger play immediately after navigation
                      Future.delayed(const Duration(milliseconds: 500), () {
                        // This will be handled by the tour builder's autoplay feature
                      });
                    });
                  },
                ),
                PopupMenuItem(
                  child: const Text('Edit'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            TourBuilderScreen(initialTour: tour),
                      ),
                    );
                  },
                ),
                PopupMenuItem(
                  child: const Text('Delete'),
                  onTap: () {
                    ref.read(toursProvider.notifier).deleteTour(tour.id);
                  },
                ),
                PopupMenuItem(
                  child: const Text('Export KML'),
                  onTap: () {
                    _showKMLPreview(context, ref, tour);
                  },
                ),
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TourBuilderScreen(initialTour: tour),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showAISuggestions(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => const AISuggestionDialog(),
    );
  }

  Future<void> _importKML(BuildContext context, WidgetRef ref) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['kml'],
    );

    if (result == null) return;

    try {
      final file = File(result.files.single.path!);
      final kmlString = await file.readAsString();
      final tourService = ref.read(tourServiceProvider);
      final waypoints = tourService.parseKML(kmlString);

      if (waypoints.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No waypoints found in KML')),
        );
        return;
      }

      // Create a tour from the KML data
      final tour = Tour(
        id: const Uuid().v4(),
        name: result.files.single.name.replaceAll('.kml', ''),
        description: 'Imported from KML',
        waypoints: waypoints,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Navigate to tour builder with the imported tour
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TourBuilderScreen(initialTour: tour),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error importing KML: $e')),
      );
    }
  }

  void _showKMLPreview(BuildContext context, WidgetRef ref, tour) {
    final tourService = ref.read(tourServiceProvider);
    final kml = tourService.generateKML(tour);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('KML Preview'),
        content: SingleChildScrollView(
          child: SelectableText(
            kml,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content:
                        Text('KML copied to clipboard (implement copy)')),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  Future<void> _flyToTour(BuildContext context, WidgetRef ref, tour) async {
    if (tour.waypoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tour has no waypoints')),
      );
      return;
    }

    try {
      // Calculate center point of all waypoints
      double avgLat = 0;
      double avgLon = 0;

      for (final wp in tour.waypoints) {
        avgLat += wp.latitude;
        avgLon += wp.longitude;
      }

      avgLat /= tour.waypoints.length;
      avgLon /= tour.waypoints.length;

      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Flying to destination...')),
      );

      // Call KML service to fly to location
      final kmlService = ref.read(kmlServiceProvider);
      await kmlService.flyTo(
        avgLat,
        avgLon,
        1000, // altitude in meters
        0,    // heading
        45,   // tilt angle
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Flying to ${tour.name}...')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error flying to tour: $e')),
        );
      }
    }
  }
}
