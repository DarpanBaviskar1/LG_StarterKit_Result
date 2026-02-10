---
title: SSH Connection Anti-Patterns
folder: 04-anti-patterns
tags: [anti-patterns, ssh, mistakes, debugging]
related:
  - ../01-core-patterns/ssh-communication.md
  - ../07-troubleshooting/ssh-connection-issues.md
difficulty: intermediate
time-to-read: 10 min
---

# SSH Connection Anti-Patterns 🚫

Don't do these. Really. Just don't.

## 1. ❌ No Timeout

```dart
// BAD - Will hang forever
_client = await SSHClient.connect(
  host,
  username: user,
  onPasswordRequest: () => pass,
  // NO TIMEOUT!
);
```

**Problem**: App freezes if network is bad  
**Fix**:
```dart
// GOOD
_client = await SSHClient.connect(
  host,
  username: user,
  onPasswordRequest: () => pass,
  timeout: Duration(seconds: 10),
);
```

## 2. ❌ Not Checking Connection Before Execute

```dart
// BAD - Crashes if disconnected
String result = await _ssh.execute('ls');
```

**Problem**: Null reference exception  
**Fix**:
```dart
// GOOD
if (!_ssh.isConnected) {
  throw Exception('Not connected');
}
String result = await _ssh.execute('ls');
```

## 3. ❌ Hard-coded Credentials

```dart
// BAD - SECURITY ISSUE!
const String password = 'lg';
const String username = 'lg';
```

**Problem**: Credentials in source code!  
**Fix**:
```dart
// GOOD - From user input or secure storage
final config = await _storage.getConnectionConfig();
await _ssh.connect(
  host: config.host,
  username: config.username,
  password: config.password,
);
```

## 4. ❌ Not Handling Exceptions

```dart
// BAD - Crashes silently
try {
  await _ssh.connect(...);
} catch (e) {
  // Ignore error, nothing to see here
}
```

**Problem**: User doesn't know what went wrong  
**Fix**:
```dart
// GOOD
try {
  await _ssh.connect(...);
} catch (e) {
  state = state.copyWith(errorMessage: e.toString());
  debugPrint('❌ Connection failed: $e');
}
```

## 5. ❌ Connection in Main Thread

```dart
// BAD - Freezes UI
await _ssh.connect(...); // On main thread!
```

**Problem**: UI becomes unresponsive  
**Fix**:
```dart
// GOOD - Use async/await properly
Future<void> connect() async {
  state = state.copyWith(isConnecting: true);
  // This runs on isolate automatically
  await _ssh.connect(...);
  state = state.copyWith(isConnecting: false);
}
```

## 6. ❌ Not Cleaning Up Connection

```dart
// BAD - Connection leaks
class MyApp {
  final _ssh = SSHService();
  
  // Never disconnects!
}
```

**Problem**: Memory leak, connections pile up  
**Fix**:
```dart
// GOOD
class MyApp {
  final _ssh = SSHService();
  
  void dispose() {
    _ssh.disconnect();
  }
}
```

## 7. ❌ Storing Password in Memory

```dart
// BAD - Password stays in memory
String? _savedPassword = 'lg';

void connect() {
  _ssh.connect(password: _savedPassword);
  // Password never cleared!
}
```

**Problem**: Security risk if app is inspected  
**Fix**:
```dart
// GOOD - Use secure storage
final password = await _secureStorage.read(key: 'lg_password');
await _ssh.connect(password: password);
// Don't store in variable
```

## 8. ❌ Not Validating Host

```dart
// BAD - Accepts anything
await _ssh.connect(
  host: userInput, // Could be anything!
  ...
);
```

**Problem**: Invalid IPs, malicious hosts  
**Fix**:
```dart
// GOOD - Validate IP format
if (!_isValidIP(userInput)) {
  throw Exception('Invalid IP address');
}
await _ssh.connect(host: userInput, ...);
```

## 9. ❌ Retrying Forever

```dart
// BAD - Infinite retry loop
while (true) {
  try {
    await _ssh.connect(...);
    break;
  } catch (e) {
    // Try again immediately
    continue;
  }
}
```

**Problem**: Wastes CPU, bad UX  
**Fix**:
```dart
// GOOD - Finite retries with backoff
for (int i = 0; i < 3; i++) {
  try {
    await _ssh.connect(...);
    return true;
  } catch (e) {
    await Future.delayed(Duration(seconds: 2 * i));
  }
}
return false;
```

