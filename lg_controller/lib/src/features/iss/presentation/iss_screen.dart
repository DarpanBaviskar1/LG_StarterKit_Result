
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lg_controller/src/features/iss/data/iss_service.dart';

class ISSScreen extends ConsumerStatefulWidget {
  const ISSScreen({super.key});

  @override
  ConsumerState<ISSScreen> createState() => _ISSScreenState();
}

class _ISSScreenState extends ConsumerState<ISSScreen> {
  bool _isTracking = false;
  late final ISSService _issService;

  @override
  void initState() {
    super.initState();
    _issService = ref.read(issServiceProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ISS Tracker')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.satellite_alt,
              size: 100,
              color: _isTracking ? Colors.greenAccent : Colors.grey,
            ),
            const SizedBox(height: 32),
            Text(
              _isTracking ? 'Tracking ISS...' : 'ISS Tracking Stopped',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Updates location every 5 seconds',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isTracking = !_isTracking;
                  if (_isTracking) {
                    _issService.startTracking();
                  } else {
                    _issService.stopTracking();
                  }
                });
              },
              icon: Icon(_isTracking ? Icons.stop : Icons.play_arrow),
              label: Text(_isTracking ? 'STOP TRACKING' : 'START TRACKING'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isTracking ? Colors.redAccent : Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Stop tracking when leaving screen? 
    // Usually yes, to avoid background SSH spam.
    _issService.stopTracking();
    super.dispose();
  }
}
