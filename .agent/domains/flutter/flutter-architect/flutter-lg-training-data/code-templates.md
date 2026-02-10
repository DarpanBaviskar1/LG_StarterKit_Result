# Flutter + LG Code Templates

Ready-to-use code templates for common Liquid Galaxy Flutter app scenarios.

---

## 📋 Template 1: Basic SSH Service

```dart
// lib/src/services/ssh_service.dart
import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';

class SSHService {
  SSHClient? _client;
  bool _isConnected = false;
  
  bool get isConnected => _isConnected;
  
  /// Connect to SSH server
  Future<SSHResult> connect({
    required String host,
    required String username,
    required String password,
    int port = 22,
  }) async {
    try {
      // Close existing connection if any
      if (_isConnected) {
        await disconnect();
      }
      
      // Create socket with timeout
      final socket = await SSHSocket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );
      
      // Create SSH client
      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );
      
      // Test connection
      await _client!.run('echo "test"');
      
      _isConnected = true;
      return SSHResult.success('Connected successfully');
    } catch (e) {
      _isConnected = false;
      debugPrint('SSH Connection Error: $e');
      return SSHResult.failure('Connection failed: $e');
    }
  }
  
  /// Disconnect from SSH server
  Future<void> disconnect() async {
    try {
      _client?.close();
      await _client?.done;
    } catch (e) {
      debugPrint('Disconnect error: $e');
    } finally {
      _client = null;
      _isConnected = false;
    }
  }
  
  /// Execute a command on the SSH server
  Future<SSHResult> execute(String command) async {
    if (!_isConnected || _client == null) {
      return SSHResult.failure('Not connected to SSH server');
    }
    
    try {
      final result = await _client!.run(command);
      final output = utf8.decode(result);
      return SSHResult.success(output);
    } catch (e) {
      debugPrint('Execute error: $e');
      return SSHResult.failure('Command execution failed: $e');
    }
  }
  
  /// Execute a command with timeout
  Future<SSHResult> executeWithTimeout(
    String command, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      final result = await execute(command).timeout(timeout);
      return result;
    } on TimeoutException {
      return SSHResult.failure('Command timed out');
    }
  }
}

/// Result wrapper for SSH operations
class SSHResult {
  final bool isSuccess;
  final String message;
  
  SSHResult.success(this.message) : isSuccess = true;
  SSHResult.failure(this.message) : isSuccess = false;
  
  bool get isFailure => !isSuccess;
}
```

---

## 📋 Template 2: LG Service Layer

```dart
// lib/src/services/lg_service.dart
import 'ssh_service.dart';

class LGService {
  final SSHService _ssh;
  
  LGService(this._ssh);
  
  /// Send KML content to Liquid Galaxy
  Future<SSHResult> sendKML(String kmlContent, String filename) async {
    // Escape single quotes for shell
    final escaped = kmlContent.replaceAll("'", "'\\''");
    
    // Write KML to file
    final writeResult = await _ssh.execute(
      "echo '$escaped' > /var/www/html/kml/$filename.kml",
    );
    
    if (writeResult.isFailure) {
      return writeResult;
    }
    
    // Send query to display
    final queryResult = await _ssh.execute(
      'echo "http://lg1:81/$filename.kml" > /tmp/query.txt',
    );
    
    return queryResult;
  }
  
  /// Clean all slave screens
  Future<SSHResult> cleanSlaves({int screenCount = 5}) async {
    for (int i = 2; i <= screenCount; i++) {
      final result = await _ssh.execute(
        'echo "" > /var/www/html/kml/slave_$i.kml',
      );
      
      if (result.isFailure) {
        return result;
      }
    }
    
    return SSHResult.success('Slaves cleaned');
  }
  
  /// Relaunch Liquid Galaxy
  Future<SSHResult> relaunch() async {
    return await _ssh.execute('''
      if pgrep -x "chromium" > /dev/null; then
        killall -9 chromium
      fi
      sleep 2
      lg-relaunch
    ''');
  }
  
  /// Set refresh (exit tour)
  Future<SSHResult> setRefresh() async {
    return await _ssh.execute('echo "exittour=true" > /tmp/query.txt');
  }
  
  /// Get screen count from configuration
  Future<int> getScreenCount() async {
    final result = await _ssh.execute(
      'cat /lg/personavars.txt | grep SCREEN_NUM | cut -d"=" -f2',
    );
    
    if (result.isSuccess) {
      try {
        return int.parse(result.message.trim());
      } catch (e) {
        return 3; // Default fallback
      }
    }
    
    return 3; // Default fallback
  }
  
  /// Fly to a location
  Future<SSHResult> flyTo({
    required double latitude,
    required double longitude,
    double altitude = 0,
    double range = 5000,
    double tilt = 60,
    double heading = 0,
  }) async {
    final kml = '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <LookAt>
    <longitude>$longitude</longitude>
    <latitude>$latitude</latitude>
    <altitude>$altitude</altitude>
    <range>$range</range>
    <tilt>$tilt</tilt>
    <heading>$heading</heading>
    <gx:altitudeMode>relativeToGround</gx:altitudeMode>
  </LookAt>
</kml>
''';
    
    return await sendKML(kml, 'flyto');
  }
}
```