## 10. ❌ Mixing Connection Logic with UI

```dart
// BAD - Business logic in widget
class ConnectionScreen extends StatefulWidget {
  @override
  Widget build(context) {
    return ElevatedButton(
      onPressed: () async {
        _ssh.connect(...); // Logic in widget!
        setState(...);
      },
    );
  }
}
```

**Problem**: Hard to test, tightly coupled  
**Fix**:
```dart
// GOOD - Use provider
ElevatedButton(
  onPressed: () {
    ref.read(connectionProvider.notifier).connect(config);
  },
);
```

## 11. ❌ Using execute() Instead of run() for Commands

```dart
// BAD - Commands don't actually execute
Future<bool> shutdown(int rigs, String password) async {
  for (int i = 1; i <= rigs; i++) {
    await execute('sshpass -p "$password" ssh -t lg$i "sudo poweroff"');
  }
  return true;
}
```

**Problem**: `execute()` returns SSHSession but doesn't wait for command to complete. Commands appear to run but nothing happens.  
**Fix**:
```dart
// GOOD - Use run() to actually execute commands
Future<bool> shutdown(int rigs, String password) async {
  try {
    for (int i = 1; i <= rigs; i++) {
      await run('sshpass -p "$password" ssh -t lg$i "sudo poweroff"');
    }
    return true;
  } catch (e) {
    debugPrint('Shutdown failed: $e');
    return false;
  }
}
```

**When to use each:**
- `execute()` - For reading output or interactive sessions
- `run()` - For executing commands that need to complete

**Real-world impact:** This bug caused all power management buttons (shutdown/reboot/relaunch) to silently fail in production!

## 12. ❌ Incorrect sshpass + sudo Password Handling

```dart
// BAD - Password won't reach sudo
Future<bool> reboot(int rigs, String password) async {
  for (int i = 1; i <= rigs; i++) {
    // sshpass authenticates SSH, but sudo doesn't receive the password!
    await run('sshpass -p "$password" ssh -t lg$i "echo $password | sudo -S reboot"');
  }
  return true;
}
```

**Problem**: `sshpass` provides SSH auth, but the password piped to `sudo` doesn't work. Results in "Permission denied" errors.

**Why it fails:**
1. `sshpass` authenticates the SSH connection
2. Inside SSH, `echo $password` tries to pipe the password to `sudo`
3. But the password variable is empty or not properly passed through the pipeline
4. `sudo -S` expects input on stdin but doesn't receive it correctly

**Fix**:
```dart
// GOOD - Use subshell with sleep to ensure stdin buffering
Future<bool> reboot(int rigs, String password) async {
  try {
    for (int i = 1; i <= rigs; i++) {
      // Use (echo password; sleep 1) to give sudo time to read
      final command = 'sshpass -p "$password" ssh -o StrictHostKeyChecking=no -o BatchMode=no lg$i "(echo $password; sleep 1) | sudo -S reboot"';
      await run(command);
    }
    return true;
  } catch (e) {
    debugPrint('Reboot failed: $e');
    return false;
  }
}
```

**Key improvements:**
- `(echo $password; sleep 1)` - Subshell ensures password is sent then waits
- `-o BatchMode=no` - Prevents SSH from ignoring stdin
- `-o StrictHostKeyChecking=no` - Avoids host key verification prompts
- Sleep adds buffer time for password to be read by sudo

## 13. ❌ Using const for Scripts with Runtime Variable Interpolation

```dart
// BAD - const prevents password interpolation
Future<bool> relaunch() async {
  const relaunchScript = """
    if [[ \\\$(service \\\$SERVICE status) =~ 'stop' ]]; then
      (echo \$password; sleep 1) | sudo -S service \\\${SERVICE} start
    fi
  """;
  
  final command = 'sshpass -p "$_password" ssh lg1 "$relaunchScript"';
  await _client!.run(command); // Fails - \$password is literal text
}
```

**Problem**: Using `const` prevents Dart variable interpolation. The script contains `\$password` as literal text, so sudo never receives the actual password value.

**Result**: "Permission denied" errors because password isn't passed to sudo.

**Fix**:
```dart
// GOOD - final allows password interpolation
Future<bool> relaunch() async {
  final relaunchScript = """
    if [[ \\\$(service \\\$SERVICE status) =~ 'stop' ]]; then
      (echo $_password; sleep 1) | sudo -S service \\\${SERVICE} start
    fi
  """;
  
  final command = 'sshpass -p "$_password" ssh lg1 "$relaunchScript"';
  await _client!.run(command); // Works - password value is in script
}
```

