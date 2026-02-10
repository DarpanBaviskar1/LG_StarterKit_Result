---
title: State Management with Riverpod
folder: 01-core-patterns
tags: [riverpod, state-management, providers, riverpod]
related:
  - ../02-implementation-guides/connection-feature.md
  - ../03-code-templates/connection-provider.dart
  - ../07-troubleshooting/state-management-bugs.md
  - ../04-anti-patterns/state-management-mistakes.md
difficulty: intermediate
time-to-read: 12 min
---

# State Management with Riverpod 🔄

Global state management is critical. Use Riverpod, not setState.

## ⚠️ Version Notice

**This guide uses Riverpod 3.x (flutter_riverpod ^3.0.0)**

If using Riverpod 2.x, the API is different:
- Riverpod 2.x: Use `StateNotifier` + `StateNotifierProvider`
- Riverpod 3.x: Use `Notifier` + `NotifierProvider` ← **This guide**

Check your `pubspec.yaml` to see your version.

## Why Riverpod?

- ✅ Global state accessible everywhere
- ✅ Reactive updates automatically
- ✅ Easy dependency injection
- ✅ Testable
- ✅ Type-safe

## Core Pattern (Riverpod 3.x)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Define state class
class ConnectionState {
  final bool isConnected;
  final bool isConnecting;
  final String? errorMessage;
  final String? host;
  
  const ConnectionState({
    this.isConnected = false,
    this.isConnecting = false,
    this.errorMessage,
    this.host,
  });
  
  ConnectionState copyWith({
    bool? isConnected,
    bool? isConnecting,
    String? errorMessage,
    String? host,
  }) {
    return ConnectionState(
      isConnected: isConnected ?? this.isConnected,
      isConnecting: isConnecting ?? this.isConnecting,
      errorMessage: errorMessage,
      host: host ?? this.host,
    );
  }
}

// 2. Create notifier (Riverpod 3.x uses Notifier, not StateNotifier)
class ConnectionNotifier extends Notifier<ConnectionState> {
  late final SSHService _ssh;
  
  @override
  ConnectionState build() {
    _ssh = ref.watch(sshServiceProvider);
    return const ConnectionState();
  }
  
  Future<void> connect(String host, String user, String pass) async {
    // Show loading
    state = state.copyWith(isConnecting: true, errorMessage: null);
    
    // Try to connect
    final success = await _ssh.connect(
      host: host,
      username: user,
      password: pass,
    );
    
    if (success) {
      // Success
      state = state.copyWith(
        isConnected: true,
        isConnecting: false,
        host: host,
      );
    } else {
      // Failure
      state = state.copyWith(
        isConnected: false,
        isConnecting: false,
        errorMessage: 'Failed to connect',
      );
    }
  }
  
  Future<void> disconnect() async {
    await _ssh.disconnect();
    state = const ConnectionState();
  }
}

// 3. Create provider (Riverpod 3.x uses NotifierProvider, not StateNotifierProvider)
final sshServiceProvider = Provider<SSHService>((ref) => SSHService());

final connectionProvider = NotifierProvider<
  ConnectionNotifier, ConnectionState>(() {
  return ConnectionNotifier();
});
```

**Key Differences from Riverpod 2.x:**
- Use `Notifier` instead of `StateNotifier`
- Use `NotifierProvider` instead of `StateNotifierProvider`
- Provider factory is `() => NotifierClass()` not `(ref) => NotifierClass(deps)`
- Dependencies accessed via `ref.watch()` in `build()` method, not constructor

## Using in Widgets

```dart
class ConnectionScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the provider
    final state = ref.watch(connectionProvider);
    
    return Scaffold(
      body: state.isConnecting
          ? Center(child: CircularProgressIndicator())
          : state.isConnected
              ? _buildConnectedUI(context, ref)
              : _buildConnectionForm(context, ref),
    );
  }
  
  Widget _buildConnectionForm(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        TextField(/* IP input */),
        ElevatedButton(
          onPressed: () {
            ref.read(connectionProvider.notifier).connect(
              '192.168.1.100',
              'lg',
              'lg',
            );
          },
          child: Text('Connect'),
        ),
        if (ref.watch(connectionProvider).errorMessage != null)
          Text(
            ref.watch(connectionProvider).errorMessage!,
            style: TextStyle(color: Colors.red),
          ),
      ],
    );
  }
  
  Widget _buildConnectedUI(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        Text('Connected to ${ref.watch(connectionProvider).host}'),
        ElevatedButton(
          onPressed: () {
            ref.read(connectionProvider.notifier).disconnect();
          },
          child: Text('Disconnect'),
        ),
      ],
    );
  }
}
```

## Provider Types

### Simple Value
```dart
final nameProvider = Provider<String>((ref) => 'Flutter');
```

### Simple State
```dart
final countProvider = StateProvider<int>((ref) => 0);
```

### Complex State
```dart
class MyNotifier extends StateNotifier<MyState> {
  MyNotifier() : super(const MyState());
  
