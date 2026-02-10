---
title: State Management Anti-Patterns with Riverpod
folder: 04-anti-patterns
tags: [anti-patterns, riverpod, state-management, mistakes]
related:
  - ../01-core-patterns/state-management.md
  - ../07-troubleshooting/state-management-bugs.md
difficulty: intermediate
time-to-read: 10 min
---

# State Management Anti-Patterns 🚫

Common Riverpod mistakes that cause bugs.

## 1. ❌ Mutating State

```dart
// BAD - Directly mutating state
state.isConnected = true;
state.errorMessage = null;
```

**Problem**: Listeners don't get notified of changes  
**Fix**:
```dart
// GOOD - Use copyWith
state = state.copyWith(
  isConnected: true,
  errorMessage: null,
);
```

## 2. ❌ Not Implementing copyWith

```dart
// BAD - State without copyWith
class MyState {
  final bool isLoading;
  final String? error;
  
  MyState({this.isLoading = false, this.error});
  // No copyWith!
}
```

**Problem**: Can't update state properly  
**Fix**:
```dart
// GOOD - Implement copyWith
class MyState {
  final bool isLoading;
  final String? error;
  
  MyState({this.isLoading = false, this.error});
  
  MyState copyWith({
    bool? isLoading,
    String? error,
  }) {
    return MyState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
```

## 3. ❌ Using setState instead of Riverpod

```dart
// BAD - Mixing setState with Riverpod
class MyWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends ConsumerState<MyWidget> {
  bool isLoading = false;
  
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        setState(() => isLoading = true);
        // ...
        setState(() => isLoading = false);
      },
    );
  }
}
```

**Problem**: Local state and global state conflict  
**Fix**:
```dart
// GOOD - Use only Riverpod
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(myProvider);
    
    return ElevatedButton(
      onPressed: () {
        ref.read(myProvider.notifier).doSomething();
      },
    );
  }
}
```

## 4. ❌ Creating New Instances Every Build

```dart
// BAD - Provider creates new object every build
final serviceProvider = Provider((ref) {
  return MyService(); // New instance every time!
});
```

**Problem**: Wastes memory, loses state  
**Fix**:
```dart
// GOOD - Providers cache by default
final serviceProvider = Provider((ref) {
  return MyService(); // Only created once
});
```

## 5. ❌ Hard Coding Dependencies

```dart
// BAD - Service has hard-coded dependencies
class MyNotifier extends StateNotifier<MyState> {
  MyNotifier() : super(const MyState()) {
    _service = SSHService(); // Hard-coded!
  }
}
```

**Problem**: Can't test, not flexible  
**Fix**:
```dart
// GOOD - Inject dependencies
class MyNotifier extends StateNotifier<MyState> {
  final SSHService _service;
  
  MyNotifier(this._service) : super(const MyState());
}

final myProvider = StateNotifierProvider<MyNotifier, MyState>((ref) {
  final service = ref.watch(sshServiceProvider);
  return MyNotifier(service);
});
```

## 6. ❌ Not Handling Async Errors

```dart
// BAD - Ignoring exceptions
Future<void> fetchData() async {
  try {
    final data = await api.fetch();
    state = state.copyWith(data: data);
  } catch (e) {
    // Ignore error
  }
}
```

**Problem**: User doesn't know what failed  
**Fix**:
```dart
// GOOD - Set error state
Future<void> fetchData() async {
  try {
    final data = await api.fetch();
    state = state.copyWith(data: data, error: null);
  } catch (e) {
    state = state.copyWith(error: e.toString());
  }
}
```

## 7. ❌ Watching Too Much

```dart
// BAD - Watching entire state object
final state = ref.watch(myProvider);

if (state.isConnected) { ... }
if (state.errorMessage != null) { ... }
```

**Problem**: Widget rebuilds on any state change  
**Fix**:
```dart
// GOOD - Watch specific field with select
final isConnected = ref.watch(myProvider.select(
  (state) => state.isConnected,
));

final error = ref.watch(myProvider.select(
  (state) => state.errorMessage,
));
```

## 8. ❌ Using FutureProvider for Everything

```dart
// BAD - FutureProvider for one-time fetch
final dataProvider = FutureProvider<Data>((ref) async {
  return await api.fetch();
});

// But need to refetch manually
ref.refresh(dataProvider);
```

**Problem**: Hard to manage manual refreshes  
**Fix**:
```dart
// GOOD - Use StateNotifier for control
class DataNotifier extends StateNotifier<AsyncValue<Data>> {
  DataNotifier() : super(const AsyncValue.loading());
  
  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final data = await api.fetch();
      state = AsyncValue.data(data);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}
```

## 9. ❌ Not Using Equatable

```dart
// BAD - State without value equality
class MyState {
  final String value;
  MyState(this.value);
}

// Widget rebuilds even if value is same
final s1 = MyState('test');
final s2 = MyState('test');
s1 == s2 // false! Rebuilds unnecessarily
```

**Problem**: Unnecessary rebuilds  
**Fix**:
```dart
// GOOD - Use Equatable
import 'package:equatable/equatable.dart';

class MyState extends Equatable {
  final String value;
  MyState(this.value);
  
  @override
  List<Object?> get props => [value];
}

final s1 = MyState('test');
final s2 = MyState('test');
s1 == s2 // true! No unnecessary rebuilds
```

## 10. ❌ Not Disposing Resources

```dart
// BAD - Provider never cleans up
final serviceProvider = Provider((ref) {
  final service = MyService();
  // No cleanup when widget is destroyed
  return service;
});
```

**Problem**: Memory leaks, connections not closed  
**Fix**:
```dart
// GOOD - Use onDispose
final serviceProvider = Provider((ref) {
  final service = MyService();
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});
```

## Riverpod Patterns Checklist

- [ ] Always use copyWith for state updates
- [ ] Implement Equatable on state classes
- [ ] Never hard-code dependencies
- [ ] Inject dependencies via ref.watch
- [ ] Use .select() for specific fields
- [ ] Handle all async errors
- [ ] Set error state on exceptions
- [ ] Use onDispose for cleanup
- [ ] Don't mix setState with Riverpod
- [ ] Test providers with ProviderContainer

## Quick Fix Guide

| Problem | Cause | Fix |
|---------|-------|-----|
| Rebuilds too much | Watching whole state | Use .select() |
| State not updating | Direct mutation | Use copyWith() |
| Memory leak | No cleanup | Add ref.onDispose() |
| Can't test | Hard-coded deps | Inject via ref |
| Lost on rebuild | New instance | Provider caches |
| Equality fails | No Equatable | Extend Equatable |

## Next Steps

1. Read [State Management](../01-core-patterns/state-management.md)
2. Check [State Management Bugs](../07-troubleshooting/state-management-bugs.md)
3. Reference [Code Templates](../03-code-templates/connection-provider.dart)

---

**Rule of Thumb**: State should be immutable. If you're mutating, you're doing it wrong.
