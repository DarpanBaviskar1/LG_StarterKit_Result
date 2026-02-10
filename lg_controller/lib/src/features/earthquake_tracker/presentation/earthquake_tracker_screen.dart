import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lg_controller/services/earthquake_service.dart';
import 'package:lg_controller/src/features/home/data/kml_service.dart';

class EarthquakeTrackerScreen extends ConsumerStatefulWidget {
  const EarthquakeTrackerScreen({super.key});

  @override
  ConsumerState<EarthquakeTrackerScreen> createState() => _EarthquakeTrackerScreenState();
}

class _EarthquakeTrackerScreenState extends ConsumerState<EarthquakeTrackerScreen> {
  final EarthquakeService _earthquakeService = EarthquakeService();
  List<Earthquake> _earthquakes = [];
  bool _isLoading = false;
  double _minMagnitude = 4.5;
  String _filterMode = 'all'; // all, nearby, strong

  @override
  void initState() {
    super.initState();
    _loadEarthquakes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Earthquake Tracker'),
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadEarthquakes,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Filter Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Filter Options',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      
                      // Magnitude Filter
                      const Text('Minimum Magnitude:', style: TextStyle(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Slider(
                        value: _minMagnitude,
                        min: 2.5,
                        max: 8.0,
                        divisions: 22,
                        label: _minMagnitude.toStringAsFixed(1),
                        onChanged: (value) {
                          setState(() {
                            _minMagnitude = value;
                          });
                        },
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildMagChip(4.5, 'Minor'),
                          _buildMagChip(5.5, 'Moderate'),
                          _buildMagChip(6.5, 'Strong'),
                          _buildMagChip(7.0, 'Major'),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _loadEarthquakes,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _generateEarthquakeKML,
                            icon: const Icon(Icons.map),
                            label: const Text('Show on Map'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Stats
              if (_earthquakes.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard(
                      'Total',
                      _earthquakes.length.toString(),
                      Colors.blue,
                    ),
                    _buildStatCard(
                      'Strongest',
                      '${_earthquakes.reduce((a, b) => a.magnitude > b.magnitude ? a : b).magnitude.toStringAsFixed(1)}',
                      Colors.red,
                    ),
                    _buildStatCard(
                      'Tsunamis',
                      _earthquakes.where((e) => e.hasTsunamiWarning()).length.toString(),
                      Colors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // Loading
              if (_isLoading)
                const Center(child: CircularProgressIndicator()),

              // Earthquake List
              if (!_isLoading && _earthquakes.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(Icons.info_outline, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('No earthquakes found'),
                    ],
                  ),
                ),

              if (!_isLoading && _earthquakes.isNotEmpty) ...[
                Text(
                  'Recent Earthquakes (${_earthquakes.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _earthquakes.length,
                  itemBuilder: (context, index) {
                    final quake = _earthquakes[index];
                    return Card(
                      child: ListTile(
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _getMagnitudeColor(quake.magnitude),
                          ),
                          child: Center(
                            child: Text(
                              quake.magnitude.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        title: Text(quake.place),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '${quake.lat.toStringAsFixed(2)}, ${quake.lng.toStringAsFixed(2)}',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                            ),
                            Text(
                              'Depth: ${quake.depth.toStringAsFixed(1)} km',
                              style: const TextStyle(fontSize: 11),
                            ),
                            Row(
                              children: [
                                Text(
                                  quake.severity,
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                                ),
                                if (quake.hasTsunamiWarning())
                                  const Padding(
                                    padding: EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      '⚠️ Tsunami Warning',
                                      style: TextStyle(fontSize: 11, color: Colors.red),
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.flight_takeoff),
                          onPressed: () => _flyToEarthquake(quake),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMagChip(double mag, String label) {
    return FilterChip(
      label: Text(label),
      onSelected: (bool selected) {
        setState(() {
          _minMagnitude = mag;
        });
      },
      selected: (_minMagnitude - mag).abs() < 0.1,
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loadEarthquakes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final quakes = await _earthquakeService.getEarthquakesByMagnitude(
        minMagnitude: _minMagnitude,
      );
      
      debugPrint('✓ Loaded ${quakes.length} earthquakes with magnitude >= $_minMagnitude');
      
      setState(() {
        _earthquakes = quakes;
      });
    } catch (e) {
      if (!mounted) return;
      debugPrint('✗ Error loading earthquakes: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading earthquakes: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _flyToEarthquake(Earthquake quake) async {
    try {
      final kmlService = ref.read(kmlServiceProvider);
      await kmlService.flyTo(quake.lat, quake.lng, 500, 0, 60);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Flying to ${quake.place}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fly failed: $e')),
      );
    }
  }

  Future<void> _generateEarthquakeKML() async {
    if (_earthquakes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No earthquakes to display')),
      );
      return;
    }

    // Generate KML with all earthquakes as placemarks
    StringBuffer kmlBuffer = StringBuffer();
    kmlBuffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    kmlBuffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">');
    kmlBuffer.writeln('<Document>');
    kmlBuffer.writeln('<name>Earthquake Visualization</name>');
    
    for (final quake in _earthquakes.take(50)) {
      kmlBuffer.writeln('<Placemark>');
      kmlBuffer.writeln('<name>${quake.magnitude} - ${quake.place}</name>');
      kmlBuffer.writeln('<description>');
      kmlBuffer.writeln('Magnitude: ${quake.magnitude}<br/>');
      kmlBuffer.writeln('Depth: ${quake.depth.toStringAsFixed(1)} km<br/>');
      kmlBuffer.writeln('Time: ${quake.time}<br/>');
      if (quake.hasTsunamiWarning()) {
        kmlBuffer.writeln('⚠️ TSUNAMI WARNING<br/>');
      }
      kmlBuffer.writeln('</description>');
      kmlBuffer.writeln('<Point>');
      kmlBuffer.writeln('<coordinates>${quake.lng},${quake.lat},${quake.depth * 1000}</coordinates>');
      kmlBuffer.writeln('</Point>');
      kmlBuffer.writeln('</Placemark>');
    }
    
    kmlBuffer.writeln('</Document>');
    kmlBuffer.writeln('</kml>');

    try {
      final kmlService = ref.read(kmlServiceProvider);
      await kmlService.sendKmlToMaster(kmlBuffer.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✓ ${_earthquakes.length} earthquakes sent to Liquid Galaxy')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Color _getMagnitudeColor(double magnitude) {
    if (magnitude >= 8.0) return Colors.deepPurple;
    if (magnitude >= 7.0) return Colors.red;
    if (magnitude >= 6.0) return Colors.orange;
    if (magnitude >= 5.0) return Colors.yellow.shade700;
    if (magnitude >= 4.0) return Colors.green;
    return Colors.blue;
  }
}