  void increment() => state = state.copyWith(count: state.count + 1);
}

final myProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier();
});
```

### Async Data
```dart
final futureProvider = FutureProvider<String>((ref) async {
  return await fetchData();
});
```

## Best Practices

### 1. Use .copyWith() for Immutability
```dart
// ✅ GOOD - Immutable
state = state.copyWith(isConnected: true);

// ❌ BAD - Mutation
state.isConnected = true;
```

### 2. Create Specific States
```dart
// ✅ GOOD - Multiple specific states
abstract class LoadingState {}
class InitialState extends LoadingState {}
class LoadingState extends LoadingState {}
class SuccessState extends LoadingState {}
class ErrorState extends LoadingState {}

// ❌ BAD - Generic booleans
bool isLoading, isSuccess, isError;
```

### 3. Use StateNotifier for Complex Logic
```dart
// ✅ GOOD - Logic in notifier
final provider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier(ref.watch(dependency));
});

// ❌ BAD - Logic in widget
ElevatedButton(
  onPressed: () {
    // Complex logic in widget
  },
)
```

### 4. Inject Dependencies
```dart
// ✅ GOOD - Dependencies injected
final lgProvider = Provider<LGService>((ref) {
  final ssh = ref.watch(sshServiceProvider);
  return LGService(ssh);
});

// ❌ BAD - Hard-coded dependencies
class LGService {
  final ssh = SSHService(); // Hard-coded!
}
```

## Common Patterns

### Loading + Success + Error States
```dart
@freezed
class UIState with _$UIState {
  const factory UIState.initial() = _Initial;
  const factory UIState.loading() = _Loading;
  const factory UIState.success(String data) = _Success;
  const factory UIState.error(String message) = _Error;
}

// In widget
state.when(
  initial: () => SizedBox(),
  loading: () => CircularProgressIndicator(),
  success: (data) => Text(data),
  error: (msg) => Text('Error: $msg', style: TextStyle(color: Colors.red)),
)
```

### Combining Multiple Providers
```dart
final combinedProvider = Provider((ref) {
  final connection = ref.watch(connectionProvider);
  final settings = ref.watch(settingsProvider);
  
  return CombinedData(
    connected: connection.isConnected,
    host: settings.host,
  );
});
```

## Common Issues

**Provider rebuilds too much?**
→ Use `.select()` to watch specific field  
→ Move state to separate provider  
→ Use `.when()` for fine-grained updates

**State not updating?**
→ Make sure using `.copyWith()`  
→ Verify watching the right provider  
→ Check StateNotifier constructor

**Dependency issues?**
→ Pass dependencies via `ref.watch()`  
→ Don't hard-code dependencies  
→ Use provider for all services

## Next Steps

- Read `02-implementation-guides/connection-feature.md` for example
- Copy `03-code-templates/connection-provider.dart` for template
- Check `04-anti-patterns/state-management-mistakes.md` for errors
- Use `06-quality-standards/code-review-checklist.md` before shipping

---

**Rule of Thumb**: Riverpod is your app's brain. Keep it clean, organized, and well-tested.