---

## 📋 Template 3: KML Builder Utilities

```dart
// lib/src/utils/kml/kml_builder.dart

class KMLBuilder {
  /// Create KML document wrapper
  static String wrapDocument(String content, {String name = 'Document'}) {
    return '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>$name</name>
    $content
  </Document>
</kml>
''';
  }
  
  /// Build a placemark
  static String buildPlacemark({
    required String name,
    required double latitude,
    required double longitude,
    double altitude = 0,
    String? description,
    String? iconUrl,
  }) {
    final desc = description != null 
        ? '<description><![CDATA[$description]]></description>' 
        : '';
    
    final icon = iconUrl != null ? '''
    <Style>
      <IconStyle>
        <Icon>
          <href>$iconUrl</href>
        </Icon>
      </IconStyle>
    </Style>
''' : '';
    
    return '''
<Placemark>
  <name>$name</name>
  $desc
  $icon
  <Point>
    <coordinates>$longitude,$latitude,$altitude</coordinates>
  </Point>
</Placemark>
''';
  }
  
  /// Build a line string (path)
  static String buildLineString({
    required String name,
    required List<Map<String, double>> coordinates,
    String color = 'ff0000ff', // AABBGGRR format
    double width = 2.0,
  }) {
    final coordsString = coordinates
        .map((c) => '${c['longitude']},${c['latitude']},${c['altitude'] ?? 0}')
        .join('\n        ');
    
    return '''
<Placemark>
  <name>$name</name>
  <Style>
    <LineStyle>
      <color>$color</color>
      <width>$width</width>
    </LineStyle>
  </Style>
  <LineString>
    <coordinates>
      $coordsString
    </coordinates>
  </LineString>
</Placemark>
''';
  }
  
  /// Build a polygon
  static String buildPolygon({
    required String name,
    required List<Map<String, double>> coordinates,
    String fillColor = '7f0000ff',
    String lineColor = 'ff0000ff',
    double lineWidth = 2.0,
  }) {
    final coordsString = coordinates
        .map((c) => '${c['longitude']},${c['latitude']},${c['altitude'] ?? 0}')
        .join('\n          ');
    
    return '''
<Placemark>
  <name>$name</name>
  <Style>
    <LineStyle>
      <color>$lineColor</color>
      <width>$lineWidth</width>
    </LineStyle>
    <PolyStyle>
      <color>$fillColor</color>
    </PolyStyle>
  </Style>
  <Polygon>
    <outerBoundaryIs>
      <LinearRing>
        <coordinates>
          $coordsString
        </coordinates>
      </LinearRing>
    </outerBoundaryIs>
  </Polygon>
</Placemark>
''';
  }
  
  /// Build a screen overlay (logo, watermark)
  static String buildScreenOverlay({
    required String name,
    required String imageUrl,
    double x = 0,
    double y = 1,
    double sizeX = 0.2,
    double sizeY = 0,
  }) {
    return '''
<ScreenOverlay>
  <name>$name</name>
  <Icon>
    <href>$imageUrl</href>
  </Icon>
  <overlayXY x="$x" y="$y" xunits="fraction" yunits="fraction"/>
  <screenXY x="$x" y="$y" xunits="fraction" yunits="fraction"/>
  <size x="$sizeX" y="$sizeY" xunits="fraction" yunits="fraction"/>
</ScreenOverlay>
''';
  }
  
  /// Build a tour
  static String buildTour({
    required String name,
    required List<TourPoint> points,
  }) {
    final playlist = points.map((point) => '''
<gx:FlyTo>
  <gx:duration>${point.duration}</gx:duration>
  <gx:flyToMode>smooth</gx:flyToMode>
  <LookAt>
    <longitude>${point.longitude}</longitude>
    <latitude>${point.latitude}</latitude>
    <altitude>${point.altitude}</altitude>
    <range>${point.range}</range>
    <tilt>${point.tilt}</tilt>
    <heading>${point.heading}</heading>
    <gx:altitudeMode>relativeToGround</gx:altitudeMode>
  </LookAt>
</gx:FlyTo>
<gx:Wait>
  <gx:duration>${point.waitTime}</gx:duration>
</gx:Wait>
''').join('\n');
    
    return '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>$name</name>
    <gx:Tour>
      <name>$name</name>
      <gx:Playlist>
        $playlist
      </gx:Playlist>
    </gx:Tour>
  </Document>
</kml>
''';
  }
}

class TourPoint {
  final double latitude;
  final double longitude;
  final double altitude;
  final double range;
  final double tilt;
  final double heading;
  final double duration;
  final double waitTime;
  
  const TourPoint({
    required this.latitude,
    required this.longitude,
    this.altitude = 0,
    this.range = 5000,
    this.tilt = 60,
    this.heading = 0,
    this.duration = 3.0,
    this.waitTime = 2.0,
  });
}
```

