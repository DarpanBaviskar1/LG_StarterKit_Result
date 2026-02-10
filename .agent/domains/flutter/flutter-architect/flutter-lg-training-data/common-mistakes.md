# Common Mistakes and Anti-Patterns

Learn from common mistakes in Flutter + Liquid Galaxy development.

---

## ⚠️ CRITICAL: Using execute() Instead of run() in Navigation/Fly Functions

### ❌ Mistake: Calling execute() for KML Upload and Tour Playback

**This causes KML files to fail silencing and tours to never play!**

### The Problem

When uploading KML or triggering tours in navigation functions, `execute()` returns immediately without waiting for command completion:

```dart
// ❌ WRONG - execute() doesn't wait for completion
Future<void> flyToMumbai() async {
  final kmlPath = '/var/www/html/kml/master.kml';
  final escapedKml = mumbaiTourKml.replaceAll('"', '\\"').replaceAll('\$', '\\\$');
  
  await _sshService.execute('echo "$escapedKml" > $kmlPath');  // Returns immediately!
  await Future.delayed(const Duration(seconds: 1));
  await _sshService.execute('echo "playtour=Mumbai" > /tmp/query.txt'); // May run before KML written!
  
  // Result: Race condition - Google Earth might not find the KML file yet
}
```

**Real-world symptom:** "Fly to Mumbai" button is clicked, the app says "Flying..." but nothing happens on the LG display.

### ✅ CORRECT: Using _sshService.client!.run() Directly

**This is the PRODUCTION PATTERN that works!**

```dart
// ✅ PRODUCTION PATTERN - Direct client call (matches power management)
Future<void> flyToMumbai() async {
  final kmlPath = '/var/www/html/kml/master.kml';
  final escapedKml = mumbaiTourKml.replaceAll('"', '\\"').replaceAll('\$', '\\\$');
  
  // Always use _sshService.client!.run() directly for navigation
  await _sshService.client!.run('echo "$escapedKml" > $kmlPath');
  await Future.delayed(const Duration(seconds: 1));
  await _sshService.client!.run('echo "playtour=Mumbai" > /tmp/query.txt');
  
  debugPrint('Flying to Mumbai');
  // Result: Works reliably, no silent failures
}
```

### Why _sshService.client!.run() Works

1. **Direct access** to the SSH client - no wrapper overhead
2. **Guaranteed waits** for full command execution before returning
3. **Matches power management pattern** (shutdown, reboot, relaunch)
4. **No UTF-8 decoding issues** - just pass through the command result
5. **Proven in production** - tested with shuttle/reboot/relaunch

### Key Difference

| Pattern | Works? | When to Use |
|---------|--------|------------|
| `_sshService.execute()` | ❌ No | Never for navigation |
| `_sshService.run()` | ⚠️ Sometimes | Only if you need output |
| `_sshService.client!.run()` | ✅ Yes | **Always for navigation/KML** |

**GOLDEN RULE:** For all KML operations (flying, tours, logos) use:
```dart
await _sshService.client!.run(command);
```

This applies to:
- **Navigation functions** (flyToMumbai, flyTo)
- **Logo operations** (sendLogo, clearLogos)
- **Any KML file write/update**

---

## ⚠️ CRITICAL: Sending Logos Uses execute() Instead of run()

### ❌ Mistake: LogoService Uses execute() for KML Upload

**This causes logos to fail uploading silently!**

### Bad Pattern:
```dart
// ❌ WRONG - execute() doesn't wait for file write
Future<bool> sendLogo(String imageUrl, int screen) async {
  final escapedKml = kml.replaceAll('"', '\\"').replaceAll('\$', '\\\$');
  
  // Race condition: File write may not complete
  await _sshService.execute('echo "$escapedKml" > /var/www/html/kml/slave_$screen.kml');
  await _forceRefreshSlave(screen, 'slave_$screen.kml');
  
  return true; // Returns before write completes!
}
```

**Symptoms:**
- "Send Logo" button shows success but logo doesn't appear on slave screens
- Silent failure, no error messages
- Clearing logos also fails

