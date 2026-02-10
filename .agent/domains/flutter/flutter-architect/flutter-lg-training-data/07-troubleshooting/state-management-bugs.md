---
title: State Management Bugs & Debugging
folder: 07-troubleshooting
tags: [troubleshooting, riverpod, state-management, debugging]
related:
  - ../01-core-patterns/state-management.md
  - ../04-anti-patterns/state-management-mistakes.md
difficulty: intermediate
time-to-read: 10 min
---

# State Management & Riverpod Debugging 🐛

Fix common state management issues.

## 🚨 CRITICAL: Riverpod 3.x Compilation Errors

### Error: "Classes can only extend other classes"

**Full Error Message**:
```
lib/src/features/connections/presentation/connection_provider.dart:13:40:
Error: Classes can only extend other classes.
class ConnectionNotifier extends StateNotifier<ConnectionState> {
                                       ^^^^^^^^^^^^^
```

**Cause**: You're using Riverpod 2.x `StateNotifier` pattern in a Riverpod 3.x project.

**Solution**:
```dart
// ❌ WRONG (Riverpod 2.x)
class ConnectionNotifier extends StateNotifier<ConnectionState> {
  final SSHService _ssh;
  ConnectionNotifier(this._ssh) : super(const ConnectionState());
}

// ✅ CORRECT (Riverpod 3.x)
class ConnectionNotifier extends Notifier<ConnectionState> {
  late final SSHService _ssh;
  
  @override
  ConnectionState build() {
    _ssh = ref.watch(sshServiceProvider);
    return const ConnectionState();
  }
}
```

### Error: "Too many positional arguments: 0 expected, but 1 found"

**Full Error Message**:
```
Error: Too many positional arguments: 0 expected, but 1 found.
  ConnectionNotifier(this._ssh) : super(const ConnectionState());
                                        ^
```

**Cause**: `Notifier` in Riverpod 3.x doesn't take a state parameter in super().

**Solution**: Remove the super() call and use `build()` method:
```dart
// ❌ WRONG
class ConnectionNotifier extends Notifier<ConnectionState> {
  ConnectionNotifier() : super(const ConnectionState()); // No super() needed!
}

// ✅ CORRECT
class ConnectionNotifier extends Notifier<ConnectionState> {
  @override
  ConnectionState build() {
    return const ConnectionState(); // Initialize state here
  }
}
```

### Error: "Undefined name 'state'"

**Full Error Message**:
```
Error: Undefined name 'state'.
    state = ConnectionState(isConnected: true, config: connection);
    ^^^^^
```

**Cause**: Not properly extending `Notifier`, so `state` property isn't available.

**Solution**: Make sure you:
1. Extend `Notifier<YourState>` (not `StateNotifier`)
2. Implement `build()` method
3. Have `flutter_riverpod` imported correctly

```dart
// ✅ CORRECT structure
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectionNotifier extends Notifier<ConnectionState> {
  @override
  ConnectionState build() => const ConnectionState();
  
  void connect() {
    state = state.copyWith(isConnected: true); // state is now available
  }
}
```

### Error: "StateNotifierProvider isn't defined"

**Full Error Message**:
```
Error: The getter 'StateNotifierProvider' isn't defined for the class '_ProviderLabel'.
final connectionProvider = StateNotifierProvider<ConnectionNotifier, ConnectionState>((ref) {
                           ^^^^^^^^^^^^^^^^^^^^
```

**Cause**: Using Riverpod 2.x `StateNotifierProvider` in Riverpod 3.x.

**Solution**: Use `NotifierProvider`:
```dart
// ❌ WRONG (Riverpod 2.x)
final connectionProvider = StateNotifierProvider<
    ConnectionNotifier,
    ConnectionState>((ref) {
  final ssh = ref.watch(sshServiceProvider);
  return ConnectionNotifier(ssh);
});

// ✅ CORRECT (Riverpod 3.x)
final connectionProvider = NotifierProvider<
    ConnectionNotifier,
    ConnectionState>(() {
  return ConnectionNotifier();
});
```

**Note**: Factory function changes from `(ref) => ...` to `() => ...` because dependencies are now accessed in `build()` method.

### Quick Fix Checklist for Riverpod 3.x

If you see Riverpod errors, check:

