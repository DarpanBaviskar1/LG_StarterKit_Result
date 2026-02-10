# LG Repository Examples and Patterns

This document contains examples and patterns derived from open-source Liquid Galaxy projects at https://github.com/LiquidGalaxyLAB/

## 📦 Key Repositories to Study

### 1. **lg_controller** - Reference Controller App
Repository: https://github.com/LiquidGalaxyLAB/lg_controller

**Key Learnings:**
- SSH connection management patterns
- Settings persistence
- UI layouts for tablet controllers
- Basic KML operations

**Notable Files to Study:**
- `lib/services/ssh_service.dart` - SSH implementation
- `lib/models/connection_config.dart` - Configuration management
- `lib/screens/connection_screen.dart` - Connection UI patterns

### 2. **LG-Gemma-AI-Touristic-info-tool** - Modern Architecture
Repository: https://github.com/LiquidGalaxyLAB/LG-Gemma-AI-Touristic-info-tool

**Key Learnings:**
- AI integration with LG
- Modern Flutter architecture
- Complex KML generation
- Tour management

**Notable Patterns:**
- Feature-first structure
- Provider pattern for state
- Service layer abstraction

### 3. **LG-Display-Server** - Server Communication
Repository: https://github.com/LiquidGalaxyLAB/LG-Display-Server

**Key Learnings:**
- Server-side KML handling
- Multi-screen coordination
- Display management

### 4. **FAED-food-excess-Identification** - Complete App Example
Repository: https://github.com/LiquidGalaxyLAB/FAED-food-excess-Identification

**Key Learnings:**
- Real-world data visualization
- Complex UI/UX patterns
- Data management with LG

---

## 🎯 Common Patterns from LG Projects

### Pattern 1: SSH Connection Singleton

**Found in multiple projects:**

```dart
class SSHManager {
  static final SSHManager _instance = SSHManager._internal();
  factory SSHManager() => _instance;
  SSHManager._internal();
  
  SSHClient? _client;
  bool _isConnected = false;
  
  bool get isConnected => _isConnected;
  
  Future<bool> connect({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    try {
      if (_isConnected) {
        await disconnect();
      }
      
      final socket = await SSHSocket.connect(host, port);
      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );
      
      _isConnected = true;
      return true;
    } catch (e) {
      print('Connection error: $e');
      _isConnected = false;
      return false;
    }
  }
  
  Future<void> disconnect() async {
    _client?.close();
    await _client?.done;
    _client = null;
    _isConnected = false;
  }
  
  Future<SSHSession?> execute(String command) async {
    if (!_isConnected || _client == null) return null;
    
    try {
      return await _client!.execute(command);
    } catch (e) {
      print('Execute error: $e');
      return null;
    }
  }
}
```

### Pattern 2: LG Commands Utility

**Commonly used LG commands:**

```dart
class LGCommands {
  // Relaunch Google Earth
  static const String relaunch = '''
    if [[ \$(pgrep -c chromium) -eq 0 ]]; then
      echo "true"
    else
      killall -9 chromium chromium-browse
      echo "false"
    fi
  ''';
  
  // Get screen count
  static const String getScreenCount = '''
    cat /lg/personavars.txt | grep SCREEN_NUM | cut -d'=' -f2
  ''';
  
  // Clean slaves
  static String cleanSlave(int slaveId) => '''
    echo "\$(cat /tmp/query.txt)" > /var/www/html/kml/slave_$slaveId.kml
  ''';
  
  // Send KML to slave
  static String sendKMLToSlave(String kmlContent, int slaveId) => '''
    echo '$kmlContent' > /var/www/html/kml/slave_$slaveId.kml
  ''';
  
  // Send query
  static String sendQuery(String kmlUrl) => '''
    echo "$kmlUrl" > /tmp/query.txt
  ''';
  
  // Set refresh
  static const String setRefresh = '''
    echo "exittour=true" > /tmp/query.txt
  ''';
  
  // Reboot LG
  static const String reboot = '''
    reboot
  ''';
  
  // Shutdown LG
  static const String shutdown = '''
    poweroff
  ''';
}
```

### Pattern 3: KML File Management

**Standard approach from projects:**