### ✅ CORRECT: Use _sshService.client!.run()

```dart
// ✅ CORRECT - Direct client call (matches power management)
Future<bool> sendLogo(String imageUrl, int screen) async {
  try {
    // Get direct client reference
    final client = _sshService.client;
    if (client == null || client.isClosed) {
      debugPrint('SendLogo failed: SSH not connected');
      return false;
    }

    final kmlPath = '/var/www/html/kml/slave_$screen.kml';
    final escapedKml = kml.replaceAll('"', '\\"').replaceAll('\$', '\\\$');
    
    // ALWAYS use client!.run() for KML file writes
    debugPrint('Sending logo to slave_$screen.kml');
    await client.run('echo "$escapedKml" > $kmlPath');
    
    // Now safe: file is guaranteed written
    await _forceRefreshSlave(screen, 'slave_$screen.kml');
    
    debugPrint('Logo sent successfully to screen $screen');
    return true;
  } catch (e) {
    debugPrint('SendLogo failed: $e');
    return false;
  }
}
```

### Why This Pattern Works

| Operation | Method | Why |
|-----------|--------|-----|
| KML file write | `_sshService.client!.run()` | Must wait for file to be written |
| KML file read | `_sshService.client!.run()` | Must wait for file to be readable |
| Refresh trigger | `_sshService.client!.run()` | Must wait for touch/sed to complete |
| Power mgmt | `_sshService.client!.run()` | Must wait for system to respond |

**ALL KML operations must use `_sshService.client!.run()`** because each step depends on the previous step completing.

---

## ⚠️ CRITICAL: KML File Path (master.kml vs master_1.kml)

### ❌ Mistake: Using master_1.kml Instead of master.kml

**This breaks KML injection and tour playback!**

### Bad (old pattern):
```dart
// ❌ WRONG - master_1.kml is NOT the standard injection point
await sendKml(kml, 'master_1.kml');
await execute('echo "playtour=MyTour" > /tmp/query.txt'); // Won't work!

// Clearing:
await sendKml(blankKml, 'master_1.kml'); // Won't clear properly
```

**Result:** KML may not load, tours won't play, clearing doesn't work

### Good (production standard):
```dart
// ✅ CORRECT - Always use master.kml
await sendKml(kml, 'master.kml'); // ← Standard injection point
await execute('echo "playtour=MyTour" > /tmp/query.txt'); // ← Works!

// Clearing:
await sendKml(blankKml, 'master.kml'); // ← Clears properly
```

**Key Point:** `master.kml` is the default injection point that Google Earth monitors. Use it for:
- Flying to locations
- Running tours
- Clearing displays
- All interactive KML content

---

## ⚠️ CRITICAL: Configuring Dio Timeouts for External APIs

### ❌ Mistake: No Timeout Configuration on Dio HTTP Client

**This causes connection timeouts and unreliable API calls!**

### Bad (No Timeout):
```dart
// ❌ WRONG - No timeout configuration, Dio uses defaults which may be too short
class ISSService {
  final Dio _dio = Dio(); // Default timeouts may timeout too quickly
  
  Future<void> trackISS() async {
    try {
      final response = await _dio.get('http://api.open-notify.org/iss-now.json');
      // May fail with "connection timeout" on slow networks
    } catch (e) {
      debugPrint('ISS Tracking failed: $e');
    }
  }
}
```

**Symptoms:**
- "DioException [connection timeout]: The request connection took longer"
- "HttpException: Connection reset by peer"
- Random failures when network is slow
- No retry mechanism