---

## 📋 Template 4: Connection State with Riverpod

```dart
// lib/src/features/connection/models/lg_config.dart
class LGConfig {
  final String host;
  final String username;
  final String password;
  final int port;
  
  const LGConfig({
    required this.host,
    required this.username,
    required this.password,
    this.port = 22,
  });
  
  Map<String, dynamic> toJson() => {
    'host': host,
    'username': username,
    'password': password,
    'port': port,
  };
  
  factory LGConfig.fromJson(Map<String, dynamic> json) => LGConfig(
    host: json['host'] as String,
    username: json['username'] as String,
    password: json['password'] as String,
    port: json['port'] as int? ?? 22,
  );
}

// lib/src/features/connection/providers/connection_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectionState {
  final bool isConnected;
  final bool isConnecting;
  final String? errorMessage;
  final LGConfig? config;
  
  const ConnectionState({
    this.isConnected = false,
    this.isConnecting = false,
    this.errorMessage,
    this.config,
  });
  
  ConnectionState copyWith({
    bool? isConnected,
    bool? isConnecting,
    String? errorMessage,
    LGConfig? config,
  }) {
    return ConnectionState(
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      errorMessage: errorMessage,
      config: config ?? this.config,
    );
  }
}

class ConnectionNotifier extends StateNotifier<ConnectionState> {
  final SSHService _sshService;
  
  ConnectionNotifier(this._sshService) : super(const ConnectionState());
  
  Future<void> connect(LGConfig config) async {
    state = state.copyWith(isConnecting: true, errorMessage: null);
    
    final result = await _sshService.connect(
      host: config.host,
      username: config.username,
      password: config.password,
      port: config.port,
    );
    
    if (result.isSuccess) {
      state = state.copyWith(
        isConnected: true,
        isConnecting: false,
        config: config,
      );
    } else {
      state = state.copyWith(
        isConnected: false,
        isConnecting: false,
        errorMessage: result.message,
      );
    }
  }
  
  Future<void> disconnect() async {
    await _sshService.disconnect();
    state = const ConnectionState();
  }
}

// Providers
final sshServiceProvider = Provider<SSHService>((ref) => SSHService());

final lgServiceProvider = Provider<LGService>((ref) {
  final ssh = ref.watch(sshServiceProvider);
  return LGService(ssh);
});

final connectionProvider = StateNotifierProvider<ConnectionNotifier, ConnectionState>((ref) {
  final ssh = ref.watch(sshServiceProvider);
  return ConnectionNotifier(ssh);
});
```

---

## 📋 Template 5: Connection Screen UI

