# Riverpod 3.x Migration Guide

**Date**: Created based on lg_controller app errors  
**Purpose**: Document common Riverpod 2.x → 3.x migration issues to prevent future mistakes

---

## 🚨 Critical Issue: Riverpod Version Mismatch

The lg_controller app had compilation errors because it used Riverpod 2.x patterns with Riverpod 3.x dependency (`flutter_riverpod: ^3.2.1`).

### Errors Encountered

1. **"Classes can only extend other classes"** - StateNotifier not available in 3.x
2. **"Too many positional arguments: 0 expected, but 1 found"** - super() signature changed
3. **"Undefined name 'state'"** - Not properly extending Notifier
4. **"StateNotifierProvider isn't defined"** - Wrong provider type for 3.x

---

## Migration Changes

### 1. Class Inheritance

**Riverpod 2.x:**
```dart
class ConnectionNotifier extends StateNotifier<ConnectionState> {
  final SSHService _ssh;
  ConnectionNotifier(this._ssh) : super(const ConnectionState());
}
```

**Riverpod 3.x:**
```dart
class ConnectionNotifier extends Notifier<ConnectionState> {
  late final SSHService _ssh;
  
  @override
  ConnectionState build() {
    _ssh = ref.watch(sshServiceProvider);
    return const ConnectionState();
  }
}
```

**Key Changes:**
- `StateNotifier` → `Notifier`
- Remove constructor with state parameter
- Add `build()` method to initialize state
- Dependencies now accessed in `build()` via `ref.watch()`

### 2. Provider Declaration

**Riverpod 2.x:**
```dart
final connectionProvider = StateNotifierProvider<
    ConnectionNotifier, 
    ConnectionState>((ref) {
  final ssh = ref.watch(sshServiceProvider);
  return ConnectionNotifier(ssh);
});
```

**Riverpod 3.x:**
```dart
final connectionProvider = NotifierProvider<
    ConnectionNotifier, 
    ConnectionState>(() {
  return ConnectionNotifier();
});
```

**Key Changes:**
- `StateNotifierProvider` → `NotifierProvider`
- Factory changes from `(ref) => ...` to `() => ...`
- No more passing dependencies via constructor

### 3. Dependency Injection

**Riverpod 2.x:** Dependencies via constructor
```dart
class ConnectionNotifier extends StateNotifier<ConnectionState> {
  final SSHService _ssh;
  ConnectionNotifier(this._ssh) : super(const ConnectionState());
}
```

**Riverpod 3.x:** Dependencies via build() method
```dart
class ConnectionNotifier extends Notifier<ConnectionState> {
  late final SSHService _ssh;
  
  @override
  ConnectionState build() {
    _ssh = ref.watch(sshServiceProvider);  // Access here
    return const ConnectionState();
  }
}
```

---

## Additional Fixes

### const vs final for String Interpolation

**Error in ssh_service.dart line 87:**
```dart
// ❌ WRONG - const cannot use variables
const relaunchScript = """
  echo $password | sudo -S service lg start
""";
```

**Fixed:**
```dart
// ✅ CORRECT - use final for runtime values
final relaunchScript = """
  echo $password | sudo -S service lg start
""";
```

### Test Setup with Riverpod

**widget_test.dart fixes:**
1. Added `import 'package:flutter_riverpod/flutter_riverpod.dart'`
2. Changed import from `main.dart` to `src/app.dart`
3. Wrapped with `ProviderScope`:
```dart
await tester.pumpWidget(const ProviderScope(child: MyApp()));
```

---

## Documentation Updates

Updated the following files to prevent these mistakes:

1. **`.agent/skills/flutter-lg-training-data/03-code-templates/connection-provider.dart`**
   - Updated to use Riverpod 3.x `Notifier` pattern
   - Added version warning comments
   - Annotated with ✅ CORRECT and ❌ WRONG markers

2. **`.agent/skills/flutter-lg-training-data/common-mistakes.md`**
   - Added "Riverpod Version Mismatch" as #1 mistake (top of file)
   - Added "const vs final String Interpolation" mistake
   - Included error messages developers will see

3. **`.agent/skills/flutter-lg-training-data/07-troubleshooting/state-management-bugs.md`**
   - Added "Riverpod 3.x Compilation Errors" section at top
   - Documented all 4 error types with solutions
   - Added quick fix checklist

4. **`.agent/skills/flutter-lg-training-data/01-core-patterns/state-management.md`**
   - Added version notice at top
   - Updated all examples to Riverpod 3.x
   - Added "Key Differences from Riverpod 2.x" notes

---

## Quick Reference

| Aspect | Riverpod 2.x | Riverpod 3.x |
|--------|-------------|-------------|
| Base Class | `StateNotifier<T>` | `Notifier<T>` |
| Provider Type | `StateNotifierProvider` | `NotifierProvider` |
| Constructor | `MyNotifier(deps) : super(initialState)` | No args, use `build()` |
| Init State | `super(initialState)` | `@override T build() { return initialState; }` |
| Dependencies | Constructor parameters | `ref.watch()` in `build()` |
| Provider Factory | `(ref) => MyNotifier(ref.watch(...))` | `() => MyNotifier()` |

---

## Verification Checklist

When creating Riverpod providers, verify:

- [ ] Check `pubspec.yaml` for Riverpod version
- [ ] If 3.x, use `Notifier` not `StateNotifier`
- [ ] If 3.x, use `NotifierProvider` not `StateNotifierProvider`
- [ ] No `super()` call with state parameter
- [ ] Implement `build()` method
- [ ] Dependencies accessed in `build()` via `ref.watch()`
- [ ] Provider factory is `() => NotifierClass()` for 3.x
- [ ] Tests wrapped with `ProviderScope`
- [ ] No `const` used with string interpolation (use `final`)

---

## See Also

- [State Management Core Pattern](01-core-patterns/state-management.md)
- [Connection Provider Template](03-code-templates/connection-provider.dart)
- [Common Mistakes](common-mistakes.md)
- [State Management Bugs Troubleshooting](07-troubleshooting/state-management-bugs.md)
- [Riverpod 3.x Official Migration Guide](https://riverpod.dev/docs/migration/v3_introduction)