### Good (With Timeouts and Retries):
```dart
// ✅ CORRECT - Configure timeouts and add retry logic
class ISSService {
  final NavigationService _navigationService;
  late final Dio _dio;

  ISSService(this._navigationService) {
    // Configure Dio with proper timeouts (10 seconds each)
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ));
  }

  Future<void> trackISS() async {
    try {
      debugPrint('Fetching ISS Location...');
      
      // Retry logic for network failures
      int retries = 3;
      Response? response;
      
      for (int i = 0; i < retries; i++) {
        try {
          response = await _dio.get('http://api.open-notify.org/iss-now.json');
          break; // Success, exit retry loop
        } catch (e) {
          debugPrint('ISS API Attempt ${i + 1} failed: $e');
          if (i < retries - 1) {
            await Future.delayed(const Duration(seconds: 2)); // Wait before retry
          } else {
            rethrow;
          }
        }
      }
      
      if (response != null && response.statusCode == 200) {
        final data = response.data;
        if (data['message'] == 'success') {
          final position = data['iss_position'];
          final lat = double.parse(position['latitude']);
          final lng = double.parse(position['longitude']);
          
          debugPrint('ISS Found at $lat, $lng. Flying...');
          await _navigationService.flyTo(lat, lng, 500000);
        }
      }
    } catch (e) {
      debugPrint('ISS Tracking failed: $e');
    }
  }
}
```

### Key Points for External APIs

| Setting | Why It Matters |
|---------|----------------|
| **connectTimeout** | Time to establish connection (default may be too short) |
| **receiveTimeout** | Time to receive response (external APIs can be slow) |
| **sendTimeout** | Time to send request (usually fast) |
| **Retry Logic** | Networks are unreliable, always retry failed requests |
| **Backoff Delay** | Wait 2-3 seconds between retries to avoid hammering server |

**Rules for External APIs:**
- ✅ Always set explicit timeouts (10+ seconds for reliability)
- ✅ Always add retry logic (3-5 attempts)
- ✅ Always add delay between retries (exponential backoff preferred)
- ✅ Always handle all DioException types
- ✅ Show user feedback ("Retrying...")

---

## ⚠️ CRITICAL: Riverpod Version Mismatch

### ❌ Mistake: Using Riverpod 2.x StateNotifier Pattern with Riverpod 3.x

**This is the #1 cause of compilation errors in Riverpod 3.x projects!**

### Bad (Riverpod 2.x pattern with 3.x):
```dart
// ❌ WRONG - This worked in Riverpod 2.x but FAILS in 3.x
class ConnectionNotifier extends StateNotifier<ConnectionState> {
  final SSHService _ssh;

  ConnectionNotifier(this._ssh) : super(const ConnectionState());
  
  void connect() {
    state = state.copyWith(isConnected: true);
  }
}

final connectionProvider = StateNotifierProvider<ConnectionNotifier, ConnectionState>((ref) {
  final ssh = ref.watch(sshServiceProvider);
  return ConnectionNotifier(ssh);
});
```

**Errors you'll see:**
- "Classes can only extend other classes" (StateNotifier)
- "Too many positional arguments: 0 expected, but 1 found" (super call)
- "Undefined name 'state'" (not inheriting properly)
- "StateNotifierProvider isn't defined" (wrong provider type)

### Good (Riverpod 3.x pattern):
```dart
// ✅ CORRECT - Use Notifier instead of StateNotifier in Riverpod 3.x
class ConnectionNotifier extends Notifier<ConnectionState> {
  late final SSHService _ssh;

  @override
  ConnectionState build() {
    _ssh = ref.watch(sshServiceProvider);
    return const ConnectionState();
  }
  
  void connect() {
    state = state.copyWith(isConnected: true);
  }
}

final connectionProvider = NotifierProvider<ConnectionNotifier, ConnectionState>(() {
  return ConnectionNotifier();
});
```

**Key Differences:**
1. **Class**: `Notifier` instead of `StateNotifier`
2. **Constructor**: No constructor parameters, use `build()` method instead
3. **Provider**: `NotifierProvider` instead of `StateNotifierProvider`
4. **Factory**: `() => ConnectionNotifier()` instead of `(ref) => ConnectionNotifier(ref.watch(...))`
5. **Dependencies**: Access ref in `build()` method, not constructor

**Why**: Riverpod 3.x redesigned the API. StateNotifier is deprecated. Always check your pubspec.yaml version:
- `flutter_riverpod: ^2.x.x` → Use StateNotifier
- `flutter_riverpod: ^3.x.x` → Use Notifier

---

## ⚠️ CRITICAL: Using `ref` After Widget Disposal

