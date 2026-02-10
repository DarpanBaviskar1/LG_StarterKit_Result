
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lg_controller/src/common/ssh/ssh_service.dart';

class KMLService {
  final SSHService _sshService;

  KMLService(this._sshService);

  Future<bool> _ensureConnection() async {
    if (_sshService.client == null || _sshService.client!.isClosed) {
      debugPrint('KMLService: SSH not connected');
      return false;
    }
    return true;
  }

  /// Flies to a specific location using gx:Tour.
  Future<void> flyTo(double lat, double lon, double alt, double heading, double tilt) async {
    if (!await _ensureConnection()) return;

    try {
      final tourKml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>FlyToTour</name>
    <gx:Tour>
      <name>FlyTo</name>
      <gx:Playlist>
        <gx:FlyTo>
          <gx:duration>3</gx:duration>
          <gx:flyToMode>smooth</gx:flyToMode>
          <Camera>
            <longitude>$lon</longitude>
            <latitude>$lat</latitude>
            <altitude>$alt</altitude>
            <heading>$heading</heading>
            <tilt>$tilt</tilt>
            <roll>0</roll>
            <altitudeMode>relativeToGround</altitudeMode>
          </Camera>
        </gx:FlyTo>
      </gx:Playlist>
    </gx:Tour>
  </Document>
</kml>''';

      final client = _sshService.client!;
      // 1. Upload KML
      final escapedKml = tourKml.replaceAll('"', '\\"').replaceAll('\$', '\\\$');
      debugPrint('Uploading tour KML...');
      await client.run('echo "$escapedKml" > /var/www/html/kml/master.kml');

      // 2. Force Refresh
      await _forceRefresh('master.kml');

      // 3. Wait for Earth to parse
      debugPrint('Waiting for Earth to parse...');
      await Future.delayed(const Duration(seconds: 1));

      // 4. Play Tour
      debugPrint('Playing tour...');
      await client.run('echo "playtour=FlyTo" > /tmp/query.txt');
    } catch (e) {
      debugPrint('FlyTo failed: $e');
    }
  }

  /// Sends a logo to a specific screen (e.g., slave_3).
  Future<void> sendLogo({required String screen, required String imageUrl}) async {
    if (!await _ensureConnection()) return;

    try {
      final kml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>Logo</name>
    <Folder>
      <name>Logo</name>
      <ScreenOverlay>
        <name>Logo</name>
        <Icon>
          <href>$imageUrl</href>
        </Icon>
        <overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
        <screenXY x="0.02" y="0.98" xunits="fraction" yunits="fraction"/>
        <rotationXY x="0" y="0" xunits="fraction" yunits="fraction"/>
        <size x="300" y="300" xunits="pixels" yunits="pixels"/>
      </ScreenOverlay>
    </Folder>
  </Document>
</kml>''';

      final client = _sshService.client!;
      final kmlPath = '/var/www/html/kml/slave_$screen.kml';
      final escapedKml = kml.replaceAll('"', '\\"').replaceAll('\$', '\\\$');

      debugPrint('Sending logo to slave_$screen...');
      await client.run('echo "$escapedKml" > $kmlPath');
      await _forceRefresh('slave_$screen.kml');
    } catch (e) {
      debugPrint('SendLogo failed: $e');
    }
  }