- [ ] Pubspec has `flutter_riverpod: ^3.x.x`
- [ ] Using `Notifier` not `StateNotifier`
- [ ] Using `NotifierProvider` not `StateNotifierProvider`
- [ ] No `super()` call in constructor
- [ ] Implemented `build()` method
- [ ] Dependencies accessed in `build()` via `ref.watch()`
- [ ] Provider factory is `() => NotifierClass()` not `(ref) => ...`

---

## Widget Not Rebuilding

**Symptom**: State changes but UI doesn't update

**Causes**:

1. **Not watching provider**:
```dart
// BAD - Not watching
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // State changes but we don't watch it!
    final state = connectionProvider;
    return Text(state.toString());
  }
}

// GOOD - Watch the provider
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectionProvider);
    return Text(state.isConnected ? 'Connected' : 'Disconnected');
  }
}
```

2. **Using direct mutation**:
```dart
// BAD - Direct mutation, listeners don't get notified
state.isConnected = true;

// GOOD - Use copyWith
state = state.copyWith(isConnected: true);
```

3. **Not using Equatable**:
```dart
// BAD - State objects not equal even with same values
class MyState {
  final bool isLoading;
  MyState(this.isLoading);
}
final s1 = MyState(true);
final s2 = MyState(true);
s1 == s2; // false! Rebuilds unnecessarily

// GOOD - Use Equatable
class MyState extends Equatable {
  final bool isLoading;
  MyState(this.isLoading);
  @override
  List<Object> get props => [isLoading];
}
final s1 = MyState(true);
final s2 = MyState(true);
s1 == s2; // true! Doesn't rebuild
```

**Debug**:
```dart
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(connectionProvider);
    
    // Print whenever build is called
    debugPrint('🔄 Widget built, state: $state');
    
    return Text(state.isConnected ? 'Connected' : 'Disconnected');
  }
}
```

## State Not Updating

**Symptom**: Call `ref.read(provider.notifier).doSomething()` but state doesn't change

**Debug Steps**:

1. Check if exception thrown:
```dart
Future<void> connect(config) async {
  try {
    await _ssh.connect(...);
    state = state.copyWith(isConnected: true);
  } catch (e) {
    debugPrint('❌ Exception: $e');
    state = state.copyWith(isConnected: false, errorMessage: e.toString());
  }
}
```

2. Verify state actually changed:
```dart
Future<void> connect(config) async {
  final oldState = state;
  state = state.copyWith(isConnected: true);
  debugPrint('Old: $oldState');
  debugPrint('New: $state');
  debugPrint('Changed: ${oldState != state}');
}
```

3. Check copyWith implementation:
```dart
// BAD - copyWith returns same instance
MyState copyWith({bool? isConnected}) {
  return this; // Always returns same instance!
}

// GOOD - copyWith creates new instance
MyState copyWith({bool? isConnected}) {
  return MyState(
    isConnected: isConnected ?? this.isConnected,
  );
}
```

## Excessive Rebuilds

**Symptom**: Widget rebuilds constantly even when state doesn't change

**Causes**:

1. **Watching entire state when you only need one field**:
```dart
// BAD - Rebuilds on any state change
final state = ref.watch(connectionProvider);
if (state.isConnected) { ... }

// GOOD - Only watch what you need
final isConnected = ref.watch(connectionProvider.select(
  (state) => state.isConnected,
));
```

2. **Creating new objects in build**:
```dart
// BAD - New list every build
@override
Widget build(BuildContext context, WidgetRef ref) {
  final items = ref.watch(itemsProvider);
  return ListView(children: items.map(...).toList()); // New list!
}

// GOOD - Provider creates once
final itemsProvider = Provider((ref) => [1, 2, 3]);
```

3. **Provider dependency changes**:
```dart
// BAD - Notifier rebuilds if dependency changes
final notifierProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  return MyNotifier(
    ref.watch(dependencyProvider), // Rebuild if dependency changes
  );
});

// Sometimes OK if dependency actually changes
```

**Debug Excessive Rebuilds**:
```dart
class MyWidget extends ConsumerWidget {
  static int buildCount = 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    buildCount++;
    debugPrint('🔄 Build #$buildCount');
    
    final state = ref.watch(myProvider);
    return Text(state.toString());
  }
}

// Check console: is buildCount incrementing rapidly?
```