### ❌ Mistake: Calling `ref.read()` in `dispose()`

**This throws `StateError: Using "ref" when a widget is about to or has been unmounted is unsafe.`**

### Bad:
```dart
@override
void dispose() {
  ref.read(issServiceProvider).stopTracking();
  super.dispose();
}
```

### ✅ Correct: Cache the dependency in `initState`
```dart
late final ISSService _issService;

@override
void initState() {
  super.initState();
  _issService = ref.read(issServiceProvider);
}

@override
void dispose() {
  _issService.stopTracking();
  super.dispose();
}
```

**Why**: `ref` depends on `BuildContext`. After unmount, `BuildContext` is unsafe, and Riverpod throws.

---

## ✅ BEST PRACTICE: Smart Tour Builder Feature

### What Was Added
1. **Tour Models** - Waypoint and Tour data classes
2. **Gemini AI Service** - Generate tours from text prompts
3. **Tour Service** - CRUD + KML export for Liquid Galaxy
4. **Map Editor** - flutter_map + interactive waypoint placement
5. **Dashboard Integration** - "Smart Tours" card + navigation

### Architecture Pattern
```
feature/
├── domain/models/          # Pure data classes
├── data/                   # Services + Providers
│   ├── *_service.dart      # Business logic
│   └── *_provider.dart     # Riverpod providers
└── presentation/           # UI Screens & Widgets
```

### Key Integration Points
- **Selection Policy**: Used flutter_map (not google_maps_flutter) for free OSM tiles
- **AI Provider**: Gemini Free API for tour generation
- **State Management**: Riverpod + SharedPreferences (no conflicts)
- **Navigation**: Dashboard → ToursScreen → TourBuilderScreen
- **Data Persistence**: Async providers with SharedPreferences

### No Breaking Changes
- ✅ Separate feature folder (isolated)
- ✅ New Riverpod providers (no overwrites)
- ✅ Dashboard extended (not modified)
- ✅ Same injection patterns as ISS/Settings

### API Key Setup Required
Before running:
```dart
// tour_provider.dart line 11
const apiKey = 'YOUR_GEMINI_API_KEY_HERE';
```
Get from: https://ai.google.dev

---

## ⚠️ CRITICAL: Using execute() Instead of run() for SSH Commands

### ❌ Mistake: Using execute() for Power Management Commands

**This prevents shutdown, reboot, and relaunch from actually executing!**

### Bad (commands don't execute):
```dart
// ❌ WRONG - execute() returns SSHSession but doesn't wait for completion
Future<bool> shutdown(int rigs, String password) async {
  try {
    for (int i = 1; i <= rigs; i++) {
      await execute('sshpass -p "$password" ssh -t lg$i "echo $password | sudo -S poweroff"');
    }
    return true;
  } catch (e) {
    return false;
  }
}
```

**Result:** Commands appear to run but nothing happens. The SSH session is created but the command doesn't actually execute.

### Good (commands execute properly):
```dart
// ✅ CORRECT - run() actually executes the command and waits for completion
Future<bool> shutdown(int rigs, String password) async {
  try {
    for (int i = 1; i <= rigs; i++) {
      await run('sshpass -p "$password" ssh -t lg$i "echo $password | sudo -S poweroff"');
    }
    return true;
  } catch (e) {
    debugPrint('Shutdown failed: $e');
    return false;
  }
}
```

**Key Differences:**
- **`execute()`** - Returns `SSHSession?` for interactive sessions or reading output. Doesn't wait for command completion.
- **`run()`** - Actually executes the command, waits for it to complete, and returns the result.

**When to use each:**
- Use `execute()` when you need to read command output or manage an interactive session
- Use `run()` for fire-and-forget commands or when you need the command to fully execute

**Applies to:**
- Shutdown commands
- Reboot commands  
- Relaunch commands
- Any system administration command
- Commands that modify system state

**Real-world impact:** This bug caused all power management buttons (shutdown/reboot/relaunch) to silently fail in production!

---

## ⚠️ CRITICAL: Using const with Password Interpolation in Scripts

