---
title: Building a Connection Feature
folder: 02-implementation-guides
tags: [implementation, connection, riverpod, step-by-step]
related:
  - ../01-core-patterns/ssh-communication.md
  - ../01-core-patterns/state-management.md
  - ../03-code-templates/ssh-service.dart
  - ../03-code-templates/connection-provider.dart
difficulty: intermediate
time-to-read: 15 min
---

# Building a Connection Feature: Step-by-Step Guide 🔌

Let's build a complete connection feature from scratch.

## What We're Building

A feature that:
1. Allows users to input IP, username, password
2. Shows connection status
3. Handles errors gracefully
4. Manages SSH state globally with Riverpod

## Step 1: Create Models

**File: `lib/src/features/connection/models/connection_config.dart`**

```dart
import 'package:equatable/equatable.dart';

class ConnectionConfig extends Equatable {
  final String host;
  final String username;
  final String password;
  final int port;
  final Duration timeout;

  const ConnectionConfig({
    required this.host,
    required this.username,
    required this.password,
    this.port = 22,
    this.timeout = const Duration(seconds: 10),
  });

  @override
  List<Object?> get props => [host, username, password, port, timeout];
}
```

**File: `lib/src/features/connection/models/connection_state.dart`**

```dart
import 'package:equatable/equatable.dart';

class ConnectionState extends Equatable {
  final bool isConnected;
  final bool isConnecting;
  final String? errorMessage;
  final ConnectionConfig? config;

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
    ConnectionConfig? config,
  }) {
    return ConnectionState(
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      errorMessage: errorMessage,
      config: config ?? this.config,
    );
  }

  @override
  List<Object?> get props => [isConnected, isConnecting, errorMessage, config];
}
```

## Step 2: Create Services

**File: `lib/src/services/ssh_service.dart`**

```dart
import 'package:dartssh2/dartssh2.dart';

class SSHService {
  SSHClient? _client;
  
  bool get isConnected => _client != null;

  Future<bool> connect({
    required String host,
    required String username,
    required String password,
    int port = 22,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      debugPrint('🔌 Connecting to $host:$port...');
      
      _client = await SSHClient.connect(
        host,
        port: port,
        username: username,
        onPasswordRequest: () => password,
        timeout: timeout,
      );

      debugPrint('✅ Connected successfully');
      return true;
    } catch (e) {
      debugPrint('❌ Connection failed: $e');
      _client = null;
      return false;
    }
  }

  Future<bool> disconnect() async {
    try {
      await _client?.close();
      _client = null;
      debugPrint('✅ Disconnected');
      return true;
    } catch (e) {
      debugPrint('❌ Disconnect failed: $e');
      return false;
    }
  }

  Future<String> execute(String command) async {
    if (_client == null) {
      throw Exception('Not connected');
    }

    try {
      final result = await _client!.run(command);
      return result;
    } catch (e) {
      debugPrint('❌ Execution failed: $e');
      rethrow;
    }
  }
}
```

## Step 3: Create Providers

**File: `lib/src/features/connection/providers/ssh_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/ssh_service.dart';

final sshServiceProvider = Provider<SSHService>((ref) {
  return SSHService();
});
```

**File: `lib/src/features/connection/providers/connection_provider.dart`**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection_state.dart';
import '../models/connection_config.dart';
import './ssh_provider.dart';

class ConnectionNotifier extends StateNotifier<ConnectionState> {
  final SSHService _ssh;

  ConnectionNotifier(this._ssh) : super(const ConnectionState());