```dart
// lib/src/features/connection/screens/connection_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectionScreen extends ConsumerStatefulWidget {
  const ConnectionScreen({Key? key}) : super(key: key);
  
  @override
  ConsumerState<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends ConsumerState<ConnectionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _hostController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _usernameController = TextEditingController(text: 'lg');
  final _passwordController = TextEditingController();
  
  bool _obscurePassword = true;
  
  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  
  void _connect() {
    if (!_formKey.currentState!.validate()) return;
    
    final config = LGConfig(
      host: _hostController.text,
      username: _usernameController.text,
      password: _passwordController.text,
      port: int.parse(_portController.text),
    );
    
    ref.read(connectionProvider.notifier).connect(config);
  }
  
  @override
  Widget build(BuildContext context) {
    final connectionState = ref.watch(connectionProvider);
    
    // Listen to connection state changes
    ref.listen<ConnectionState>(connectionProvider, (previous, next) {
      if (next.isConnected && !next.isConnecting) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connected successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect to Liquid Galaxy'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Icon(Icons.computer, size: 64),
            const SizedBox(height: 24),
            TextFormField(
              controller: _hostController,
              decoration: const InputDecoration(
                labelText: 'Host IP',
                prefixIcon: Icon(Icons.dns),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter host IP';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _portController,
              decoration: const InputDecoration(
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _usernameController,
              decoration: const InputDecoration(
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock),
                border: const OutlineInputBorder(),
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: connectionState.isConnecting ? null : _connect,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: connectionState.isConnecting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('CONNECT', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 📋 Template 6: Storage Service

```dart
// lib/src/services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _configKey = 'lg_config';
  
  /// Save LG configuration
  Future<void> saveConfig(LGConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(config.toJson());
    await prefs.setString(_configKey, json);
  }
  
  /// Load LG configuration
  Future<LGConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_configKey);
    
    if (json == null) return null;
    
    try {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return LGConfig.fromJson(map);
    } catch (e) {
      return null;
    }
  }
  
  /// Clear saved configuration
  Future<void> clearConfig() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_configKey);
  }
  
  /// Save generic data
  Future<void> saveData(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(value);
    await prefs.setString(key, json);
  }
  
  /// Load generic data
  Future<dynamic> loadData(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(key);
    
    if (json == null) return null;
    
    try {
      return jsonDecode(json);
    } catch (e) {
      return null;
    }
  }
}
```

---

## 📋 Template 7: App Setup (main.dart)

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/app.dart';

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

// lib/src/app.dart
import 'package:flutter/material.dart';
import 'features/connection/screens/connection_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LG Controller',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const DashboardScreen(),
        '/connection': (context) => const ConnectionScreen(),
      },
    );
  }
}
```

---

## 📋 Template 8: pubspec.yaml Dependencies

```yaml
name: lg_controller
description: Flutter controller app for Liquid Galaxy
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # SSH connectivity
  dartssh2: ^3.0.0
  
  # State management
  flutter_riverpod: ^2.4.0
  
  # Storage
  shared_preferences: ^2.2.0
  
  # Utilities
  http: ^1.1.0
  path_provider: ^2.1.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
```

---

## 🎯 Quick Start Guide

1. **Copy templates** into your project structure
2. **Install dependencies** from pubspec.yaml template
3. **Set up providers** in main.dart
4. **Create connection screen** for SSH setup
5. **Build dashboard** with LG controls
6. **Test connection** thoroughly before deploying

## 📚 Usage Examples

### Example 1: Send a placemark
```dart
final lgService = ref.read(lgServiceProvider);
final kml = KMLBuilder.buildPlacemark(
  name: 'Eiffel Tower',
  latitude: 48.8584,
  longitude: 2.2945,
  description: 'Famous landmark',
);
await lgService.sendKML(KMLBuilder.wrapDocument(kml), 'eiffel');
```

### Example 2: Fly to location
```dart
final lgService = ref.read(lgServiceProvider);
await lgService.flyTo(
  latitude: 40.7128,
  longitude: -74.0060,
  range: 10000,
);
```

### Example 3: Start a tour
```dart
final tour = [
  TourPoint(latitude: 48.8584, longitude: 2.2945),
  TourPoint(latitude: 51.5074, longitude: -0.1278),
  TourPoint(latitude: 40.7128, longitude: -74.0060),
];
final kml = KMLBuilder.buildTour(name: 'World Tour', points: tour);
await lgService.sendKML(kml, 'tour');
```

---

All templates are production-ready and follow LG community best practices!