### ❌ Mistake: Declaring Script as const When It Needs Runtime Values

**This prevents password from being passed to sudo, causing relaunch to fail!**

### Bad (password doesn't interpolate):
```dart
// ❌ WRONG - const prevents $_password interpolation
Future<bool> relaunch() async {
  const relaunchScript = """
    if [[ \\\$(service \\\$SERVICE status) =~ 'stop' ]]; then
      (echo \$password; sleep 1) | sudo -S service \\\${SERVICE} start
    fi
  """;
  
  for (int i = 1; i <= _rigs; i++) {
    final command = 'sshpass -p "$_password" ssh lg$i "$relaunchScript"';
    await _client!.run(command); // Fails - no $password variable exists on remote
  }
}
```

**Result:** Relaunch fails because `\$password` is treated as a literal shell variable that doesn't exist, instead of the Dart variable `$_password` being interpolated.

### Good (password interpolates correctly):
```dart
// ✅ CORRECT - final allows $_password interpolation
Future<bool> relaunch() async {
  final relaunchScript = """
    if [[ \\\$(service \\\$SERVICE status) =~ 'stop' ]]; then
      (echo $_password; sleep 1) | sudo -S service \\\${SERVICE} start
    fi
  """;
  
  for (int i = 1; i <= _rigs; i++) {
    final command = 'sshpass -p "$_password" ssh lg$i "$relaunchScript"';
    await _client!.run(command); // Works - password value is in script
  }
}
```

**Key Rules:**
- **Use `const`** when script has NO Dart variables (pure shell script)
- **Use `final`** when script needs Dart variable interpolation (`$_password`, `$_rigs`, etc.)
- **`const`** = compile-time constant, no runtime values allowed
- **`final`** = runtime value, allows interpolation

**Real-world impact:** Shutdown and reboot worked, but relaunch failed silently because password wasn't being passed to sudo!

---

## ✅ BEST PRACTICE: Call SSHClient Methods Directly for Power Management

### The Problem with Wrapper Methods

When implementing power management, calling wrapper methods that add logging can interfere with command execution.

### Bad (using wrapper that may interfere):
```dart
// ❌ MAY FAIL - Wrapper adds decoding/logging overhead
Future<bool> shutdown() async {
  for (int i = 1; i <= _rigs; i++) {
    final result = await run(command); // Calls wrapper method
    if (result == null) return false; // May fail unnecessarily
  }
}
```

### Good (call client directly):
```dart
// ✅ CORRECT - Direct call to SSHClient.run() as in SKILL.md
Future<bool> shutdown() async {
  for (int i = 1; i <= _rigs; i++) {
    await _client!.run(command); // Direct call, no wrapper overhead
  }
  return true;
}
```

**Why Direct Calls Work Better:**
1. No extra UTF-8 decoding overhead
2. No null checking on results
3. Matches reference implementation exactly
4. Simpler error handling - catch block handles all failures

**Pattern:**
- Use wrapper `run()` method when you need output/logging
- Use `_client!.run()` directly for fire-and-forget commands like power management

---

## ❌ Mistake 2: Using const with String Interpolation

### Bad:
```dart
const String password = "mypass123";
const relaunchScript = """
  echo $password | sudo -S service lg start
"""; // ❌ ERROR: Const strings cannot use variables
```

**Error**: "Const variables cannot reference non-const values"

### Good:
```dart
const String password = "mypass123";
final relaunchScript = """
  echo $password | sudo -S service lg start
"""; // ✅ CORRECT: Use 'final' for strings with interpolation
```

**Why**: `const` requires compile-time constants. Variable interpolation happens at runtime, so use `final` instead.

---

## ❌ Mistake 3: Not Checking Connection State

### Bad:
```dart
class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        // Directly calling without checking connection
        SSHManager().execute('echo "test"');
      },
      child: Text('Send Command'),
    );
  }
}
```

### Good:
```dart
class DashboardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectionProvider);
    
    return ElevatedButton(
      onPressed: connectionState.isConnected 
          ? () async {
              final result = await ref.read(lgServiceProvider).execute('echo "test"');
              if (result.isFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result.message)),
                );
              }
            }
          : null, // Disabled when not connected
      child: Text('Send Command'),
    );
  }
}
```

