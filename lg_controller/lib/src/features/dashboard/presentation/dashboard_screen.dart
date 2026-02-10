
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lg_controller/src/features/home/data/lg_service.dart';
import 'package:lg_controller/src/features/home/data/kml_service.dart';
import 'package:lg_controller/src/features/settings/data/settings_service.dart';
import 'package:lg_controller/src/features/settings/presentation/settings_screen.dart';
import 'package:lg_controller/src/features/iss/presentation/iss_screen.dart';
import 'package:lg_controller/src/features/tour_builder/presentation/tours_screen.dart';
import 'package:lg_controller/src/features/pyramid/presentation/pyramid_builder_screen.dart';
import 'package:lg_controller/src/features/kml_agent/presentation/kml_agent_screen.dart';
import 'package:lg_controller/src/features/location_lookup/presentation/location_lookup_screen.dart';
import 'package:lg_controller/src/features/weather_overlay/presentation/weather_overlay_screen.dart';
import 'package:lg_controller/src/features/earthquake_tracker/presentation/earthquake_tracker_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsServiceProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('LG Controller'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildStatusCard(settings),
            const SizedBox(height: 24),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _ControlCard(
                    title: 'Shutdown',
                    icon: Icons.power_settings_new,
                    color: Colors.redAccent,
                    onTap: () => _confirmAction(context, 'Shutdown', () {
                      ref.read(lgServiceProvider).shutdown(rigs: settings.rigs, password: settings.password);
                    }),
                  ),
                  _ControlCard(
                    title: 'Reboot',
                    icon: Icons.restart_alt,
                    color: Colors.orangeAccent,
                    onTap: () => _confirmAction(context, 'Reboot', () {
                      ref.read(lgServiceProvider).reboot(rigs: settings.rigs, password: settings.password);
                    }),
                  ),
                  _ControlCard(
                    title: 'Relaunch',
                    icon: Icons.refresh,
                    color: Colors.blueAccent,
                    onTap: () => ref.read(lgServiceProvider).relaunch(rigs: settings.rigs, password: settings.password),
                  ),
                  _ControlCard(
                    title: 'Send Logo (Slave 3)',
                    icon: Icons.image,
                    color: Colors.greenAccent,
                    onTap: () => ref.read(kmlServiceProvider).sendLogo(
                          screen: '3',
                          imageUrl: 'https://raw.githubusercontent.com/LiquidGalaxyLAB/liquid-galaxy-lab-website/main/assets/images/google-summers/gsoc/2022/liquid-galaxy-lab/liquid-galaxy-lab-logo.png', // Example Logo
                        ),
                  ),
                  _ControlCard(
                    title: 'Clear Logo',
                    icon: Icons.layers_clear,
                    color: Colors.purpleAccent,
                    onTap: () => ref.read(kmlServiceProvider).clearLogo('3'),
                  ),
                  _ControlCard(
                    title: 'Fly to New York',
                    icon: Icons.flight_takeoff,
                    color: Colors.tealAccent,
                    onTap: () => ref.read(kmlServiceProvider).flyTo(40.7128, -74.0060, 1000, 0, 45),
                  ),
                  _ControlCard(
                    title: '3D Pyramid (NY)',
                    icon: Icons.layers_sharp,
                    color: Colors.cyan,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PyramidBuilderScreen()),
                      );
                    },
                  ),
                  _ControlCard(
                    title: 'ISS Tracker',
                    icon: Icons.satellite_alt,
                    color: Colors.indigoAccent,
                    onTap: () {
                       Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ISSScreen()),
                      );
                    },
                  ),
                  _ControlCard(
                    title: 'Smart Tours',
                    icon: Icons.tour,
                    color: Colors.amberAccent,
                    onTap: () {
                       Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ToursScreen()),
                      );
                    },
                  ),
                  _ControlCard(
                    title: 'KML Agent',
                    icon: Icons.auto_awesome,
                    color: Colors.lightBlueAccent,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const KmlAgentScreen()),
                      );
                    },
                  ),
                  _ControlCard(
                    title: 'Location Lookup',
                    icon: Icons.location_on,
                    color: Colors.redAccent,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const LocationLookupScreen()),
                      );
                    },
                  ),
                  _ControlCard(
                    title: 'Weather Overlay',
                    icon: Icons.cloud,
                    color: Colors.lightBlueAccent,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const WeatherOverlayScreen()),
                      );
                    },
                  ),
                  _ControlCard(
                    title: 'Earthquake Tracker',
                    icon: Icons.warning,
                    color: Colors.deepOrange,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const EarthquakeTrackerScreen()),
                      );
                    },
                  ),
                  _ControlCard(
                    title: 'Clear KML',
                    icon: Icons.clear_all,
                    color: Colors.grey,
                    onTap: () async {
                      await ref.read(kmlServiceProvider).clearKml();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('KML cleared successfully'),
                            backgroundColor: Colors.green,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(SettingsService settings) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.wifi, color: Colors.green),
        title: Text('Connected to ${settings.host}'),
        subtitle: Text('Rigs: ${settings.rigs}'),
      ),
    );
  }

  void _confirmAction(BuildContext context, String action, VoidCallback onConfirm) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm $action'),
        content: Text('Are you sure you want to $action all rigs?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onConfirm();
            },
            child: const Text('Confirm', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _ControlCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ControlCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
