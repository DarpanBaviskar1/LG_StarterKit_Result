---
title: Troubleshooting Guide
folder: 07-troubleshooting
tags: [overview, troubleshooting, debugging, help]
---

# Troubleshooting Guide 🔧

Fixes for common problems.

## What's Inside

Solutions for the most common issues developers encounter.

### Files

1. **[SSH Connection Issues](ssh-connection-issues.md)**
   - Connection timeout
   - Authentication failed
   - Connection refused
   - Host not found
   - Connection dropping
   - Commands failing
   - State mismatch
   - Debugging flowchart

2. **[KML Validation Errors](kml-validation-errors.md)**
   - KML not loading
   - XML parsing errors
   - Coordinates not working
   - Camera not positioning
   - Tour/animation not playing
   - Placemark not showing
   - Validation checklist

3. **[State Management Bugs](state-management-bugs.md)**
   - Widget not rebuilding
   - State not updating
   - Excessive rebuilds
   - Stale closures
   - Memory leaks
   - Provider comparison issues
   - Testing helpers

4. **[Common Questions](common-questions.md)** (coming soon)

## How to Use

### When Something Breaks

1. **Identify the symptom**
   - "App freezes when connecting"
   - "KML sent but nothing happens"
   - "Widget doesn't update"

2. **Find matching symptom** in troubleshooting file
   - SSH → Connection Issues
   - KML → Validation Errors
   - State → State Management Bugs

3. **Follow debug steps**
   - Run suggested checks
   - Add debug prints
   - Test in isolation

4. **Compare solutions**
   - Try suggested fixes
   - Check anti-patterns
   - Reference code templates

### When Stuck

1. Open this folder
2. Find your symptom
3. Follow troubleshooting steps
4. If still stuck, check [Anti-Patterns](../04-anti-patterns/)

## Symptom Index

### Connection Issues
- ❌ "App hangs/freezes" → Connection timeout
- ❌ "Authentication failed" → Wrong credentials
- ❌ "Connection refused" → SSH not running
- ❌ "Host not found" → Wrong IP address
- ❌ "Keeps disconnecting" → Network instability
- ❌ "Connected but commands fail" → Command syntax
- ❌ "UI says connected but it's not" → State mismatch

### KML Issues
- ❌ "KML sent but nothing happens" → Invalid KML
- ❌ "Camera goes to wrong place" → Wrong coordinates
- ❌ "XML parsing error" → Bad XML format
- ❌ "Camera angle is wrong" → Wrong tilt/heading
- ❌ "Animation doesn't play" → Tour format issue
- ❌ "Placemark not showing" → Invalid structure

### State Issues
- ❌ "State changes but UI doesn't update" → Not watching provider
- ❌ "UI rebuilds constantly" → Watching whole state
- ❌ "State appears to not change" → Direct mutation
- ❌ "Using old values in closure" → Stale closure
- ❌ "App memory grows over time" → Memory leak

## Quick Fixes

### Freezing App
→ Check for timeouts and blocking calls  
→ Use `Future` and `async/await`  
→ Don't call SSH operations in main thread

### Silent Failures
→ Add debug prints everywhere  
→ Check exception handling  
→ Validate inputs before operations

### State Not Updating
→ Add prints before/after state change  
→ Check using `ref.watch()`  
→ Verify `copyWith()` implementation

### Wrong Values
→ Add debug prints showing values  
→ Check coordinate order (Lng, Lat)  
→ Verify XML is correct

## Debug Tools

### Debug Printing
```dart
debugPrint('📍 State before: $oldState');
debugPrint('📍 State after: $newState');
debugPrint('🔌 Connected: ${ssh.isConnected}');
debugPrint('⏱️  Took ${DateTime.now().difference(start)}');
```

### Testing Connection
```bash
ping 192.168.1.100
telnet 192.168.1.100 22
ssh lg@192.168.1.100
```

### Testing KML
- Save to test.kml
- Open in Google Earth Desktop
- If it works there, should work on LG

### Testing State
```dart
final container = ProviderContainer();
final initialState = container.read(myProvider);
await container.read(myProvider.notifier).doSomething();
final newState = container.read(myProvider);
assert(newState != initialState);
```

## Common Root Causes

| Symptom | Root Cause | Fix |
|---------|-----------|-----|
| App freezes | No timeout | Add timeout |
| Silent fail | No error handling | Add try/catch |
| Wrong location | Lat,Lng order | Use Lng,Lat |
| No rebuild | Not watching | Use ref.watch() |
| Memory leak | No cleanup | Add ref.onDispose() |
| State mismatch | Exception not caught | Add error state |

## Next Steps

1. Identify your symptom
2. Open matching troubleshooting file
3. Follow debug steps
4. Apply suggested fix
5. If still stuck:
   - Check [Anti-Patterns](../04-anti-patterns/)
   - Review [Core Patterns](../01-core-patterns/)
   - Run [Code Templates](../03-code-templates/) tests

---

**Rule of Thumb**: 80% of issues are SSH timeouts, KML validation, or state mutations. Start there.