**Why**: Always verify connection status before executing commands to prevent silent failures and provide better UX.

---

## ❌ Mistake 2: Inline KML String Building

### Bad:
```dart
void sendTour() async {
  String kml = '<?xml version="1.0"?>\n';
  kml += '<kml xmlns="http://www.opengis.net/kml/2.2">\n';
  kml += '<Document>\n';
  kml += '<Placemark>\n';
  kml += '<name>' + placeName + '</name>\n';
  kml += '<Point>\n';
  kml += '<coordinates>' + lon.toString() + ',' + lat.toString() + '</coordinates>\n';
  kml += '</Point>\n';
  kml += '</Placemark>\n';
  kml += '</Document>\n';
  kml += '</kml>';
  
  await ssh.sendKML(kml);
}
```

### Good:
```dart
class KMLBuilder {
  static String buildPlacemark({
    required String name,
    required double latitude,
    required double longitude,
  }) {
    return '''
<Placemark>
  <name>${_escapeXml(name)}</name>
  <Point>
    <coordinates>$longitude,$latitude,0</coordinates>
  </Point>
</Placemark>
''';
  }
  
  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;');
  }
}

void sendTour() async {
  final kml = KMLBuilder.wrapDocument(
    KMLBuilder.buildPlacemark(
      name: placeName,
      latitude: lat,
      longitude: lon,
    ),
  );
  
  await lgService.sendKML(kml, 'tour');
}
```

**Why**: Modular KML building is maintainable, testable, and prevents XML injection vulnerabilities.

---

## ❌ Mistake 3: No Error Handling

### Bad:
```dart
Future<void> connect(String host, String password) async {
  final socket = await SSHSocket.connect(host, 22);
  _client = SSHClient(socket, username: 'lg', onPasswordRequest: () => password);
  print('Connected');
}
```

### Good:
```dart
Future<SSHResult> connect({
  required String host,
  required String password,
  int port = 22,
}) async {
  try {
    final socket = await SSHSocket.connect(host, port)
        .timeout(Duration(seconds: 5));
    
    _client = SSHClient(
      socket,
      username: 'lg',
      onPasswordRequest: () => password,
    );
    
    // Test connection
    await _client!.run('echo "test"');
    
    return SSHResult.success('Connected successfully');
  } on TimeoutException {
    return SSHResult.failure('Connection timed out');
  } on SocketException catch (e) {
    return SSHResult.failure('Network error: ${e.message}');
  } catch (e) {
    return SSHResult.failure('Connection failed: $e');
  }
}
```

**Why**: Proper error handling provides meaningful feedback and prevents app crashes.

---

## ❌ Mistake 4: Hardcoded Configuration

### Bad:
```dart
class SSHService {
  final String host = '192.168.1.100';
  final String username = 'lg';
  final String password = 'lg';
  final int screenCount = 3;
  
  // ...
}
```

### Good:
```dart
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
      host: json['host'],
      username: json['username'],
      password: json['password'],
      port: json['port'] ?? 22,
      screenCount: json['screenCount'] ?? 3,
    );
  }
}

// Use storage service to persist
final storageService = StorageService();
final config = await storageService.loadConfig();
```

**Why**: Configuration should be user-customizable and persisted for different LG setups.

---

## ❌ Mistake 5: Not Escaping Shell Commands

### Bad:
```dart
Future<void> sendKML(String kml) async {
  final command = "echo '$kml' > /var/www/html/kml/file.kml";
  await ssh.execute(command);
}
```

### Good:
```dart
Future<SSHResult> sendKML(String kml, String filename) async {
  // Escape single quotes for shell
  final escaped = kml.replaceAll("'", "'\\''");
  
  final command = "echo '$escaped' > /var/www/html/kml/$filename.kml";
  return await ssh.execute(command);
}
```

**Why**: Prevents shell injection and handles special characters in KML content.

---

## ❌ Mistake 6: Poor State Management