  Future<void> connect(ConnectionConfig config) async {
    state = state.copyWith(isConnecting: true, errorMessage: null);

    try {
      final success = await _ssh.connect(
        host: config.host,
        username: config.username,
        password: config.password,
        port: config.port,
        timeout: config.timeout,
      );

      if (success) {
        state = state.copyWith(
          isConnected: true,
          isConnecting: false,
          config: config,
        );
      } else {
        state = state.copyWith(
          isConnected: false,
          isConnecting: false,
          errorMessage: 'Connection failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isConnected: false,
        isConnecting: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> disconnect() async {
    await _ssh.disconnect();
    state = const ConnectionState();
  }

  Future<String> execute(String command) async {
    if (!state.isConnected) {
      throw Exception('Not connected');
    }
    return await _ssh.execute(command);
  }
}

final connectionProvider = StateNotifierProvider<
  ConnectionNotifier, ConnectionState>((ref) {
  final ssh = ref.watch(sshServiceProvider);
  return ConnectionNotifier(ssh);
});
```

## Step 4: Create Form Widget

**File: `lib/src/features/connection/widgets/connection_form.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection_config.dart';
import '../providers/connection_provider.dart';

class ConnectionForm extends ConsumerStatefulWidget {
  final VoidCallback? onConnected;

  const ConnectionForm({this.onConnected});

  @override
  ConsumerState<ConnectionForm> createState() => _ConnectionFormState();
}

class _ConnectionFormState extends ConsumerState<ConnectionForm> {
  late TextEditingController _hostController;
  late TextEditingController _userController;
  late TextEditingController _passController;

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController();
    _userController = TextEditingController(text: 'lg');
    _passController = TextEditingController(text: 'lg');
  }

  @override
  void dispose() {
    _hostController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectionProvider);

    return Column(
      spacing: 16,
      children: [
        TextField(
          controller: _hostController,
          decoration: InputDecoration(
            labelText: 'Liquid Galaxy IP',
            hintText: '192.168.1.100',
            prefixIcon: Icon(Icons.router),
          ),
          enabled: !state.isConnecting,
        ),
        TextField(
          controller: _userController,
          decoration: InputDecoration(
            labelText: 'Username',
            prefixIcon: Icon(Icons.person),
          ),
          enabled: !state.isConnecting,
        ),
        TextField(
          controller: _passController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            prefixIcon: Icon(Icons.lock),
          ),
          enabled: !state.isConnecting,
        ),
        ElevatedButton(
          onPressed: state.isConnecting
              ? null
              : () async {
                  final config = ConnectionConfig(
                    host: _hostController.text,
                    username: _userController.text,
                    password: _passController.text,
                  );

                  await ref
                      .read(connectionProvider.notifier)
                      .connect(config);

                  if (mounted && state.isConnected) {
                    widget.onConnected?.call();
                  }
                },
          child: state.isConnecting
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Connect'),
        ),
        if (state.errorMessage != null)
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              state.errorMessage!,
              style: TextStyle(color: Colors.red.shade900),
            ),
          ),
      ],
    );
  }
}
```

## Step 5: Create Status Widget

**File: `lib/src/features/connection/widgets/connection_status.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/connection_provider.dart';

class ConnectionStatus extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectionProvider);

    if (!state.isConnected) {
      return SizedBox();
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        spacing: 8,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              'Connected to ${state.config?.host}',
              style: TextStyle(
                color: Colors.green.shade900,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(connectionProvider.notifier).disconnect();
            },
            child: Text('Disconnect'),
          ),
        ],
      ),
    );
  }
}
```

## Step 6: Create Screen

**File: `lib/src/features/connection/screens/connection_screen.dart`**

```dart
import 'package:flutter/material.dart';
import '../widgets/connection_form.dart';
import '../widgets/connection_status.dart';

class ConnectionScreen extends StatelessWidget {
  final VoidCallback? onConnected;

  const ConnectionScreen({this.onConnected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Liquid Galaxy Connection'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          spacing: 24,
          children: [
            Text(
              'Connect to your Liquid Galaxy system',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            ConnectionForm(onConnected: onConnected),
            ConnectionStatus(),
          ],
        ),
      ),
    );
  }
}
```

## Step 7: Use in App

**File: `lib/src/app.dart`**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/features/connection/screens/connection_screen.dart';
import 'src/features/dashboard/screens/dashboard_screen.dart';

class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(connectionProvider);

    return MaterialApp(
      home: connectionState.isConnected
          ? DashboardScreen()
          : ConnectionScreen(
              onConnected: () {
                // Auto-navigate if needed
              },
            ),
    );
  }
}
```

## Checklist ✓

- [ ] Create `ConnectionConfig` model
- [ ] Create `ConnectionState` model
- [ ] Create `SSHService` class
- [ ] Create `ssh_provider.dart`
- [ ] Create `connection_provider.dart`
- [ ] Create `ConnectionForm` widget
- [ ] Create `ConnectionStatus` widget
- [ ] Create `ConnectionScreen`
- [ ] Add to `app.dart`
- [ ] Test connection with real LG
- [ ] Add error handling
- [ ] Add loading states
- [ ] Test with invalid credentials

## Testing

```dart
test('Connection should update state', () async {
  final container = ProviderContainer();
  
  await container.read(connectionProvider.notifier).connect(
    ConnectionConfig(
      host: '192.168.1.100',
      username: 'lg',
      password: 'lg',
    ),
  );
  
  expect(
    container.read(connectionProvider).isConnected,
    true,
  );
});
```

## Common Issues

**"Connection timeout"**
→ Check IP address is correct  
→ Check network is reachable  
→ Check SSH port (22) is open  

**"Authentication failed"**
→ Check username/password  
→ Check SSH key authentication if needed  

**"State not updating"**
→ Make sure using `.copyWith()`  
→ Check watching correct provider  

## Next Steps

1. Reference [SSH Communication](../01-core-patterns/ssh-communication.md) for deep dive
2. Reference [State Management](../01-core-patterns/state-management.md) for Riverpod patterns
3. Read [Code Templates](../03-code-templates/ssh-service.dart) for ready-to-use code
4. Check [Anti-Patterns](../04-anti-patterns/) to avoid mistakes
5. Use [Quality Checklist](../06-quality-standards/code-review-checklist.md) before shipping

---

**Rule of Thumb**: Build connection feature first, everything else depends on it.
