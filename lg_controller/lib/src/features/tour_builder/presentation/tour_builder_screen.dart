import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'package:lg_controller/src/features/tour_builder/domain/models/tour.dart';
import 'package:lg_controller/src/features/tour_builder/domain/models/waypoint.dart';
import 'package:lg_controller/src/features/tour_builder/data/tour_provider.dart';

class TourBuilderScreen extends ConsumerStatefulWidget {
  final Tour? initialTour;

  const TourBuilderScreen({super.key, this.initialTour});

  @override
  ConsumerState<TourBuilderScreen> createState() => _TourBuilderScreenState();
}

class _TourBuilderScreenState extends ConsumerState<TourBuilderScreen> {
  late List<Waypoint> waypoints;
  late TextEditingController _tourNameController;
  late TextEditingController _tourDescController;
  late MapController _mapController;
  double _initialLat = 20.0;
  double _initialLon = 0.0;
  bool _isPlayingTour = false;
  int _currentWaypointIndex = 0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    waypoints = widget.initialTour?.waypoints ?? [];
    _tourNameController =
        TextEditingController(text: widget.initialTour?.name ?? '');
    _tourDescController =
        TextEditingController(text: widget.initialTour?.description ?? '');

    if (waypoints.isNotEmpty) {
      _initialLat = waypoints.first.latitude;
      _initialLon = waypoints.first.longitude;
      
      // Schedule the fly-to animation after the map is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _flyToWaypoints();
      });
    }
  }

  @override
  void dispose() {
    _tourNameController.dispose();
    _tourDescController.dispose();
    super.dispose();
  }

  void _flyToWaypoints() {
    if (waypoints.isEmpty) return;

    if (waypoints.length == 1) {
      // Fly to single waypoint
      _mapController.move(
        LatLng(waypoints.first.latitude, waypoints.first.longitude),
        10,
      );
    } else {
      // Calculate bounds for all waypoints
      double minLat = waypoints.first.latitude;
      double maxLat = waypoints.first.latitude;
      double minLon = waypoints.first.longitude;
      double maxLon = waypoints.first.longitude;

      for (final wp in waypoints) {
        minLat = minLat > wp.latitude ? wp.latitude : minLat;
        maxLat = maxLat < wp.latitude ? wp.latitude : maxLat;
        minLon = minLon > wp.longitude ? wp.longitude : minLon;
        maxLon = maxLon < wp.longitude ? wp.longitude : maxLon;
      }

      // Calculate center and appropriate zoom
      final centerLat = (minLat + maxLat) / 2;
      final centerLon = (minLon + maxLon) / 2;

      _mapController.move(
        LatLng(centerLat, centerLon),
        8,
      );
    }
  }

  Future<void> _playTour() async {
    if (waypoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add waypoints to play tour')),
      );
      return;
    }

    setState(() {
      _isPlayingTour = true;
      _currentWaypointIndex = 0;
    });

    try {
      for (int i = 0; i < waypoints.length; i++) {
        if (!_isPlayingTour) break;

        final wp = waypoints[i];
        setState(() {
          _currentWaypointIndex = i;
        });

        // Fly to waypoint
        _mapController.move(
          LatLng(wp.latitude, wp.longitude),
          12,
        );

        // Wait for the waypoint duration
        await Future.delayed(Duration(seconds: wp.durationSeconds));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tour finished!')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlayingTour = false);
      }
    }
  }

  void _stopTour() {
    setState(() {
      _isPlayingTour = false;
      _currentWaypointIndex = 0;
    });
    _flyToWaypoints();
  }

  void _addWaypoint(LatLng point) {
    final waypoint = Waypoint(
      id: const Uuid().v4(),
      latitude: point.latitude,
      longitude: point.longitude,
      name: 'Waypoint ${waypoints.length + 1}',
      description: '',
      order: waypoints.length,
    );

    setState(() {
      waypoints.add(waypoint);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Waypoint added. Tap to edit.')),
    );
  }

  void _editWaypoint(int index) {
    final wp = waypoints[index];
    showDialog(
      context: context,
      builder: (context) => _WaypointEditDialog(
        waypoint: wp,
        onSave: (updated) {
          setState(() {
            waypoints[index] = updated;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _removeWaypoint(int index) {
    setState(() {
      waypoints.removeAt(index);
      // Reorder
      for (int i = 0; i < waypoints.length; i++) {
        waypoints[i] = waypoints[i].copyWith(order: i);
      }
    });
  }

  Future<void> _saveTour() async {
    if (_tourNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter tour name')),
      );
      return;
    }

    if (waypoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one waypoint')),
      );
      return;
    }

    final tour = Tour(
      id: widget.initialTour?.id ?? const Uuid().v4(),
      name: _tourNameController.text,
      description: _tourDescController.text,
      waypoints: waypoints,
      createdAt: widget.initialTour?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await ref.read(toursProvider.notifier).addTour(tour);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tour saved!')),
    );

    Navigator.pop(context, tour);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tour Builder'),
        actions: [
          if (_isPlayingTour)
            IconButton(
              icon: const Icon(Icons.stop),
              onPressed: _stopTour,
              tooltip: 'Stop Tour',
            )
          else
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: waypoints.isNotEmpty ? _playTour : null,
              tooltip: 'Play Tour',
            ),
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveTour,
            tooltip: 'Save Tour',
          ),
        ],
      ),
      body: Column(
        children: [
          // Tour metadata
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _tourNameController,
                  decoration: InputDecoration(
                    labelText: 'Tour Name',
                    prefixIcon: const Icon(Icons.tour),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tourDescController,
                  decoration: InputDecoration(
                    labelText: 'Tour Description',
                    prefixIcon: const Icon(Icons.description),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 2,
                ),
                if (_isPlayingTour && _currentWaypointIndex < waypoints.length) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Now playing: ${waypoints[_currentWaypointIndex].name}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Waypoint ${_currentWaypointIndex + 1} of ${waypoints.length}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: (_currentWaypointIndex + 1) / waypoints.length,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Map
          Expanded(
            flex: 2,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(_initialLat, _initialLon),
                initialZoom: 4,
                onTap: (tapPosition, point) => _addWaypoint(point),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.lg_controller',
                ),
                MarkerLayer(
                  markers: waypoints
                      .map((wp) => Marker(
                            point: LatLng(wp.latitude, wp.longitude),
                            child: GestureDetector(
                              onTap: () => _editWaypoint(waypoints.indexOf(wp)),
                              child: const Icon(
                                Icons.location_on,
                                color: Colors.red,
                                size: 40,
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          // Waypoints list
          Expanded(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Waypoints (${waypoints.length})',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: waypoints.isEmpty
                      ? Center(
                          child: Text(
                            'Tap on map to add waypoints',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        )
                      : ListView.builder(
                          itemCount: waypoints.length,
                          itemBuilder: (context, index) {
                            final wp = waypoints[index];
                            return ListTile(
                              leading: Text('${wp.order + 1}'),
                              title: Text(wp.name),
                              subtitle: Text(
                                '${wp.latitude.toStringAsFixed(2)}, ${wp.longitude.toStringAsFixed(2)}',
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeWaypoint(index),
                              ),
                              onTap: () => _editWaypoint(index),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WaypointEditDialog extends StatefulWidget {
  final Waypoint waypoint;
  final Function(Waypoint) onSave;

  const _WaypointEditDialog({
    required this.waypoint,
    required this.onSave,
  });

  @override
  State<_WaypointEditDialog> createState() => _WaypointEditDialogState();
}

class _WaypointEditDialogState extends State<_WaypointEditDialog> {
  late TextEditingController nameCtrl;
  late TextEditingController descCtrl;
  late TextEditingController durationCtrl;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.waypoint.name);
    descCtrl = TextEditingController(text: widget.waypoint.description);
    durationCtrl =
        TextEditingController(text: widget.waypoint.durationSeconds.toString());
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    durationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Waypoint'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: durationCtrl,
              decoration: const InputDecoration(labelText: 'Duration (seconds)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            final updated = widget.waypoint.copyWith(
              name: nameCtrl.text,
              description: descCtrl.text,
              durationSeconds: int.tryParse(durationCtrl.text) ?? 5,
            );
            widget.onSave(updated);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