### Bad:
```dart
class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool isConnected = false;
  
  void checkConnection() async {
    // Check from multiple places
    final ssh = SSHManager();
    setState(() {
      isConnected = ssh.isConnected;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(isConnected ? 'Connected' : 'Disconnected'),
        // ...
      ],
    );
  }
}
```

### Good:
```dart
final connectionProvider = StateNotifierProvider<ConnectionNotifier, ConnectionState>(
  (ref) => ConnectionNotifier(ref.watch(sshServiceProvider)),
);

class DashboardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectionProvider);
    
    return Column(
      children: [
        Text(connectionState.isConnected ? 'Connected' : 'Disconnected'),
        // All widgets automatically update when connection state changes
      ],
    );
  }
}
```

**Why**: Centralized state management prevents inconsistencies and simplifies UI updates.

---

## ❌ Mistake 7: Blocking UI Thread

### Bad:
```dart
void sendMultipleCommands() {
  for (int i = 0; i < 100; i++) {
    ssh.execute('echo "$i"'); // Blocking calls
  }
}
```

### Good:
```dart
Future<void> sendMultipleCommands() async {
  final commands = List.generate(100, (i) => 'echo "$i"');
  
  for (final command in commands) {
    await ssh.execute(command);
    // UI remains responsive
  }
}

// Or with progress indicator:
Future<void> sendMultipleCommandsWithProgress(
  void Function(double) onProgress,
) async {
  final commands = List.generate(100, (i) => 'echo "$i"');
  
  for (int i = 0; i < commands.length; i++) {
    await ssh.execute(commands[i]);
    onProgress((i + 1) / commands.length);
  }
}
```

**Why**: Async operations prevent UI freezing and allow progress feedback.

---

## ❌ Mistake 8: Not Cleaning Slaves

### Bad:
```dart
Future<void> showNewContent() async {
  final kml = buildKML();
  await lgService.sendKML(kml, 'content');
  // Old content remains on slave screens
}
```

### Good:
```dart
Future<void> showNewContent() async {
  // Clean old content first
  await lgService.cleanSlaves();
  
  // Then send new content
  final kml = buildKML();
  await lgService.sendKML(kml, 'content');
}
```

**Why**: Prevents overlay of old and new content on slave screens.

---

## ❌ Mistake 9: No Timeout Handling

### Bad:
```dart
Future<String> execute(String command) async {
  final result = await _client!.run(command);
  return utf8.decode(result);
}
```

### Good:
```dart
Future<SSHResult> execute(
  String command, {
  Duration timeout = const Duration(seconds: 10),
}) async {
  try {
    final result = await _client!.run(command).timeout(timeout);
    return SSHResult.success(utf8.decode(result));
  } on TimeoutException {
    return SSHResult.failure('Command timed out after ${timeout.inSeconds}s');
  } catch (e) {
    return SSHResult.failure('Execution failed: $e');
  }
}
```

**Why**: Prevents indefinite hangs on slow or failed commands.

---

## ❌ Mistake 10: Poor File Organization

### Bad:
```
lib/
├── main.dart
├── ssh.dart
├── kml.dart
├── screen1.dart
├── screen2.dart
├── screen3.dart
├── utils.dart
└── helpers.dart
```

### Good:
```
lib/
├── main.dart
├── app.dart
└── src/
    ├── features/
    │   ├── connection/
    │   │   ├── models/
    │   │   ├── providers/
    │   │   ├── screens/
    │   │   └── widgets/
    │   ├── dashboard/
    │   └── settings/
    ├── services/
    │   ├── ssh_service.dart
    │   └── lg_service.dart
    ├── utils/
    │   └── kml/
    └── constants/
```

**Why**: Feature-first organization scales better and groups related code.

---

## ❌ Mistake 11: Ignoring Password Security

### Bad:
```dart
class StorageService {
  Future<void> savePassword(String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('password', password);
  }
}
```

### Good:
```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final _secureStorage = FlutterSecureStorage();
  
  Future<void> savePassword(String password) async {
    await _secureStorage.write(key: 'password', value: password);
  }
  
  Future<String?> loadPassword() async {
    return await _secureStorage.read(key: 'password');
  }
}
```