  /// Clears the logo from a specific screen.
  Future<void> clearLogo(String screen) async {
    if (!await _ensureConnection()) return;

    try {
      final blankKml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document><name>Empty</name></Document>
</kml>''';

      final client = _sshService.client!;
      final kmlPath = '/var/www/html/kml/slave_$screen.kml';
      final escapedKml = blankKml.replaceAll('"', '\\"').replaceAll('\$', '\\\$');

      debugPrint('Clearing logo from slave_$screen...');
      await client.run('echo "$escapedKml" > $kmlPath');
      await _forceRefresh('slave_$screen.kml');
    } catch (e) {
      debugPrint('ClearLogo failed: $e');
    }
  }

  /// Clears all KML from the master screen.
  Future<void> clearKml() async {
    if (!await _ensureConnection()) return;

    try {
      final blankKml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Cleared</name>
    <description>All content cleared</description>
  </Document>
</kml>''';

      final client = _sshService.client!;
      const kmlPath = '/var/www/html/kml/master.kml';
      final escapedKml = blankKml.replaceAll('"', '\\"').replaceAll('\$', '\\\$');

      debugPrint('Clearing all KML from master...');
      await client.run('echo "$escapedKml" > $kmlPath');
      await _forceRefresh('master.kml');
      debugPrint('KML cleared successfully!');
    } catch (e) {
      debugPrint('ClearKml failed: $e');
    }
  }

  /// Sends raw KML to the master screen.
  Future<void> sendKmlToMaster(String kml) async {
    if (!await _ensureConnection()) return;

    try {
      final client = _sshService.client!;
      const kmlPath = '/var/www/html/kml/master.kml';
      final escapedKml = kml.replaceAll('"', '\\"').replaceAll(r'$', r'\$');

      debugPrint('Uploading custom KML to master...');
      await client.run('echo "$escapedKml" > $kmlPath');
      await _forceRefresh('master.kml');
    } catch (e) {
      debugPrint('SendKmlToMaster failed: $e');
    }
  }

  /// Plays a tour by name (gx:Tour must already be loaded on master).
  Future<void> playTour(String tourName) async {
    if (!await _ensureConnection()) return;

    try {
      final client = _sshService.client!;
      await client.run('echo "playtour=$tourName" > /tmp/query.txt');
    } catch (e) {
      debugPrint('PlayTour failed: $e');
    }
  }