```dart
class KMLFileManager {
  final SSHManager _ssh = SSHManager();
  
  Future<bool> uploadKML(String kmlContent, String filename) async {
    if (!_ssh.isConnected) return false;
    
    // Escape single quotes in KML
    final escapedKML = kmlContent.replaceAll("'", "'\\''");
    
    // Write to file
    final command = "echo '$escapedKML' > /var/www/html/kml/$filename.kml";
    final result = await _ssh.execute(command);
    
    return result != null;
  }
  
  Future<bool> sendToGoogleEarth(String filename) async {
    if (!_ssh.isConnected) return false;
    
    final url = 'http://lg1:81/$filename.kml';
    final command = 'echo "$url" > /tmp/query.txt';
    final result = await _ssh.execute(command);
    
    return result != null;
  }
  
  Future<bool> sendAndDisplay(String kmlContent, String filename) async {
    final uploaded = await uploadKML(kmlContent, filename);
    if (!uploaded) return false;
    
    return await sendToGoogleEarth(filename);
  }
  
  Future<bool> clearScreen(int screenId) async {
    if (!_ssh.isConnected) return false;
    
    final command = LGCommands.cleanSlave(screenId);
    final result = await _ssh.execute(command);
    
    return result != null;
  }
  
  Future<bool> clearAllScreens(int screenCount) async {
    for (int i = 2; i <= screenCount; i++) {
      await clearScreen(i);
    }
    return true;
  }
}
```

### Pattern 4: Connection Settings Screen

**Standard UI pattern:**

```dart
class ConnectionScreen extends StatefulWidget {
  @override
  _ConnectionScreenState createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _usernameController = TextEditingController(text: 'lg');
  final _passwordController = TextEditingController();
  
  bool _isConnecting = false;
  bool _obscurePassword = true;
  
  @override
  void initState() {
    super.initState();
    _loadSavedSettings();
  }
  
  Future<void> _loadSavedSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _hostController.text = prefs.getString('ssh_host') ?? '';
      _portController.text = prefs.getString('ssh_port') ?? '22';
      _usernameController.text = prefs.getString('ssh_username') ?? 'lg';
    });
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ssh_host', _hostController.text);
    await prefs.setString('ssh_port', _portController.text);
    await prefs.setString('ssh_username', _usernameController.text);
  }
  
  Future<void> _connect() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isConnecting = true);
    
    final ssh = SSHManager();
    final success = await ssh.connect(
      host: _hostController.text,
      port: int.parse(_portController.text),
      username: _usernameController.text,
      password: _passwordController.text,
    );
    
    setState(() => _isConnecting = false);
    
    if (success) {
      await _saveSettings();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connected successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Connection failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('LG Connection'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _hostController,
              decoration: InputDecoration(
                labelText: 'Host IP',
                prefixIcon: Icon(Icons.computer),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter host IP';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _portController,
              decoration: InputDecoration(
                labelText: 'Port',
                prefixIcon: Icon(Icons.settings_ethernet),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter port';
                }
                final port = int.tryParse(value);
                if (port == null || port < 1 || port > 65535) {
                  return 'Invalid port number';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter username';
                }
                return null;
              },
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: Icon(Icons.lock),
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
              obscureText: _obscurePassword,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter password';
                }
                return null;
              },
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isConnecting ? null : _connect,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isConnecting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('CONNECT', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
```

### Pattern 5: Tour Implementation

**Based on multiple tourism apps:**

```dart
class TourPoint {
  final String name;
  final double latitude;
  final double longitude;
  final double altitude;
  final String? description;
  final double duration; // seconds to fly
  final double waitTime; // seconds to wait
  
  const TourPoint({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.altitude = 0,
    this.description,
    this.duration = 3.0,
    this.waitTime = 2.0,
  });
}

class Tour {
  final String id;
  final String name;
  final String description;
  final List<TourPoint> points;
  
  const Tour({
    required this.id,
    required this.name,
    required this.description,
    required this.points,
  });
}

class TourManager {
  final KMLFileManager _kmlManager = KMLFileManager();
  
  Future<bool> startTour(Tour tour) async {
    final kml = _buildTourKML(tour);
    return await _kmlManager.sendAndDisplay(kml, 'tour_${tour.id}');
  }
  
  String _buildTourKML(Tour tour) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2"');
    buffer.writeln('     xmlns:gx="http://www.google.com/kml/ext/2.2">');
    buffer.writeln('  <Document>');
    buffer.writeln('    <name>${tour.name}</name>');
    buffer.writeln('    <description>${tour.description}</description>');
    
    // Add tour
    buffer.writeln('    <gx:Tour>');
    buffer.writeln('      <name>${tour.name}</name>');
    buffer.writeln('      <gx:Playlist>');
    
    for (final point in tour.points) {
      // FlyTo
      buffer.writeln('        <gx:FlyTo>');
      buffer.writeln('          <gx:duration>${point.duration}</gx:duration>');
      buffer.writeln('          <gx:flyToMode>smooth</gx:flyToMode>');
      buffer.writeln('          <LookAt>');
      buffer.writeln('            <longitude>${point.longitude}</longitude>');
      buffer.writeln('            <latitude>${point.latitude}</latitude>');
      buffer.writeln('            <altitude>${point.altitude}</altitude>');
      buffer.writeln('            <range>5000</range>');
      buffer.writeln('            <tilt>60</tilt>');
      buffer.writeln('            <heading>0</heading>');
      buffer.writeln('            <gx:altitudeMode>relativeToGround</gx:altitudeMode>');
      buffer.writeln('          </LookAt>');
      buffer.writeln('        </gx:FlyTo>');
      
      // Wait
      buffer.writeln('        <gx:Wait>');
      buffer.writeln('          <gx:duration>${point.waitTime}</gx:duration>');
      buffer.writeln('        </gx:Wait>');
    }
    
    buffer.writeln('      </gx:Playlist>');
    buffer.writeln('    </gx:Tour>');
    
    // Add placemarks
    for (final point in tour.points) {
      buffer.writeln('    <Placemark>');
      buffer.writeln('      <name>${point.name}</name>');
      if (point.description != null) {
        buffer.writeln('      <description>${point.description}</description>');
      }
      buffer.writeln('      <Point>');
      buffer.writeln('        <coordinates>${point.longitude},${point.latitude},${point.altitude}</coordinates>');
      buffer.writeln('      </Point>');
      buffer.writeln('    </Placemark>');
    }
    
    buffer.writeln('  </Document>');
    buffer.writeln('</kml>');
    
    return buffer.toString();
  }
  
  Future<bool> stopTour() async {
    final ssh = SSHManager();
    final result = await ssh.execute(LGCommands.setRefresh);
    return result != null;
  }
}
```

