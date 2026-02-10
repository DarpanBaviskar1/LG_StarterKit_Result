import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lg_controller/src/features/home/data/kml_service.dart';
import 'package:lg_controller/src/features/pyramid/data/pyramid_model.dart';
import 'package:lg_controller/src/features/pyramid/data/pyramid_provider.dart';

class PyramidBuilderScreen extends ConsumerWidget {
  const PyramidBuilderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pyramidConfig = ref.watch(pyramidConfigProvider);
    final pyramidNotifier = ref.read(pyramidConfigProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Pyramid Builder'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Location Preset Section
              _buildSectionHeader('📍 Location Presets'),
              _buildLocationPresets(context, pyramidNotifier),
              const SizedBox(height: 24),

              // Manual Location Controls
              _buildSectionHeader('📍 Manual Location'),
              _buildLatitudeControl(pyramidConfig, pyramidNotifier),
              const SizedBox(height: 12),
              _buildLongitudeControl(pyramidConfig, pyramidNotifier),
              const SizedBox(height: 24),

              // Pyramid Dimensions
              _buildSectionHeader('📏 Pyramid Dimensions'),
              _buildAltitudeControl(pyramidConfig, pyramidNotifier),
              const SizedBox(height: 12),
              _buildBaseSizeControl(pyramidConfig, pyramidNotifier),
              const SizedBox(height: 24),

              // Color Selection
              _buildSectionHeader('🎨 Color'),
              _buildColorPresets(pyramidConfig, pyramidNotifier),
              const SizedBox(height: 24),

              // Name
              _buildSectionHeader('📝 Name'),
              _buildNameField(pyramidConfig, pyramidNotifier),
              const SizedBox(height: 24),

              // Preview
              _buildPreviewSection(pyramidConfig),
              const SizedBox(height: 24),

              // Action Buttons
              _buildActionButtons(context, ref, pyramidConfig),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white70,
        ),
      ),
    );
  }

  Widget _buildLocationPresets(BuildContext context, dynamic notifier) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: PyramidConfig.locationPresets.keys.map((location) {
        return ElevatedButton(
          onPressed: () => notifier.loadPreset(location, 'Blue'),
          child: Text(location),
        );
      }).toList(),
    );
  }

  Widget _buildLatitudeControl(
    PyramidConfig config,
    dynamic notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Latitude', style: TextStyle(fontSize: 16)),
            Text(
              config.latitude.toStringAsFixed(4),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: config.latitude,
          min: -90,
          max: 90,
          divisions: 180,
          onChanged: notifier.setLatitude,
          label: config.latitude.toStringAsFixed(4),
        ),
      ],
    );
  }

  Widget _buildLongitudeControl(
    PyramidConfig config,
    dynamic notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Longitude', style: TextStyle(fontSize: 16)),
            Text(
              config.longitude.toStringAsFixed(4),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: config.longitude,
          min: -180,
          max: 180,
          divisions: 360,
          onChanged: notifier.setLongitude,
          label: config.longitude.toStringAsFixed(4),
        ),
      ],
    );
  }

  Widget _buildAltitudeControl(
    PyramidConfig config,
    dynamic notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Peak Altitude (m)', style: TextStyle(fontSize: 16)),
            Text(
              config.altitude.toStringAsFixed(0),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: config.altitude,
          min: 100,
          max: 10000,
          divisions: 99,
          onChanged: notifier.setAltitude,
          label: config.altitude.toStringAsFixed(0),
        ),
      ],
    );
  }

  Widget _buildBaseSizeControl(
    PyramidConfig config,
    dynamic notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Base Size (°)', style: TextStyle(fontSize: 16)),
            Text(
              config.baseSize.toStringAsFixed(4),
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Slider(
          value: config.baseSize,
          min: 0.001,
          max: 0.1,
          divisions: 99,
          onChanged: notifier.setBaseSize,
          label: config.baseSize.toStringAsFixed(4),
        ),
      ],
    );
  }

  Widget _buildColorPresets(
    PyramidConfig config,
    dynamic notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: PyramidConfig.colorPresets.entries.map((entry) {
            final colorName = entry.key;
            final colorHex = entry.value;
            final isSelected = config.color == colorHex;

            return FilterChip(
              label: Text(colorName),
              selected: isSelected,
              onSelected: (_) => notifier.setColor(colorHex),
              backgroundColor: _parseColor(colorHex),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNameField(
    PyramidConfig config,
    dynamic notifier,
  ) {
    return TextField(
      decoration: const InputDecoration(
        hintText: 'Enter pyramid name',
        border: OutlineInputBorder(),
      ),
      controller: TextEditingController(text: config.name),
      onChanged: notifier.setName,
    );
  }

  Widget _buildPreviewSection(PyramidConfig config) {
    return Card(
      color: Colors.grey[850],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Configuration Preview',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildPreviewRow('Location', '${config.latitude.toStringAsFixed(4)}, ${config.longitude.toStringAsFixed(4)}'),
            _buildPreviewRow('Altitude', '${config.altitude.toStringAsFixed(0)} m'),
            _buildPreviewRow('Base Size', '${config.baseSize.toStringAsFixed(4)}°'),
            _buildPreviewRow('Color', config.color),
            _buildPreviewRow('Name', config.name),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    PyramidConfig config,
  ) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => ref.read(pyramidConfigProvider.notifier).reset(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reset'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () async {
              try {
                await ref.read(kmlServiceProvider).sendColoredPyramid(
                  latitude: config.latitude,
                  longitude: config.longitude,
                  altitude: config.altitude,
                  baseSize: config.baseSize,
                  color: config.color,
                  name: config.name,
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('✅ Pyramid sent successfully!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('❌ Error: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.send),
            label: const Text('Send Pyramid'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Color _parseColor(String aabbggrr) {
    try {
      final value = int.parse(aabbggrr.substring(2), radix: 16);
      return Color(0xFF000000 | value);
    } catch (e) {
      return Colors.blue;
    }
  }
}
