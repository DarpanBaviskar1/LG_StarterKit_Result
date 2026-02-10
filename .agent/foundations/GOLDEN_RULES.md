# 🏆 GOLDEN RULES for LG Controller Development

## THE GOLDEN RULE ✨

### For ALL KML and System Operations:
```dart
await _sshService.client!.run(command);
```

**This is the ONLY reliable pattern. Use it everywhere.**

---

## Why This Rule Exists

### The Problem
Three SSH methods exist in dartssh2:
1. **`execute()`** - Returns immediately ❌ **NEVER USE**
2. **`_sshService.run()`** - Wrapper with UTF-8 decoding ⚠️ **Sometimes works**
3. **`_sshService.client!.run()`** - Direct client call ✅ **ALWAYS USE**

### The Real Issue: Race Conditions
Many operations have dependencies where the next step MUST wait for the previous step to complete:

```
KML File Write → Parse Delay → Tour Trigger
```

If `write` doesn't complete before `trigger` runs, **everything fails silently.**

---

## Operations That MUST Use client!.run()

### Power Management
```dart
// Shutdown, Reboot, Relaunch
await _sshService.client!.run('sshpass -p "$_password" ssh lg1 "...')
```

### Navigation & Flying
```dart
// FlyToMumbai, FlyTo, Tours
await _sshService.client!.run('echo "$escapedKml" > /var/www/html/kml/master.kml');
await Future.delayed(const Duration(seconds: 1));
await _sshService.client!.run('echo "playtour=Mumbai" > /tmp/query.txt');
```

### Logo Management
```dart
// SendLogo, ClearLogos
await _sshService.client!.run('echo "$escapedKml" > /var/www/html/kml/slave_$screen.kml');
await _sshService.client!.run('touch /var/www/html/kml/slave_$screen.kml');
```

### Any File Operation
- ✅ Writing KML files
- ✅ Uploading images
- ✅ Triggering commands that depend on file writes
- ✅ Anything with > 1 command in sequence

---

## The Pattern Template

Use this template for ANY new KML/system operation:

```dart
Future<bool> myOperation(String param) async {
  try {
    // 1. Check connection
    final client = _sshService.client;
    if (client == null || client.isClosed) {
      debugPrint('Operation failed: SSH not connected');
      return false;
    }

    // 2. Execute with client!.run()
    debugPrint('Starting operation...');
    await client.run('command 1');
    await Future.delayed(const Duration(seconds: 1)); // Wait for parsing
    await client.run('command 2');
    
    // 3. Log success
    debugPrint('Operation completed successfully');
    return true;
  } catch (e) {
    debugPrint('Operation failed: $e');
    return false;
  }
}
```

---

## Critical Mistakes to AVOID

### ❌ WRONG - Never use execute()
```dart
await _sshService.execute('command'); // Returns immediately, unsafe
```

### ❌ WRONG - Never use wrapper without checking
```dart
await _sshService.run('command'); // Works sometimes, unreliable
```

### ❌ WRONG - Never skip connection check
```dart
await _sshService.client!.run('command'); // Crashes if not connected
```

### ✅ CORRECT - Always use this pattern
```dart
final client = _sshService.client;
if (client == null || client.isClosed) return false;
await client.run('command');
```

---

## Historical Context: How We Learned This

### Symptom 1: Power Management Didn't Work
- Buttons showed "Shutting down..." but nothing happened
- **Root Cause:** Using `execute()` instead of `run()`
- **Fix:** Changed to `client!.run()`

### Symptom 2: Tours Played But Stuck
- "Flying to Mumbai" button would trigger but no animation
- **Root Cause:** Using suboptimal wrapper `run()` method
- **Fix:** Changed to direct `client!.run()`

### Symptom 3: Relaunch Failed Silently
- Shutdown/Reboot worked, but Relaunch always failed
- **Root Cause:** Using `const` instead of `final` for password interpolation
- **Fix:** Changed script to `final` to allow `$_password` interpolation

### Symptom 4: Logos Never Appeared
- "Send Logo" button would complete but slave screens stayed blank
- **Root Cause:** File write wasn't waiting, refresh ran too early
- **Fix:** Changed `execute()` to `client!.run()`

### Symptom 5: ISS Tracking Timed Out
- External API calls randomly failed with "connection timeout"
- **Root Cause:** No timeout configuration on Dio client
- **Fix:** Added 10-second timeouts and retry logic

---

## Checklist Before Committing

Before you commit ANY SSH operation code:

- [ ] Am I using `_sshService.client!.run()`?
- [ ] Did I check if `client` is null/closed?
- [ ] Did I add proper error handling?
- [ ] Are there multiple operations? Did I add delays between them?
- [ ] Did I add debug logging for troubleshooting?
- [ ] Did I test with actual SSH connection failures?
- [ ] Did I document the reason for each command?

If you answered NO to any question, **DO NOT COMMIT.**

---

## Files Using This Rule

✅ **ssh_service.dart** - Power management functions  
✅ **navigation_service.dart** - Flying and tour operations  
✅ **logo_service.dart** - Logo upload and clearing  
✅ **iss_service.dart** - External API with retry logic  

---

## When You Add New Features

If you need to:
- Control LG systems
- Upload KML files
- Trigger tours/flights
- Send logos/overlays
- Execute any shell commands

**Always use:** `await _sshService.client!.run(command);`

**Never use:** `execute()` or `_sshService.run()`

---

## Questions?

Refer to:
- [SKILL.md](../domains/flutter/flutter-architect/SKILL.md) - Reference implementations
- [common-mistakes.md](../domains/flutter/flutter-architect/flutter-lg-training-data/common-mistakes.md) - What NOT to do

---

**Last Updated:** February 6, 2026  
**Confidence Level:** 🟢 Production Tested & Proven
