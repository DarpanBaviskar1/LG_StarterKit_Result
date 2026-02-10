---
name: flutter-lg-training-data
description: Comprehensive training data, best practices, and patterns for building Flutter applications for Liquid Galaxy systems
---

# Flutter LG Training Data 🚀

## Purpose
This skill contains curated training data, best practices, and code patterns for building professional Flutter applications that integrate with Liquid Galaxy systems. All examples are based on open-source repositories from https://github.com/LiquidGalaxyLAB/.

## Core Principles

### 1. **SSH Communication Pattern**
All LG Flutter apps communicate with the Master machine via SSH. This is the primary interface.

**Good Behavior:**
```dart
// Use dartssh2 library
import 'package:dartssh2/dartssh2.dart';

class SSHService {
  SSHClient? _client;
  
  Future<bool> connect({
    required String host,
    required String username,
    required String password,
    int port = 22,
  }) async {
    try {
      _client = SSHClient(
        await SSHSocket.connect(host, port),
        username: username,
        onPasswordRequest: () => password,
      );
      return true;
    } catch (e) {
      debugPrint('SSH Connection Error: $e');
      return false;
    }
  }
  
  Future<String?> execute(String command) async {
    if (_client == null) return null;
    try {
      final result = await _client!.run(command);
      return utf8.decode(result);
    } catch (e) {
      debugPrint('SSH Execute Error: $e');
      return null;
    }
  }
}
```

**Bad Behavior:**
- ❌ Not checking if client is connected before executing commands
- ❌ Not handling SSH exceptions properly
- ❌ Hardcoding connection credentials in code

### 2. **KML Management Architecture**

**Good Behavior:**
```dart
class KMLBuilder {
  static String buildPlacemark({
    required String name,
    required double latitude,
    required double longitude,
    double altitude = 0,
    String? description,
  }) {
    return '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>$name</name>
    <Placemark>
      ${description != null ? '<description>$description</description>' : ''}
      <Point>
        <coordinates>$longitude,$latitude,$altitude</coordinates>
      </Point>
    </Placemark>
  </Document>
</kml>
''';
  }
  
  static String buildOrbit({
    required double latitude,
    required double longitude,
    required double altitude,
    required double range,
    double tilt = 60,
    double heading = 0,
  }) {
    return '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
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
  }
}
```

**Bad Behavior:**
- ❌ Concatenating KML strings inline in UI code
- ❌ Not escaping XML special characters
- ❌ Mixing KML generation with business logic

### 3. **Project Structure (Feature-First)**

**Good Behavior:**
```
lib/
├── src/
│   ├── features/
│   │   ├── connection/
│   │   │   ├── models/
│   │   │   │   └── connection_config.dart
│   │   │   ├── providers/
│   │   │   │   └── ssh_provider.dart
│   │   │   ├── screens/
│   │   │   │   └── connection_screen.dart
│   │   │   └── widgets/
│   │   │       └── connection_form.dart
│   │   ├── dashboard/
│   │   │   ├── providers/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   └── settings/
│   ├── services/
│   │   ├── ssh_service.dart
│   │   └── storage_service.dart
│   ├── utils/
│   │   ├── kml/
│   │   │   ├── kml_builder.dart
│   │   │   └── kml_validator.dart
│   │   └── helpers/
│   ├── models/
│   └── constants/
├── main.dart
└── app.dart
```

**Bad Behavior:**
- ❌ Organizing by type (views/, controllers/, models/)
- ❌ Putting everything in lib/ root
- ❌ No separation of concerns

### 4. **State Management with Riverpod**

**Good Behavior:**
```dart
// providers/ssh_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final sshServiceProvider = Provider<SSHService>((ref) => SSHService());

final connectionStateProvider = StateNotifierProvider<ConnectionNotifier, ConnectionState>(
  (ref) => ConnectionNotifier(ref.watch(sshServiceProvider)),
);

class ConnectionState {
  final bool isConnected;
  final String? errorMessage;
  final String? host;
  
  const ConnectionState({
    this.isConnected = false,
    this.errorMessage,
    this.host,
  });
  
  ConnectionState copyWith({
    bool? isConnected,
    String? errorMessage,
    String? host,
  }) {
    return ConnectionState(
      isConnected: isConnected ?? this.isConnected,
      errorMessage: errorMessage ?? this.errorMessage,
      host: host ?? this.host,
    );
  }
}

class ConnectionNotifier extends StateNotifier<ConnectionState> {
  final SSHService _sshService;
  
  ConnectionNotifier(this._sshService) : super(const ConnectionState());
  
  Future<void> connect({
    required String host,
    required String username,
    required String password,
  }) async {
    state = state.copyWith(errorMessage: null);
    
    final success = await _sshService.connect(
      host: host,
      username: username,
      password: password,
    );
    
    if (success) {
      state = state.copyWith(isConnected: true, host: host);
    } else {
      state = state.copyWith(
        isConnected: false,
        errorMessage: 'Failed to connect to $host',
      );
    }
  }
  
  Future<void> disconnect() async {
    await _sshService.disconnect();
    state = const ConnectionState();
  }
}
```

