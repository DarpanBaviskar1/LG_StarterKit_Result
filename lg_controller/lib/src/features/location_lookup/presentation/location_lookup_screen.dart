import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lg_controller/services/nominatim_service.dart';
import 'package:lg_controller/src/features/home/data/kml_service.dart';

class LocationLookupScreen extends ConsumerStatefulWidget {
  const LocationLookupScreen({super.key});

  @override
  ConsumerState<LocationLookupScreen> createState() => _LocationLookupScreenState();
}

class _LocationLookupScreenState extends ConsumerState<LocationLookupScreen> {
  final TextEditingController _searchController = TextEditingController();
  final NominatimService _nominatimService = NominatimService();
  List<LocationResult> _searchResults = [];
  bool _isLoading = false;
  LocationResult? _selectedLocation;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Location Lookup'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Search for a Location:',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'E.g., "Eiffel Tower", "Mount Everest"',
                        prefixIcon: const Icon(Icons.location_on),
                        suffixIcon: _isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabled: !_isLoading,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isLoading || _searchController.text.isEmpty ? null : _searchLocations,
                      icon: const Icon(Icons.search),
                      label: const Text('Search'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Quick Examples
            if (_searchResults.isEmpty && !_isLoading) ...[
              const Text(
                'Popular Locations:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildQuickChip('Eiffel Tower'),
                  _buildQuickChip('Big Ben'),
                  _buildQuickChip('Taj Mahal'),
                  _buildQuickChip('Statue of Liberty'),
                  _buildQuickChip('Great Wall of China'),
                  _buildQuickChip('Mount Everest'),
                ],
              ),
              const SizedBox(height: 20),
            ],

            // Search Results
            if (_searchResults.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Results (${_searchResults.length})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  if (_selectedLocation != null)
                    ElevatedButton.icon(
                      onPressed: _flyToLocation,
                      icon: const Icon(Icons.flight_takeoff),
                      label: const Text('Fly To'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final result = _searchResults[index];
                  final isSelected = _selectedLocation == result;
                  
                  return Card(
                    color: isSelected ? Colors.blue.shade50 : null,
                    child: ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.orange),
                      title: Text(result.name),
                      subtitle: Text(
                        '${result.lat.toStringAsFixed(4)}, ${result.lng.toStringAsFixed(4)}',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedLocation = result;
                        });
                      },
                    ),
                  );
                },
              ),
            ],

            // Selected Location Details
            if (_selectedLocation != null) ...[
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selected Location',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow('Name', _selectedLocation!.name),
                      _buildDetailRow('Latitude', _selectedLocation!.lat.toStringAsFixed(6)),
                      _buildDetailRow('Longitude', _selectedLocation!.lng.toStringAsFixed(6)),
                      if (_selectedLocation!.type != null)
                        _buildDetailRow('Type', _selectedLocation!.type!),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Wrap(
                          spacing: 8,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _flyToLocation,
                              icon: const Icon(Icons.flight_takeoff),
                              label: const Text('Fly To'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _generateKMLForLocation,
                              icon: const Icon(Icons.map),
                              label: const Text('Generate KML'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _copyCoordinates,
                              icon: const Icon(Icons.content_copy),
                              label: const Text('Copy Coords'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickChip(String label) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        _searchController.text = label;
        _searchLocations();
      },
      avatar: const Icon(Icons.location_on, size: 16),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _searchLocations() async {
    setState(() {
      _isLoading = true;
      _selectedLocation = null;
    });

    try {
      final results = await _nominatimService.searchLocation(_searchController.text);
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Search failed: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _flyToLocation() async {
    if (_selectedLocation == null) return;

    try {
      final kmlService = ref.read(kmlServiceProvider);
      await kmlService.flyTo(
        _selectedLocation!.lat,
        _selectedLocation!.lng,
        1000,
        0,
        45,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Flying to ${_selectedLocation!.name}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fly failed: $e')),
      );
    }
  }

  Future<void> _generateKMLForLocation() async {
    if (_selectedLocation == null) return;

    final kml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>${_selectedLocation!.name}</name>
    <Placemark>
      <name>${_selectedLocation!.name}</name>
      <Point>
        <coordinates>${_selectedLocation!.lng},${_selectedLocation!.lat},0</coordinates>
      </Point>
    </Placemark>
    <gx:Tour>
      <name>Fly to ${_selectedLocation!.name}</name>
      <gx:Playlist>
        <gx:FlyTo>
          <gx:duration>3</gx:duration>
          <gx:flyToMode>smooth</gx:flyToMode>
          <Camera>
            <longitude>${_selectedLocation!.lng}</longitude>
            <latitude>${_selectedLocation!.lat}</latitude>
            <altitude>1000</altitude>
            <heading>0</heading>
            <tilt>45</tilt>
            <roll>0</roll>
            <altitudeMode>relativeToGround</altitudeMode>
          </Camera>
        </gx:FlyTo>
      </gx:Playlist>
    </gx:Tour>
  </Document>
</kml>''';

    try {
      final kmlService = ref.read(kmlServiceProvider);
      await kmlService.sendKmlToMaster(kml);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✓ KML sent to Liquid Galaxy')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Send failed: $e')),
      );
    }
  }

  void _copyCoordinates() {
    if (_selectedLocation == null) return;

    final coords = '${_selectedLocation!.lat},${_selectedLocation!.lng}';
    Clipboard.setData(ClipboardData(text: coords));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✓ Coordinates copied')),
    );
  }
}