---

## 🎓 Learning from Real Projects

### Example 1: Orbit Feature (Rotating View)

**Common in visualization apps:**

```dart
class OrbitController {
  final KMLFileManager _kmlManager;
  bool _isOrbiting = false;
  
  OrbitController(this._kmlManager);
  
  Future<void> startOrbit({
    required double latitude,
    required double longitude,
    required double altitude,
    int rotations = 1,
    double duration = 60.0, // seconds for full rotation
  }) async {
    _isOrbiting = true;
    
    final kml = _buildOrbitKML(
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      rotations: rotations,
      duration: duration,
    );
    
    await _kmlManager.sendAndDisplay(kml, 'orbit');
  }
  
  String _buildOrbitKML({
    required double latitude,
    required double longitude,
    required double altitude,
    required int rotations,
    required double duration,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2"');
    buffer.writeln('     xmlns:gx="http://www.google.com/kml/ext/2.2">');
    buffer.writeln('  <Document>');
    buffer.writeln('    <name>Orbit</name>');
    buffer.writeln('    <gx:Tour>');
    buffer.writeln('      <name>Orbit Tour</name>');
    buffer.writeln('      <gx:Playlist>');
    
    // Generate orbit points
    final steps = 36; // 10 degree increments
    final stepDuration = duration / steps / rotations;
    
    for (int rotation = 0; rotation < rotations; rotation++) {
      for (int i = 0; i < steps; i++) {
        final heading = (i * 10.0) % 360;
        
        buffer.writeln('        <gx:FlyTo>');
        buffer.writeln('          <gx:duration>$stepDuration</gx:duration>');
        buffer.writeln('          <gx:flyToMode>smooth</gx:flyToMode>');
        buffer.writeln('          <LookAt>');
        buffer.writeln('            <longitude>$longitude</longitude>');
        buffer.writeln('            <latitude>$latitude</latitude>');
        buffer.writeln('            <altitude>$altitude</altitude>');
        buffer.writeln('            <range>5000</range>');
        buffer.writeln('            <tilt>60</tilt>');
        buffer.writeln('            <heading>$heading</heading>');
        buffer.writeln('            <gx:altitudeMode>relativeToGround</gx:altitudeMode>');
        buffer.writeln('          </LookAt>');
        buffer.writeln('        </gx:FlyTo>');
      }
    }
    
    buffer.writeln('      </gx:Playlist>');
    buffer.writeln('    </gx:Tour>');
    buffer.writeln('  </Document>');
    buffer.writeln('</kml>');
    
    return buffer.toString();
  }
  
  Future<void> stopOrbit() async {
    _isOrbiting = false;
    final ssh = SSHManager();
    await ssh.execute(LGCommands.setRefresh);
  }
}
```

### Example 2: Logo/Overlay Management

**Used in many branding implementations:**