**Bad Behavior:**
- ❌ Using setState for global state
- ❌ Not separating business logic from UI
- ❌ Direct widget-to-service communication without state management

### 5. **Clean Slaves Pattern**

**Good Behavior:**
```dart
class LGService {
  final SSHService _sshService;
  
  LGService(this._sshService);
  
  Future<void> cleanSlaves() async {
    const commands = [
      'echo "\$(cat /tmp/query.txt)" > /var/www/html/kml/slave_\$SLAVE_ID.kml',
      'pkill -f chromium',
    ];
    
    for (final command in commands) {
      await _sshService.execute(command);
    }
  }
  
  Future<void> sendKML(String kmlContent, String filename) async {
    // Write KML to file
    final command = 'echo \'$kmlContent\' > /var/www/html/kml/$filename.kml';
    await _sshService.execute(command);
    
    // Send query to display
    final queryCommand = 'echo "http://lg1:81/$filename.kml" > /tmp/query.txt';
    await _sshService.execute(queryCommand);
  }
  
  Future<void> flyTo({
    required double latitude,
    required double longitude,
    double altitude = 1000,
    double range = 5000,
  }) async {
    final kml = KMLBuilder.buildOrbit(
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      range: range,
    );
    
    await sendKML(kml, 'orbit');
  }
}
```

**Bad Behavior:**
- ❌ Not cleaning screens before new content
- ❌ Hardcoding screen numbers without configuration
- ❌ Not wrapping commands in service layer

### 6. **Error Handling and User Feedback**

**Good Behavior:**
```dart
class DashboardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectionStateProvider);
    
    if (!connectionState.isConnected) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Not connected to Liquid Galaxy'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/connection');
                },
                child: Text('Connect'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: /* Your dashboard content */,
    );
  }
}
```

**Bad Behavior:**
- ❌ Silently failing when not connected
- ❌ Not showing loading states
- ❌ No error messages for failed operations

### 7. **Configuration Management**

**Good Behavior:**
```dart
// models/lg_config.dart
class LGConfig {
  final String host;
  final String username;
  final String password;
  final int port;
  final int screenCount;
  
  const LGConfig({
    required this.host,
    required this.username,
    required this.password,
    this.port = 22,
    this.screenCount = 3,
  });
  
  factory LGConfig.fromJson(Map<String, dynamic> json) {
    return LGConfig(
      host: json['host'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      port: json['port'] as int? ?? 22,
      screenCount: json['screenCount'] as int? ?? 3,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'host': host,
      'username': username,
      'password': password,
      'port': port,
      'screenCount': screenCount,
    };
  }
}

// services/storage_service.dart
class StorageService {
  static const _configKey = 'lg_config';
  
  Future<void> saveConfig(LGConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(config.toJson());
    await prefs.setString(_configKey, json);
  }
  
  Future<LGConfig?> loadConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_configKey);
    if (json == null) return null;
    
    final map = jsonDecode(json) as Map<String, dynamic>;
    return LGConfig.fromJson(map);
  }
}
```

**Bad Behavior:**
- ❌ Storing passwords in plain text without encryption
- ❌ Not persisting connection settings
- ❌ Hardcoding configuration values

## Training Data Sources

All examples and patterns are derived from these open-source repositories:

1. **LiquidGalaxyLAB GitHub**: https://github.com/LiquidGalaxyLAB/
   - Flutter apps for Liquid Galaxy
   - Real-world implementations
   - Community best practices

2. **Key Reference Projects**:
   - GSoC student projects
   - Production LG controller apps
   - Official examples and templates

## Common Mistakes to Avoid

### ❌ Anti-Patterns

1. **Not handling connection state globally**
   - Results in inconsistent UI states
   - Commands sent when not connected

2. **Inline KML string building**
   - Hard to maintain
   - Prone to syntax errors
   - No reusability

3. **No error handling**
   - Silent failures confuse users
   - No feedback on SSH errors

4. **Poor separation of concerns**
   - Business logic in widgets
   - SSH calls directly from UI
   - No testability

5. **Hardcoded values**
   - Screen counts
   - File paths
   - IP addresses

## Best Practices Checklist

✅ Use `dartssh2` for SSH communication
✅ Implement proper error handling
✅ Use Riverpod or BLoC for state management
✅ Feature-first folder structure
✅ Separate KML builders
✅ Persist connection settings
✅ Show connection status clearly
✅ Clean slaves before new content
✅ Use proper models and serialization
✅ Test SSH commands thoroughly
✅ Document KML formats used
✅ Handle disconnections gracefully

## Starter Template

For a complete starter template, refer to the flutter_app/ folder in this repository, which implements all these best practices.

## Resources

- Liquid Galaxy Official: https://www.liquidgalaxy.eu/
- GitHub Organization: https://github.com/LiquidGalaxyLAB/
- KML Reference: https://developers.google.com/kml/documentation/kmlreference
- dartssh2 Package: https://pub.dev/packages/dartssh2
- Riverpod Documentation: https://riverpod.dev/

---

**Remember**: Good LG Flutter apps are maintainable, testable, and provide clear feedback to users. Always think about error cases and connection states.