**Key differences:**
- `const` = Compile-time constant, NO runtime interpolation
- `final` = Runtime value, allows `$variable` interpolation
- Use `const` for pure shell scripts with no Dart variables
- Use `final` when script needs Dart values (`$_password`, `$_rigs`, etc.)

**Real-world symptom**: Shutdown/reboot work but relaunch fails silently

## 14. ❌ Using Wrapper Methods Instead of Direct Client Calls

```dart
// BAD - Wrapper method adds unnecessary overhead
Future<bool> shutdown() async {
  for (int i = 1; i <= _rigs; i++) {
    final result = await run(command); // Calls wrapper with UTF-8 decoding
    if (result == null) {
      debugPrint('Failed to shutdown lg$i');
      return false; // May fail unnecessarily
    }
  }
}

// Wrapper adds overhead:
Future<String?> run(String command) async {
  final result = await _client!.run(command);
  final output = utf8.decode(result); // Extra decoding
  debugPrint('SSH Output: $output'); // Extra logging
  return output; // Must null-check
}
```

**Problem**: 
1. Wrapper adds UTF-8 decoding overhead for commands that don't return text
2. Forces null checking when result doesn't matter
3. Doesn't match SKILL.md reference implementation
4. Extra logging may cause issues with power management

**Fix**:
```dart
// GOOD - Direct SSHClient.run() call as in SKILL.md
Future<bool> shutdown() async {
  try {
    for (int i = 1; i <= _rigs; i++) {
      await _client!.run(command); // Direct call, no overhead
    }
    return true;
  } catch (e) {
    debugPrint('Shutdown failed: $e');
    return false;
  }
}
```

**Why direct calls work better:**
- No extra UTF-8 decoding
- No null checking needed
- Matches reference implementation
- Simpler error handling via catch block
- Fire-and-forget for power management

**Pattern:**
- Use wrapper `run()` when you NEED output/logging
- Use `_client!.run()` directly for power management commands

## Mistake #15: Using execute() or Wrapper run() for KML Upload and Tour Playback

### The Problem
Navigation functions (flying, tours) using `execute()` or `_sshService.run()` fail silently. The PRODUCTION pattern requires direct `_sshService.client!.run()` calls.

### ❌ Bad Patterns:

**Pattern 1 - Using execute():**
```dart
// ❌ WRONG - execute() doesn't wait for file write completion
Future<void> flyToMumbai() async {
  final kmlPath = '/var/www/html/kml/master.kml';
  final escapedKml = mumbaiKml.replaceAll('"', '\\"').replaceAll('\$', '\\\$');
  
  await _sshService.execute('echo "$escapedKml" > $kmlPath'); // Returns immediately!
  await Future.delayed(const Duration(seconds: 1));
  await _sshService.execute('echo "playtour=Mumbai" > /tmp/query.txt');
}
```

**Pattern 2 - Using wrapper run():**
```dart
// ❌ ALSO WRONG - Wrapper run() adds UTF-8 decoding overhead
Future<void> flyToMumbai() async {
  final kmlPath = '/var/www/html/kml/master.kml';
  final escapedKml = mumbaiKml.replaceAll('"', '\\"').replaceAll('\$', '\\\$');
  
  await _sshService.run('echo "$escapedKml" > $kmlPath'); // Wrapper adds overhead
  await Future.delayed(const Duration(seconds: 1));
  await _sshService.run('echo "playtour=Mumbai" > /tmp/query.txt'); // Not reliable
}
```

**Result:** Tour never plays, no errors shown, silent failure.

### ✅ PRODUCTION PATTERN: Use _sshService.client!.run() Directly

**This is the PROVEN WORKING PATTERN:**

```dart
// ✅ CORRECT - Direct client call (matches power management)
Future<void> flyToMumbai() async {
  final kmlPath = '/var/www/html/kml/master.kml';
  final escapedKml = mumbaiKml.replaceAll('"', '\\"').replaceAll('\$', '\\\$');
  
  // ALWAYS use _sshService.client!.run() for navigation
  await _sshService.client!.run('echo "$escapedKml" > $kmlPath');
  await Future.delayed(const Duration(seconds: 1));
  await _sshService.client!.run('echo "playtour=Mumbai" > /tmp/query.txt');
  
  debugPrint('Flying to Mumbai');
}
```

### Why Direct Client Call Works

