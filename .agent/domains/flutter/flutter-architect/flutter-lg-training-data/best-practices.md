# Flutter + Liquid Galaxy Best Practices

## 📚 Table of Contents
1. [Architecture Patterns](#architecture-patterns)
2. [SSH Communication](#ssh-communication)
3. [KML Generation](#kml-generation)
4. [State Management](#state-management)
5. [UI/UX Guidelines](#uiux-guidelines)
6. [Testing Strategies](#testing-strategies)
7. [Performance Optimization](#performance-optimization)

---

## Architecture Patterns

### Feature-First Architecture

**Why**: Scales better than layer-first. Related code stays together.

```
lib/
├── src/
│   ├── features/
│   │   ├── connection/
│   │   │   ├── models/
│   │   │   ├── providers/
│   │   │   ├── screens/
│   │   │   ├── services/
│   │   │   └── widgets/
│   │   ├── tours/
│   │   ├── pois/
│   │   └── settings/
│   ├── shared/
│   │   ├── services/
│   │   │   ├── ssh_service.dart
│   │   │   └── lg_service.dart
│   │   ├── utils/
│   │   │   └── kml/
│   │   ├── models/
│   │   └── widgets/
│   └── constants/
│       ├── lg_constants.dart
│       └── app_constants.dart
├── main.dart
└── app.dart
```

### Dependency Injection

**Use Riverpod Providers:**

```dart
// providers/service_providers.dart
final sshServiceProvider = Provider<SSHService>((ref) {
  return SSHService();
});

final lgServiceProvider = Provider<LGService>((ref) {
  final sshService = ref.watch(sshServiceProvider);
  return LGService(sshService);
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
```

### Service Layer Pattern

**Always use services to encapsulate business logic:**

```dart
// services/lg_service.dart
class LGService {
  final SSHService _ssh;
  
  LGService(this._ssh);
  
  Future<Result<void>> relaunchLG() async {
    try {
      await _ssh.execute('lg-relaunch');
      return Result.success();
    } catch (e) {
      return Result.failure('Failed to relaunch: $e');
    }
  }
  
  Future<Result<void>> setRefresh() async {
    try {
      await _ssh.execute('lg-set-refresh');
      return Result.success();
    } catch (e) {
      return Result.failure('Failed to set refresh: $e');
    }
  }
  
  Future<Result<int>> getScreenCount() async {
    try {
      final result = await _ssh.execute('cat /lg/personavars.txt | grep SCREEN_NUM');
      final count = int.parse(result?.split('=')[1].trim() ?? '3');
      return Result.success(count);
    } catch (e) {
      return Result.failure('Failed to get screen count: $e');
    }
  }
}
```

---

## SSH Communication

### Connection Management

**Always use a connection manager:**

```dart
class SSHConnectionManager {
  SSHClient? _client;
  bool _isConnected = false;
  
  bool get isConnected => _isConnected;
  
  Future<Result<void>> connect(LGConfig config) async {
    if (_isConnected) {
      await disconnect();
    }
    
    try {
      final socket = await SSHSocket.connect(
        config.host,
        config.port,
        timeout: Duration(seconds: 5),
      );
      
      _client = SSHClient(
        socket,
        username: config.username,
        onPasswordRequest: () => config.password,
      );
      
      // Test connection
      await _client!.run('echo "test"');
      _isConnected = true;
      
      return Result.success();
    } catch (e) {
      _isConnected = false;
      return Result.failure('Connection failed: $e');
    }
  }
  
  Future<void> disconnect() async {
    try {
      _client?.close();
      await _client?.done;
    } catch (e) {
      debugPrint('Error during disconnect: $e');
    } finally {
      _client = null;
      _isConnected = false;
    }
  }
  
  Future<Result<String>> execute(String command) async {
    if (!_isConnected || _client == null) {
      return Result.failure('Not connected to LG');
    }
    
    try {
      final result = await _client!.run(command);
      return Result.success(utf8.decode(result));
    } catch (e) {
      return Result.failure('Command execution failed: $e');
    }
  }
}
```

### Command Batching

**For multiple commands, batch them:**

```dart
Future<Result<void>> setupTour() async {
  final commands = [
    'echo "" > /var/www/html/kml/slave_2.kml',
    'echo "" > /var/www/html/kml/slave_3.kml',
    'echo "" > /var/www/html/kml/slave_4.kml',
  ];
  
  // Execute all commands in sequence
  for (final command in commands) {
    final result = await _ssh.execute(command);
    if (result.isFailure) {
      return result;
    }
  }
  
  return Result.success();
}
```

### Timeout Handling

**Always set timeouts:**

```dart
Future<Result<String>> executeWithTimeout(
  String command, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  try {
    final result = await execute(command).timeout(timeout);
    return result;
  } on TimeoutException {
    return Result.failure('Command timed out after ${timeout.inSeconds}s');
  }
}
```

---

## KML Generation

### Builder Pattern for KML

**Create specialized builders:**

```dart
class KMLPlacemarkBuilder {
  String _name = '';
  String? _description;
  double _latitude = 0;
  double _longitude = 0;
  double _altitude = 0;
  String? _iconUrl;
  
  KMLPlacemarkBuilder name(String name) {
    _name = name;
    return this;
  }
  
  KMLPlacemarkBuilder description(String? desc) {
    _description = desc;
    return this;
  }
  
  KMLPlacemarkBuilder coordinates(double lat, double lon, [double alt = 0]) {
    _latitude = lat;
    _longitude = lon;
    _altitude = alt;
    return this;
  }
  
  KMLPlacemarkBuilder icon(String? url) {
    _iconUrl = url;
    return this;
  }
  
  String build() {
    final buffer = StringBuffer();
    buffer.writeln('<Placemark>');
    buffer.writeln('  <name>${_escapeXml(_name)}</name>');
    
    if (_description != null) {
      buffer.writeln('  <description>${_escapeXml(_description!)}</description>');
    }
    
    if (_iconUrl != null) {
      buffer.writeln('  <Style>');
      buffer.writeln('    <IconStyle>');
      buffer.writeln('      <Icon>');
      buffer.writeln('        <href>$_iconUrl</href>');
      buffer.writeln('      </Icon>');
      buffer.writeln('    </IconStyle>');
      buffer.writeln('  </Style>');
    }
    
    buffer.writeln('  <Point>');
    buffer.writeln('    <coordinates>$_longitude,$_latitude,$_altitude</coordinates>');
    buffer.writeln('  </Point>');
    buffer.writeln('</Placemark>');
    
    return buffer.toString();
  }
  
  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

// Usage:
final placemark = KMLPlacemarkBuilder()
    .name('Eiffel Tower')
    .description('Famous landmark in Paris')
    .coordinates(48.8584, 2.2945, 300)
    .icon('http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png')
    .build();
```

### KML Document Wrapper

```dart
class KMLDocument {
  final List<String> _elements = [];
  String _documentName = 'Document';
  
  void setName(String name) {
    _documentName = name;
  }
  
  void addPlacemark(String placemark) {
    _elements.add(placemark);
  }
  
  void addLineString(String lineString) {
    _elements.add(lineString);
  }
  
  void addPolygon(String polygon) {
    _elements.add(polygon);
  }
  
  String build() {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2"');
    buffer.writeln('     xmlns:gx="http://www.google.com/kml/ext/2.2">');
    buffer.writeln('  <Document>');
    buffer.writeln('    <name>$_documentName</name>');
    
    for (final element in _elements) {
      buffer.writeln(element);
    }
    
    buffer.writeln('  </Document>');
    buffer.writeln('</kml>');
    
    return buffer.toString();
  }
}
```

### Tour Builder

```dart
class KMLTourBuilder {
  final List<String> _playlist = [];
  String _tourName = 'Tour';
  
  void setName(String name) {
    _tourName = name;
  }
  
  void flyTo({
    required double latitude,
    required double longitude,
    double altitude = 1000,
    double range = 5000,
    double tilt = 60,
    double heading = 0,
    double duration = 2.0,
  }) {
    _playlist.add('''
      <gx:FlyTo>
        <gx:duration>$duration</gx:duration>
        <gx:flyToMode>smooth</gx:flyToMode>
        <LookAt>
          <longitude>$longitude</longitude>
          <latitude>$latitude</latitude>
          <altitude>$altitude</altitude>
          <range>$range</range>
          <tilt>$tilt</tilt>
          <heading>$heading</heading>
          <gx:altitudeMode>relativeToGround</gx:altitudeMode>
        </LookAt>
      </gx:FlyTo>
    ''');
  }
  
  void wait(double seconds) {
    _playlist.add('''
      <gx:Wait>
        <gx:duration>$seconds</gx:duration>
      </gx:Wait>
    ''');
  }
  
  String build() {
    final buffer = StringBuffer();
    buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
    buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2"');
    buffer.writeln('     xmlns:gx="http://www.google.com/kml/ext/2.2">');
    buffer.writeln('  <Document>');
    buffer.writeln('    <name>$_tourName</name>');
    buffer.writeln('    <gx:Tour>');
    buffer.writeln('      <name>$_tourName</name>');
    buffer.writeln('      <gx:Playlist>');
    
    for (final item in _playlist) {
      buffer.writeln(item);
    }
    
    buffer.writeln('      </gx:Playlist>');
    buffer.writeln('    </gx:Tour>');
    buffer.writeln('  </Document>');
    buffer.writeln('</kml>');
    
    return buffer.toString();
  }
}
```

---

## State Management

### Connection State with Riverpod

```dart
@freezed
class ConnectionState with _$ConnectionState {
  const factory ConnectionState({
    @Default(false) bool isConnected,
    @Default(false) bool isConnecting,
    String? errorMessage,
    LGConfig? config,
  }) = _ConnectionState;
}

class ConnectionNotifier extends StateNotifier<ConnectionState> {
  final SSHConnectionManager _connectionManager;
  final StorageService _storage;
  
  ConnectionNotifier(this._connectionManager, this._storage) 
      : super(const ConnectionState()) {
    _loadSavedConfig();
  }
  
  Future<void> _loadSavedConfig() async {
    final config = await _storage.loadConfig();
    if (config != null) {
      state = state.copyWith(config: config);
    }
  }
  
  Future<void> connect(LGConfig config) async {
    state = state.copyWith(
      isConnecting: true,
      errorMessage: null,
    );
    
    final result = await _connectionManager.connect(config);
    
    if (result.isSuccess) {
      await _storage.saveConfig(config);
      state = state.copyWith(
        isConnected: true,
        isConnecting: false,
        config: config,
      );
    } else {
      state = state.copyWith(
        isConnected: false,
        isConnecting: false,
        errorMessage: result.error,
      );
    }
  }
  
  Future<void> disconnect() async {
    await _connectionManager.disconnect();
    state = state.copyWith(isConnected: false);
  }
  
  Future<void> reconnect() async {
    if (state.config != null) {
      await connect(state.config!);
    }
  }
}

// Provider
final connectionProvider = StateNotifierProvider<ConnectionNotifier, ConnectionState>((ref) {
  final connectionManager = ref.watch(sshConnectionManagerProvider);
  final storage = ref.watch(storageServiceProvider);
  return ConnectionNotifier(connectionManager, storage);
});
```

### Feature-Specific State

```dart
// For a tours feature
@freezed
class ToursState with _$ToursState {
  const factory ToursState({
    @Default([]) List<Tour> tours,
    Tour? currentTour,
    @Default(false) bool isPlaying,
    @Default(false) bool isLoading,
    String? errorMessage,
  }) = _ToursState;
}

class ToursNotifier extends StateNotifier<ToursState> {
  final LGService _lgService;
  
  ToursNotifier(this._lgService) : super(const ToursState());
  
  Future<void> loadTours() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    // Load from storage or API
    final tours = await _loadToursFromStorage();
    
    state = state.copyWith(
      tours: tours,
      isLoading: false,
    );
  }
  
  Future<void> playTour(Tour tour) async {
    state = state.copyWith(
      currentTour: tour,
      isPlaying: true,
      errorMessage: null,
    );
    
    final kml = KMLTourBuilder();
    kml.setName(tour.name);
    
    for (final point in tour.points) {
      kml.flyTo(
        latitude: point.latitude,
        longitude: point.longitude,
        duration: point.duration,
      );
      kml.wait(point.waitTime);
    }
    
    final result = await _lgService.sendKML(kml.build(), 'tour');
    
    if (result.isFailure) {
      state = state.copyWith(
        isPlaying: false,
        errorMessage: result.error,
      );
    }
  }
  
  void stopTour() {
    state = state.copyWith(
      isPlaying: false,
      currentTour: null,
    );
  }
}
```

---

## UI/UX Guidelines

### Connection Status Indicator

```dart
class ConnectionStatusBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectionProvider);
    
    if (connectionState.isConnecting) {
      return Container(
        padding: EdgeInsets.all(8),
        color: Colors.orange,
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(Colors.white),
              ),
            ),
            SizedBox(width: 8),
            Text('Connecting...', style: TextStyle(color: Colors.white)),
          ],
        ),
      );
    }
    
    if (!connectionState.isConnected) {
      return Container(
        padding: EdgeInsets.all(8),
        color: Colors.red,
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 16),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                connectionState.errorMessage ?? 'Not connected',
                style: TextStyle(color: Colors.white),
              ),
            ),
            TextButton(
              onPressed: () {
                ref.read(connectionProvider.notifier).reconnect();
              },
              child: Text('RETRY', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
    
    return Container(
      padding: EdgeInsets.all(8),
      color: Colors.green,
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'Connected to ${connectionState.config?.host}',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
```

### Loading States

```dart
class DashboardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectionProvider);
    final toursState = ref.watch(toursProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
      ),
      body: Column(
        children: [
          ConnectionStatusBar(),
          Expanded(
            child: _buildBody(connectionState, toursState),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBody(
    ConnectionState connectionState,
    ToursState toursState,
  ) {
    if (!connectionState.isConnected) {
      return _buildNotConnectedView();
    }
    
    if (toursState.isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (toursState.errorMessage != null) {
      return _buildErrorView(toursState.errorMessage!);
    }
    
    return _buildToursList(toursState.tours);
  }
  
  Widget _buildNotConnectedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Please connect to Liquid Galaxy'),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/connection'),
            child: Text('Connect'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorView(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center),
        ],
      ),
    );
  }
  
  Widget _buildToursList(List<Tour> tours) {
    if (tours.isEmpty) {
      return Center(child: Text('No tours available'));
    }
    
    return ListView.builder(
      itemCount: tours.length,
      itemBuilder: (context, index) {
        final tour = tours[index];
        return TourCard(tour: tour);
      },
    );
  }
}
```

---

## Testing Strategies

### Unit Tests for Services

```dart
void main() {
  group('KMLPlacemarkBuilder', () {
    test('builds basic placemark correctly', () {
      final kml = KMLPlacemarkBuilder()
          .name('Test')
          .coordinates(10.0, 20.0)
          .build();
      
      expect(kml, contains('<name>Test</name>'));
      expect(kml, contains('<coordinates>20.0,10.0,0.0</coordinates>'));
    });
    
    test('escapes XML special characters', () {
      final kml = KMLPlacemarkBuilder()
          .name('Test & <Special>')
          .coordinates(0, 0)
          .build();
      
      expect(kml, contains('Test &amp; &lt;Special&gt;'));
    });
  });
  
  group('SSHService', () {
    late MockSSHClient mockClient;
    late SSHService service;
    
    setUp(() {
      mockClient = MockSSHClient();
      service = SSHService(client: mockClient);
    });
    
    test('execute returns result on success', () async {
      when(mockClient.run(any))
          .thenAnswer((_) async => utf8.encode('success'));
      
      final result = await service.execute('test command');
      
      expect(result.isSuccess, true);
      expect(result.value, 'success');
    });
    
    test('execute returns failure on error', () async {
      when(mockClient.run(any)).thenThrow(Exception('SSH error'));
      
      final result = await service.execute('test command');
      
      expect(result.isFailure, true);
      expect(result.error, contains('SSH error'));
    });
  });
}
```

### Widget Tests

```dart
void main() {
  testWidgets('ConnectionStatusBar shows connecting state', (tester) async {
    final container = ProviderContainer(
      overrides: [
        connectionProvider.overrideWith(
          (ref) => FakeConnectionNotifier(
            const ConnectionState(isConnecting: true),
          ),
        ),
      ],
    );
    
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Scaffold(body: ConnectionStatusBar()),
        ),
      ),
    );
    
    expect(find.text('Connecting...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
```

---

## Performance Optimization

### Efficient KML Updates

```dart
class KMLCache {
  final Map<String, String> _cache = {};
  
  String? getCached(String key) => _cache[key];
  
  void cache(String key, String kml) {
    _cache[key] = kml;
  }
  
  void invalidate(String key) {
    _cache.remove(key);
  }
  
  void clear() {
    _cache.clear();
  }
}

// In service:
class LGService {
  final KMLCache _kmlCache = KMLCache();
  
  Future<void> sendCachedKML(String key, String Function() generator) async {
    String? kml = _kmlCache.getCached(key);
    
    if (kml == null) {
      kml = generator();
      _kmlCache.cache(key, kml);
    }
    
    await sendKML(kml, key);
  }
}
```

### Debouncing User Input

```dart
class SearchScreen extends ConsumerStatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  Timer? _debounce;
  
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(searchProvider.notifier).search(query);
    });
  }
  
  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search...',
      ),
    );
  }
}
```

---

## Summary

These best practices ensure:
- ✅ Maintainable code structure
- ✅ Proper error handling
- ✅ Good user experience
- ✅ Testable components
- ✅ Performance optimization
- ✅ Scalable architecture

Always refer to real-world examples from https://github.com/LiquidGalaxyLAB/ for additional patterns and implementations.