  /// Sends a 3D colored pyramid to a specific location.
  /// 
  /// Parameters:
  /// - latitude: Location latitude (-90 to 90)
  /// - longitude: Location longitude (-180 to 180)
  /// - altitude: Peak altitude in meters
  /// - baseSize: Base width/height in degrees (default: 0.01 degrees ≈ 1 km)
  /// - color: AABBGGRR format (default: ffff0000 = solid blue)
  /// - name: Name of the pyramid placemark
  Future<void> sendColoredPyramid({
    required double latitude,
    required double longitude,
    required double altitude,
    double baseSize = 0.01,
    String color = 'ffff0000', // AABBGGRR: Blue
    String name = 'Colored Pyramid',
  }) async {
    if (!await _ensureConnection()) return;

    try {
      // Create pyramid geometry: 4 triangular faces + 1 base
      // Calculate base corners
      final halfSize = baseSize / 2;
      final lat1 = latitude + halfSize;
      final lat2 = latitude - halfSize;
      final lon1 = longitude + halfSize;
      final lon2 = longitude - halfSize;
      final peakLat = latitude;
      final peakLon = longitude;

      // Build the pyramid as multiple polygons for each face
      final pyramidKml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>$name</name>
    <Style id="pyramidStyle">
      <PolyStyle>
        <color>$color</color>
        <colorMode>normal</colorMode>
        <fill>1</fill>
        <outline>1</outline>
      </PolyStyle>
      <LineStyle>
        <color>ff000000</color>
        <width>2</width>
      </LineStyle>
    </Style>
    
    <!-- Base of pyramid -->
    <Placemark>
      <name>$name - Base</name>
      <styleUrl>#pyramidStyle</styleUrl>
      <Polygon>
        <extrude>0</extrude>
        <altitudeMode>relativeToGround</altitudeMode>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
              $lon1,$lat1,0
              $lon2,$lat1,0
              $lon2,$lat2,0
              $lon1,$lat2,0
              $lon1,$lat1,0
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>
    
    <!-- Front face (North) -->
    <Placemark>
      <name>$name - North Face</name>
      <styleUrl>#pyramidStyle</styleUrl>
      <Polygon>
        <extrude>0</extrude>
        <altitudeMode>relativeToGround</altitudeMode>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
              $lon1,$lat1,0
              $lon2,$lat1,0
              $peakLon,$peakLat,$altitude
              $lon1,$lat1,0
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>
    
    <!-- South face -->
    <Placemark>
      <name>$name - South Face</name>
      <styleUrl>#pyramidStyle</styleUrl>
      <Polygon>
        <extrude>0</extrude>
        <altitudeMode>relativeToGround</altitudeMode>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
              $lon2,$lat2,0
              $lon1,$lat2,0
              $peakLon,$peakLat,$altitude
              $lon2,$lat2,0
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>
    
    <!-- East face -->
    <Placemark>
      <name>$name - East Face</name>
      <styleUrl>#pyramidStyle</styleUrl>
      <Polygon>
        <extrude>0</extrude>
        <altitudeMode>relativeToGround</altitudeMode>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
              $lon1,$lat2,0
              $lon1,$lat1,0
              $peakLon,$peakLat,$altitude
              $lon1,$lat2,0
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>
    
    <!-- West face -->
    <Placemark>
      <name>$name - West Face</name>
      <styleUrl>#pyramidStyle</styleUrl>
      <Polygon>
        <extrude>0</extrude>
        <altitudeMode>relativeToGround</altitudeMode>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
              $lon2,$lat1,0
              $lon2,$lat2,0
              $peakLon,$peakLat,$altitude
              $lon2,$lat1,0
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
      </Polygon>
    </Placemark>
  </Document>
</kml>''';

      final client = _sshService.client!;
      const kmlPath = '/var/www/html/kml/master.kml';
      final escapedKml = pyramidKml.replaceAll('"', '\\"').replaceAll('\$', '\\\$');

      debugPrint('Uploading colored pyramid KML...');
      await client.run('echo "$escapedKml" > $kmlPath');

      // Force refresh
      await _forceRefresh('master.kml');

      debugPrint('Pyramid sent successfully!');
    } catch (e) {
      debugPrint('SendColoredPyramid failed: $e');
    }
  }

  /// Force refresh definition from SKILL.md
  Future<void> _forceRefresh(String kmlFileName) async {
    try {
      final client = _sshService.client!;
      final escapedFile = kmlFileName.replaceAll('/', '\\/'); // Escape slashes for sed

      final isMaster = kmlFileName.contains('master');
      final myplacesPath = isMaster
          ? '~/earth/kml/master/myplaces.kml'
          : '~/earth/kml/slave/myplaces.kml';

      // 1. Add refresh interval
      final addCommand =
          'sed -i "s|<href>[^<]*$escapedFile<\/href>|&<refreshMode>onInterval<\/refreshMode><refreshInterval>1<\/refreshInterval>|" $myplacesPath';
      await client.run(addCommand);

      await Future.delayed(const Duration(seconds: 1));

      // 2. Remove refresh interval (revert to clean state)
      // Note: The replacement string pattern matches what was added.
      // We look for the file + the refresh tags we added, and replace with just the file href (using the standard LG path prefix if needed, or just preserving original).
      // Standard LG kml link usually looks like: <href>##LG_PHPIFACE##kml/master.kml</href>
      // The sed command in SKILL.md was:
      // s|<href>[^<]*$escapedFile<\/href><refreshMode>onInterval<\/refreshMode><refreshInterval>[0-9]\+<\/refreshInterval>|<href>##LG_PHPIFACE##kml/$escapedFile<\/href>|
      
      final removeCommand =
          'sed -i "s|<href>[^<]*$escapedFile<\/href><refreshMode>onInterval<\/refreshMode><refreshInterval>[0-9]\+<\/refreshInterval>|<href>##LG_PHPIFACE##kml/$escapedFile<\/href>|" $myplacesPath';
      
      await client.run(removeCommand);
    } catch (e) {
      debugPrint('ForceRefresh failed: $e');
    }
  }
}

final kmlServiceProvider = Provider<KMLService>((ref) {
  return KMLService(ref.watch(sshServiceProvider));
});