| Method | Waits? | Overhead? | Works? |
|--------|--------|-----------|--------|
| `execute()` | ❌ No | None | ❌ No |
| `_sshService.run()` | ✅ Yes | UTF-8 decoding | ⚠️ Sometimes |
| `_sshService.client!.run()` | ✅ Yes | None | ✅ Yes - PRODUCTION |

**Why _sshService.client!.run() is best:**
- Direct access to SSH client - zero wrapper overhead
- Guaranteed waits for full command execution
- Matches power management pattern (shutdown/reboot/relaunch)
- Proven in production - tested and confirmed working
- Reliable for file operations with dependencies

**GOLDEN RULE FOR NAVIGATION:** Always use:
```dart
await _sshService.client!.run(command);
```

This is the reference implementation pattern. Use it for:
- KML file uploads
- Tour playback triggers  
- All navigation/flying functions
- Any operation where the next step depends on completion

## Checklist: Am I Doing These Wrong?

- [ ] Do I have a timeout on connect?
- [ ] Do I check isConnected before execute?
- [ ] Are credentials hard-coded?
- [ ] Do I handle all exceptions?
- [ ] Does UI freeze during connect?
- [ ] Do I disconnect on app close?
- [ ] Are passwords stored in variables?
- [ ] Do I validate user input?
- [ ] Do I retry infinitely?
- [ ] Is logic mixed with UI?
- [ ] Am I using execute() when I should use run()?
- [ ] Am I using const when I need final for interpolation?
- [ ] Am I calling wrapper methods when I should call client directly?
- [ ] Am I using execute() for KML uploads in navigation?
- [ ] Am I using execute() for logo KML uploads?

If you checked more than 2 boxes, refactor immediately.

## Mistake #16: Using execute() for Logo Service KML Uploads

### The Problem
LogoService uses `execute()` which returns immediately without waiting for the KML file to be written. This causes logos to fail uploading silently.

### ❌ Bad Pattern:
```dart
// WRONG - execute() doesn't wait for file write
Future<bool> sendLogo(String imageUrl, int screen) async {
  final escapedKml = kml.replaceAll('"', '\\"').replaceAll('\$', '\\\$');
  
  // Race condition: File write may not complete
  await _sshService.execute('echo "$escapedKml" > /var/www/html/kml/slave_$screen.kml');
  await _forceRefreshSlave(screen, 'slave_$screen.kml'); // May run before file written!
  
  return true; // Returns immediately, file still writing
}
```

**Symptoms:**
- Send Logo button appears to work but logo never appears
- Clear Logo button fails silently
- No error messages shown

### ✅ CORRECT Pattern:
```dart
// CORRECT - Direct client call (matches all other KML operations)
Future<bool> sendLogo(String imageUrl, int screen) async {
  try {
    final client = _sshService.client;
    if (client == null || client.isClosed) {
      debugPrint('SendLogo failed: SSH not connected');
      return false;
    }

    final kmlPath = '/var/www/html/kml/slave_$screen.kml';
    final escapedKml = kml.replaceAll('"', '\\"').replaceAll('\$', '\\\$');
    
    // ALWAYS use client!.run() for KML file operations
    await client.run('echo "$escapedKml" > $kmlPath');
    
    // Now safe: file is guaranteed written
    await _forceRefreshSlave(screen, 'slave_$screen.kml');
    
    return true;
  } catch (e) {
    debugPrint('SendLogo failed: $e');
    return false;
  }
}
```

### Apply to Both Methods
- `sendLogo()` - Uses execute, needs client!.run()
- `clearLogos()` - Uses execute, needs client!.run()

**All KML file operations must use `_sshService.client!.run()`**

## Key Rules

✅ **Always timeout**  
✅ **Always check connected**  
✅ **Always handle errors**  
✅ **Never hard-code credentials**  
✅ **Never block UI thread**  
✅ **Always cleanup resources**  
✅ **Never store passwords in memory**  
✅ **Always validate input**  
✅ **Always use async/await**  
✅ **Always separate logic from UI**  
✅ **Use client!.run() for all KML operations (flying, tours, logos)**  

## Next Steps

- Review [SSH Communication](../01-core-patterns/ssh-communication.md)
- Check [SSH Connection Issues](../07-troubleshooting/ssh-connection-issues.md)
- Read [Quality Checklist](../06-quality-standards/code-review-checklist.md)

---

**Rule of Thumb**: If SSH code can freeze the app, UI will freeze the app. Test with real network latency.