**Why**: Secure storage encrypts sensitive data like passwords.

---

## ❌ Mistake 12: Not Validating User Input

### Bad:
```dart
TextFormField(
  controller: _hostController,
  decoration: InputDecoration(labelText: 'Host IP'),
)
```

### Good:
```dart
TextFormField(
  controller: _hostController,
  decoration: InputDecoration(labelText: 'Host IP'),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Please enter host IP';
    }
    
    // Basic IP validation
    final ipPattern = RegExp(
      r'^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$',
    );
    
    if (!ipPattern.hasMatch(value)) {
      return 'Invalid IP format';
    }
    
    final parts = value.split('.');
    for (final part in parts) {
      final num = int.parse(part);
      if (num < 0 || num > 255) {
        return 'IP octets must be 0-255';
      }
    }
    
    return null;
  },
)
```

**Why**: Validates input before attempting connection, preventing common errors.

---

## ❌ Mistake 13: Not Providing User Feedback

### Bad:
```dart
ElevatedButton(
  onPressed: () async {
    await lgService.flyTo(lat: 10, lon: 20);
  },
  child: Text('Fly To'),
)
```

### Good:
```dart
ElevatedButton(
  onPressed: () async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Flying to location...')),
    );
    
    final result = await lgService.flyTo(lat: 10, lon: 20);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.isSuccess 
              ? 'Navigation complete' 
              : 'Navigation failed: ${result.message}',
        ),
        backgroundColor: result.isSuccess ? Colors.green : Colors.red,
      ),
    );
  },
  child: Text('Fly To'),
)
```

**Why**: Users need feedback on long-running operations.

---

## ❌ Mistake 14: Memory Leaks with Controllers

### Bad:
```dart
class ConnectionScreen extends StatefulWidget {
  @override
  _ConnectionScreenState createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _controller = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return TextField(controller: _controller);
  }
  // No dispose!
}
```

### Good:
```dart
class ConnectionScreen extends StatefulWidget {
  @override
  _ConnectionScreenState createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final _controller = TextEditingController();
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return TextField(controller: _controller);
  }
}
```

**Why**: Prevents memory leaks by properly disposing controllers.

---

## ❌ Mistake 15: Not Testing SSH Before Use

### Bad:
```dart
void initState() {
  super.initState();
  // Assume connection works
  loadData();
}
```

### Good:
```dart
void initState() {
  super.initState();
  _checkConnection();
}

Future<void> _checkConnection() async {
  final connectionState = ref.read(connectionProvider);
  
  if (!connectionState.isConnected) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushNamed(context, '/connection');
    });
  } else {
    loadData();
  }
}
```

**Why**: Ensures connection is established before attempting operations.

---

## 📋 Best Practices Summary

### ✅ DO:
- Check connection state before operations
- Use modular KML builders
- Handle all error cases
- Provide user feedback
- Use proper state management
- Escape shell commands
- Set timeouts on operations
- Dispose controllers properly
- Validate user input
- Use secure storage for passwords
- Clean slaves before new content
- Organize code by feature

### ❌ DON'T:
- Hardcode configuration values
- Build KML strings inline
- Ignore error handling
- Block the UI thread
- Skip connection checks
- Store passwords in plain text
- Mix business logic with UI
- Forget to clean up resources
- Leave operations without timeouts
- Use global mutable state

---

## 🎯 Quick Checklist

Before submitting your Flutter LG app:

- [ ] All SSH operations have error handling
- [ ] Connection state is managed globally
- [ ] KML generation is modular and testable
- [ ] User inputs are validated
- [ ] Passwords use secure storage
- [ ] All controllers/resources are disposed
- [ ] Operations have appropriate timeouts
- [ ] User receives feedback on actions
- [ ] Code is organized by feature
- [ ] No hardcoded configuration values
- [ ] Slave screens are cleaned properly
- [ ] App handles disconnections gracefully

---

Learn from these mistakes to build robust, production-ready Flutter apps for Liquid Galaxy!