```dart
class LogoManager {
  final SSHManager _ssh = SSHManager();
  
  Future<bool> showLogo({
    required String imageUrl,
    required int screenId,
  }) async {
    final kml = _buildLogoKML(imageUrl);
    final command = "echo '$kml' > /var/www/html/kml/slave_$screenId.kml";
    final result = await _ssh.execute(command);
    return result != null;
  }
  
  String _buildLogoKML(String imageUrl) {
    return '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <ScreenOverlay>
      <name>Logo</name>
      <Icon>
        <href>$imageUrl</href>
      </Icon>
      <overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
      <screenXY x="0" y="1" xunits="fraction" yunits="fraction"/>
      <size x="0.2" y="0" xunits="fraction" yunits="fraction"/>
    </ScreenOverlay>
  </Document>
</kml>
''';
  }
  
  Future<bool> removeLogo(int screenId) async {
    final command = LGCommands.cleanSlave(screenId);
    final result = await _ssh.execute(command);
    return result != null;
  }
}
```

---

## 📊 Data Visualization Patterns

### Pattern: Showing Data Points on LG

```dart
class DataVisualizer {
  final KMLFileManager _kmlManager;
  
  DataVisualizer(this._kmlManager);
  
  Future<bool> visualizePoints(List<DataPoint> points) async {
    final kml = _buildPointsKML(points);
    return await _kmlManager.sendAndDisplay(kml, 'data_points');
  }
  
  String _buildPointsKML(List<DataPoint> points) {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
    buffer.writeln('  <Document>');
    buffer.writeln('    <name>Data Visualization</name>');
    
    // Add styles
    buffer.writeln(_buildStyles());
    
    // Add points
    for (final point in points) {
      buffer.writeln(_buildPointPlacemark(point));
    }
    
    buffer.writeln('  </Document>');
    buffer.writeln('</kml>');
    
    return buffer.toString();
  }
  
  String _buildStyles() {
    return '''
    <Style id="high">
      <IconStyle>
        <color>ff0000ff</color>
        <scale>1.2</scale>
        <Icon>
          <href>http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png</href>
        </Icon>
      </IconStyle>
    </Style>
    <Style id="medium">
      <IconStyle>
        <color>ff00ffff</color>
        <scale>1.0</scale>
        <Icon>
          <href>http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png</href>
        </Icon>
      </IconStyle>
    </Style>
    <Style id="low">
      <IconStyle>
        <color>ff00ff00</color>
        <scale>0.8</scale>
        <Icon>
          <href>http://maps.google.com/mapfiles/kml/shapes/placemark_circle.png</href>
        </Icon>
      </IconStyle>
    </Style>
''';
  }
  
  String _buildPointPlacemark(DataPoint point) {
    final styleId = _getStyleForValue(point.value);
    return '''
    <Placemark>
      <name>${point.name}</name>
      <description><![CDATA[
        <h3>${point.name}</h3>
        <p>Value: ${point.value}</p>
        <p>${point.description}</p>
      ]]></description>
      <styleUrl>#$styleId</styleUrl>
      <Point>
        <coordinates>${point.longitude},${point.latitude},0</coordinates>
      </Point>
    </Placemark>
''';
  }
  
  String _getStyleForValue(double value) {
    if (value > 75) return 'high';
    if (value > 25) return 'medium';
    return 'low';
  }
}

class DataPoint {
  final String name;
  final double latitude;
  final double longitude;
  final double value;
  final String description;
  
  DataPoint({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.value,
    required this.description,
  });
}
```

---

## 🔧 Debugging and Testing Patterns

### Testing SSH Connection

```dart
class ConnectionTester {
  static Future<ConnectionTestResult> testConnection({
    required String host,
    required int port,
    required String username,
    required String password,
  }) async {
    final stopwatch = Stopwatch()..start();
    
    try {
      final socket = await SSHSocket.connect(host, port)
          .timeout(Duration(seconds: 5));
      
      final client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );
      
      // Test command execution
      final result = await client.run('echo "test"');
      final output = utf8.decode(result);
      
      stopwatch.stop();
      
      client.close();
      await client.done;
      
      return ConnectionTestResult(
        success: true,
        latency: stopwatch.elapsedMilliseconds,
        message: 'Connection successful',
      );
    } catch (e) {
      stopwatch.stop();
      
      return ConnectionTestResult(
        success: false,
        latency: stopwatch.elapsedMilliseconds,
        message: 'Connection failed: $e',
      );
    }
  }
}

class ConnectionTestResult {
  final bool success;
  final int latency;
  final String message;
  
  ConnectionTestResult({
    required this.success,
    required this.latency,
    required this.message,
  });
}
```

---

## Summary

All these patterns are derived from real-world LG projects. Study the repositories at https://github.com/LiquidGalaxyLAB/ for more examples and implementation details.

Key takeaways:
- ✅ SSH management is critical
- ✅ KML generation should be modular
- ✅ Always handle errors gracefully
- ✅ Persist user settings
- ✅ Provide clear feedback
- ✅ Test connections before operations
