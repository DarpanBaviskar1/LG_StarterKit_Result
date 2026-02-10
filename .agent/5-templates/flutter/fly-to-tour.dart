```dart
/// ============================================================================
/// FLY-TO TOUR IMPLEMENTATION (Production-Ready)
/// 
/// ⚠️ CRITICAL NOTES:
/// - Always use master.kml (NOT master_1.kml) for KML injection
/// - Always use master.kml (NOT master_1.kml) for KML clearing
/// - Wait 1 second between KML update and playtour trigger
/// - Use gx:Tour with Camera for proper 3D positioning
/// ============================================================================

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';

class SSHService {
  SSHClient? _client;

  Future<String?> execute(String command) async {
    try {
      final result = await _client!.run(command);
      return result.toString();
    } catch (e) {
      debugPrint('SSH Execute Failed: $e');
      return null;
    }
  }

  /// Trigger a tour by name
  /// Query: echo "playtour=<tourName>" > /tmp/query.txt
  /// Example: playtour=Mumbai Overview
  Future<bool> playTour(String tourName) async {
    final command = 'echo "playtour=$tourName" > /tmp/query.txt';
    final result = await execute(command);
    return result != null;
  }

  /// Full fly-to tour sequence
  /// 1. Generate KML with gx:Tour + Camera
  /// 2. Write to master.kml (NOT master_1.kml)
  /// 3. Force refresh Earth's myplaces.kml
  /// 4. Wait 1 second for Earth to parse
  /// 5. Trigger tour via playtour query
  /// 6. Clear KML after tour
  Future<void> fly2() async {
    debugPrint('DEBUG: Flying to Mumbai city...');
    
    // Step 1: Generate Mumbai tour KML with proper gx:Tour structure
    final mumbaiKml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2"
  xmlns:gx="http://www.google.com/kml/ext/2.2">
<Document>
    <name>Mumbai Fly-To Tour</name>
    <open>1</open>
    <gx:Tour>
        <name>Mumbai Overview</name>
        <gx:Playlist>
            <gx:FlyTo>
                <gx:duration>5.0</gx:duration>
                <gx:flyToMode>smooth</gx:flyToMode>
                <Camera>
                    <longitude>72.8456</longitude>
                    <latitude>19.0123</latitude>
                    <altitude>1500</altitude>
                    <heading>0</heading>
                    <tilt>45</tilt>
                    <roll>0</roll>
                    <altitudeMode>relativeToGround</altitudeMode>
                </Camera>
            </gx:FlyTo>
            <gx:Wait>
                <gx:duration>5.0</gx:duration>
            </gx:Wait>
        </gx:Playlist>
    </gx:Tour>
</Document>
</kml>''';

    // Step 2: Write to master.kml (✅ NOT master_1.kml)
    const kmlPath = '/var/www/html/kml/master.kml';
    final escapedKml = mumbaiKml.replaceAll('"', '\\"').replaceAll('\$', '\\\$');
    final kmlCommand = 'echo "$escapedKml" > $kmlPath';
    
    await execute(kmlCommand);
    
    // Step 3: Force refresh Earth's myplaces.kml
    await _forceRefresh('master.kml');

    // Step 4: Wait for Earth to parse the new KML (CRITICAL!)
    await Future.delayed(const Duration(seconds: 1));

    // Step 5: Trigger the tour
    await playTour('Mumbai Overview');
    debugPrint('Tour started successfully');
    
    // Step 6: Clean up
    await Future.delayed(const Duration(milliseconds: 500));
    await clearKml();
  }

  /// Clear KML display
  /// Always write to master.kml (NOT master_1.kml)
  Future<void> clearKml() async {
    const blankKml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Empty</name>
  </Document>
</kml>''';
    
    // ✅ Use master.kml (NOT master_1.kml)
    final escapedKml = blankKml.replaceAll('"', '\\"').replaceAll('\$', '\\\$');
    await execute('echo "$escapedKml" > /var/www/html/kml/master.kml');
    await execute('echo "" > /tmp/query.txt');
  }

  /// Force Google Earth to reload a KML file
  /// Uses sed to modify ~/earth/kml/master/myplaces.kml
  /// This ensures Earth detects the new KML and reloads it
  Future<void> _forceRefresh(String kmlFileName) async {
    try {
      final escapedFile = kmlFileName.replaceAll('/', '\\/');
      
      // Add refresh mode
      final addCommand =
          'sed -i "s|<href>[^<]*$escapedFile<\\/href>|&<refreshMode>onInterval<\\/refreshMode><refreshInterval>1<\\/refreshInterval>|" ~/earth/kml/master/myplaces.kml';
      await execute(addCommand);

      await Future.delayed(const Duration(seconds: 1));

      // Remove refresh mode to finalize
      final removeCommand =
          'sed -i "s|<href>[^<]*$escapedFile<\\/href><refreshMode>onInterval<\\/refreshMode><refreshInterval>[0-9]\\+<\\/refreshInterval>|<href>##LG_PHPIFACE##kml/$escapedFile<\\/href>|" ~/earth/kml/master/myplaces.kml';
      await execute(removeCommand);
    } catch (e) {
      debugPrint('Force refresh failed: $e');
    }
  }
}

/// ============================================================================
/// QUICK REFERENCE
/// ============================================================================
/// 
/// Default KML File: master.kml
/// Path: /var/www/html/kml/master.kml
/// 
/// Query File: /tmp/query.txt
/// Tour Trigger: echo "playtour=<tourName>" > /tmp/query.txt
/// 
/// KML Structure Requirements:
/// - XML declaration: <?xml version="1.0" encoding="UTF-8"?>
/// - KML namespaces: xmlns + xmlns:gx
/// - gx:Tour wrapper with <name> matching playtour parameter
/// - gx:Playlist with gx:FlyTo and gx:Wait elements
/// - Camera with: longitude, latitude, altitude, heading, tilt, roll
/// 
/// Timing:
/// 1. Write KML to master.kml (0s)
/// 2. Call _forceRefresh() (0-2s)
/// 3. Wait 1s for Earth to parse (2-3s)
/// 4. Send playtour query (3s) ← CRITICAL TIMING
/// 
/// Common Issues:
/// ❌ master_1.kml → Use master.kml instead
/// ❌ No gx namespace → Add xmlns:gx to kml element
/// ❌ No wait between KML and tour → Add await Future.delayed(1s)
/// ❌ Tour name mismatch → Check <gx:Tour><name> matches playtour param
/// ============================================================================

```
