import 'package:dartssh2/dartssh2.dart';
import '../utils/kml/kml_builder.dart';
import '../features/navigation/models/location.dart';

/// Liquid Galaxy Service
///
/// High-level interface for controlling Liquid Galaxy.
/// Handles KML generation, file transfer, and command execution.
///
/// Example:
/// ```dart
/// final lg = LGService(sshClient);
/// await lg.flyTo(Location(...));
/// ```
class LGService {
  final SSHClient _ssh;

  LGService(this._ssh);

  bool get isConnected => _ssh.isClosed == false;

  /// Fly to a location with animation
  Future<void> flyTo(Location location) async {
    if (!isConnected) {
      throw Exception('SSH not connected');
    }

    if (!location.isValid) {
      throw Exception('Invalid coordinates: ${location.latitude}, ${location.longitude}');
    }

    final kml = KMLBuilder.buildFlyToWithDuration(
      latitude: location.latitude,
      longitude: location.longitude,
      altitude: location.altitude,
      heading: location.heading,
      tilt: location.tilt,
      range: location.range,
      duration: 3.0,
    );

    await _sendKML(kml);
  }

  /// Send KML content to Liquid Galaxy
  Future<void> _sendKML(String kml) async {
    try {
      // Escape single quotes for shell
      final escapedKml = kml.replaceAll("'", "'\\''");

      // Write KML to file on LG master
      await _ssh.run(
        'echo \'$escapedKml\' > /tmp/flyto.kml'
      );

      // Brief delay for file system
      await Future.delayed(Duration(milliseconds: 500));

      // Notify LG to load the KML
      await _ssh.run(
        'echo "http://localhost:3001/kml" > /tmp/query.txt'
      );
    } catch (e) {
      debugPrint('❌ KML execution failed: $e');
      rethrow;
    }
  }

  /// Get LG status
  Future<String> getStatus() async {
    if (!isConnected) {
      throw Exception('Not connected');
    }

    return await _ssh.run('echo "LG Connected"');
  }

  /// Cleanup: close SSH connection
  Future<void> dispose() async {
    try {
      await _ssh.close();
    } catch (e) {
      debugPrint('Error disposing LG service: $e');
    }
  }
}
