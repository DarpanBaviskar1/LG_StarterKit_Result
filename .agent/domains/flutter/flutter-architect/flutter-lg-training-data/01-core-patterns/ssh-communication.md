---
title: SSH Communication Pattern
folder: 01-core-patterns
tags: [ssh, connection, dartssh2, networking]
related:
  - ../02-implementation-guides/connection-feature.md
  - ../03-code-templates/ssh-service.dart
  - ../07-troubleshooting/ssh-connection-issues.md
  - ../04-anti-patterns/ssh-mistakes.md
difficulty: intermediate
time-to-read: 10 min
---

# SSH Communication Pattern 🔐

All Flutter + Liquid Galaxy apps communicate through SSH. Understanding this pattern is fundamental.

## Why SSH?

LG runs commands through SSH on the Master machine:
- Send KML files
- Control screens
- Relaunch services
- Get system information
- Monitor status

**No SSH = No LG Control**

## The Core Pattern

```dart
import 'package:dartssh2/dartssh2.dart';
import 'dart:convert';

class SSHService {
  SSHClient? _client;
  bool _isConnected = false;
  
  bool get isConnected => _isConnected;
  
  /// Connect to LG Master
  Future<bool> connect({
    required String host,
    required String username,
    required String password,
    int port = 22,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    try {
      // Create socket with timeout
      final socket = await SSHSocket.connect(host, port, 
        timeout: timeout);
      
      // Create SSH client
      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );
      
      // Test connection
      await _client!.run('echo "test"');
      
      _isConnected = true;
      return true;
    } catch (e) {
      debugPrint('SSH Connect Error: $e');
      _isConnected = false;
      return false;
    }
  }
  
  /// Execute command on LG
  Future<String?> execute(String command) async {
    if (!isConnected || _client == null) {
      debugPrint('Not connected to SSH');
      return null;
    }
    
    try {
      final result = await _client!.run(command);
      return utf8.decode(result);
    } catch (e) {
      debugPrint('SSH Execute Error: $e');
      return null;
    }
  }
  
  /// Disconnect gracefully
  Future<void> disconnect() async {
    try {
      _client?.close();
      await _client?.done;
    } catch (e) {
      debugPrint('SSH Disconnect Error: $e');
    } finally {
      _client = null;
      _isConnected = false;
    }
  }
}
```

## Key Points

### 1. **Always Use Timeout**
```dart
// ✅ GOOD - Won't hang forever
final socket = await SSHSocket.connect(host, port,
  timeout: const Duration(seconds: 10));

// ❌ BAD - Can hang forever if network fails
final socket = await SSHSocket.connect(host, port);
```

### 2. **Check Connection Before Commands**
```dart
// ✅ GOOD
if (!isConnected) {
  return 'Not connected';
}
await execute(command);

// ❌ BAD - Will crash or fail silently
await execute(command);
```

### 3. **Use debugPrint Not print**
```dart
// ✅ GOOD - Only in debug builds
debugPrint('SSH Error: $e');

// ❌ BAD - Shows in release builds
print('SSH Error: $e');
```

### 4. **Handle All Error Cases**
```dart
// ✅ GOOD
try {
  await connect(...);
} on SocketException catch (e) {
  // Network error
} on TimeoutException catch (e) {
  // Connection timed out
} catch (e) {
  // Other errors
}

// ❌ BAD - Ignores errors
await connect(...);
```

### 5. **Clean Up Properly**
```dart
// ✅ GOOD
Future<void> disconnect() async {
  try {
    _client?.close();
    await _client?.done;
  } finally {
    _client = null;
  }
}

// ❌ BAD - Leaves connection open
void disconnect() {
  _client = null;
}
```

## Common SSH Commands for LG

```dart
// Get system info
await execute('cat /etc/hostname');

// Control screens
await execute('pkill chromium');
await execute('lg-relaunch');

// Send KML files
await execute('echo "$kmlContent" > /var/www/html/kml/file.kml');

// Check LG status
await execute('cat /tmp/query.txt');

// Reboot LG
await execute('sudo reboot');
```

## Integration with Riverpod

```dart
// Make it a provider
final sshServiceProvider = Provider<SSHService>((ref) {
  return SSHService();
});

// Use in another service
class LGService {
  final SSHService _ssh;
  
  LGService(this._ssh);
  
  Future<bool> relaunch() async {
    if (!_ssh.isConnected) return false;
    final result = await _ssh.execute('lg-relaunch');
    return result != null;
  }
}

// Provide dependencies
final lgServiceProvider = Provider<LGService>((ref) {
  final ssh = ref.watch(sshServiceProvider);
  return LGService(ssh);
});
```

## Testing Connection

Always test before relying on connection:

```dart
Future<bool> testConnection({
  required String host,
  required String username,
  required String password,
}) async {
  final ssh = SSHService();
  
  // Try to connect
  final connected = await ssh.connect(
    host: host,
    username: username,
    password: password,
  );
  
  if (!connected) {
    return false;
  }
  
  // Try a simple command
  final result = await ssh.execute('echo "test"');
  
  // Clean up
  await ssh.disconnect();
  
  return result != null;
}
```

## Common Issues

**Connection hangs?**
→ Check timeout is set  
→ Verify IP/port correct  
→ Check firewall

**"Not connected" errors?**
→ Test connection first  
→ Check isConnected before execute  
→ Handle reconnection

**SSH throws exception?**
→ Check error type (socket vs timeout)  
→ Provide user-friendly message  
→ Log with debugPrint

See `07-troubleshooting/ssh-connection-issues.md` for detailed debugging.

## Next Steps

- Read `02-implementation-guides/connection-feature.md` for step-by-step
- Copy `03-code-templates/ssh-service.dart` for ready-made code
- Check `04-anti-patterns/ssh-mistakes.md` for what NOT to do
- Use `06-quality-standards/code-review-checklist.md` before shipping

---

**Rule of Thumb**: SSH is critical infrastructure. Always add error handling, timeouts, and connection checks. Test thoroughly.