## Stale Closures / Old State

**Symptom**: Using state that was captured in a closure, but state changed

```dart
// BAD - oldState captured in closure
final oldState = state;

Future<void> doSomething() async {
  await someAsync();
  // oldState is stale!
  if (oldState.isConnected) { ... }
}

// GOOD - Read current state
Future<void> doSomething() async {
  await someAsync();
  // Get fresh state
  if (state.isConnected) { ... }
}
```

## Memory Leaks

**Symptom**: App memory increases over time

**Causes**:

1. **Not disposing resources**:
```dart
// BAD - Never cleaned up
final sshProvider = Provider((ref) {
  final ssh = SSHService();
  // If SSH holds connections, they leak!
  return ssh;
});

// GOOD - Cleanup on dispose
final sshProvider = Provider((ref) {
  final ssh = SSHService();
  
  ref.onDispose(() {
    ssh.disconnect();
  });
  
  return ssh;
});
```

2. **Holding references to providers**:
```dart
// BAD - Holding reference across screens
class MyApp {
  final container = ProviderContainer();
  
  // If you never dispose container, memory leaks
}

// GOOD - Let Flutter manage it
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Flutter manages provider lifecycle
    return ...;
  }
}
```

## Provider Comparison Issues

**Symptom**: Provider state appears same but widget still rebuilds

**Debug**:
```dart
// Add hashCode and toString to state
class MyState extends Equatable {
  final bool isConnected;
  
  MyState(this.isConnected);
  
  @override
  List<Object?> get props => [isConnected];
  
  @override
  String toString() => 'MyState(isConnected: $isConnected)';
}

// Compare values
final s1 = MyState(true);
final s2 = MyState(true);
debugPrint('s1: $s1');
debugPrint('s2: $s2');
debugPrint('Equal: ${s1 == s2}');
debugPrint('s1.props: ${s1.props}');
debugPrint('s2.props: ${s2.props}');
```

## Testing State Changes

```dart
test('State updates on connect', () async {
  final container = ProviderContainer();
  
  // Initial state
  expect(container.read(connectionProvider).isConnected, false);
  
  // Perform action
  await container.read(connectionProvider.notifier).connect(config);
  
  // Check new state
  expect(container.read(connectionProvider).isConnected, true);
});

test('copyWith preserves other fields', () {
  final state = ConnectionState(
    isConnected: true,
    errorMessage: 'Old error',
  );
  
  final newState = state.copyWith(isConnected: false);
  
  expect(newState.isConnected, false);
  expect(newState.errorMessage, 'Old error'); // Preserved!
});
```

## Common Issues Checklist

- [ ] Am I using `ref.watch()` or just reading provider?
- [ ] Is state being mutated directly instead of with `copyWith()`?
- [ ] Does my state implement `Equatable`?
- [ ] Am I using `.select()` for specific fields?
- [ ] Are resources being disposed in `ref.onDispose()`?
- [ ] Are exceptions being caught and handled?
- [ ] Is state changing but listeners not notified?
- [ ] Are there circular dependencies between providers?
- [ ] Am I testing with `ProviderContainer`?

## Quick Debug Template

```dart
class ConnectionNotifier extends StateNotifier<ConnectionState> {
  ConnectionNotifier() : super(const ConnectionState());
  
  Future<void> connect(config) async {
    debugPrint('📍 Before: $state');
    
    try {
      state = state.copyWith(isConnecting: true);
      debugPrint('📍 After isConnecting: $state');
      
      await doConnect();
      
      state = state.copyWith(isConnecting: false, isConnected: true);
      debugPrint('📍 After connected: $state');
    } catch (e) {
      state = state.copyWith(isConnecting: false, errorMessage: e.toString());
      debugPrint('📍 After error: $state');
    }
  }
}
```

## Next Steps

1. Read [State Management](../01-core-patterns/state-management.md)
2. Review [State Mistakes](../04-anti-patterns/state-management-mistakes.md)
3. Check [Code Templates](../03-code-templates/connection-provider.dart)

---

**Rule of Thumb**: If state doesn't update, add debug prints before and after state assignments. Print tells the truth, UI might lie.
