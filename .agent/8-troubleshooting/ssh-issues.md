---
title: SSH Connection Issues & Debugging
folder: 07-troubleshooting
tags: [troubleshooting, ssh, debugging, connection]
related:
  - ../01-core-patterns/ssh-communication.md
  - ../04-anti-patterns/ssh-mistakes.md
difficulty: intermediate
time-to-read: 10 min
---

# SSH Connection Troubleshooting 🔧

Debug SSH connection problems systematically.

## Connection Timeout

**Symptom**: App hangs, eventually times out

**Check List**:
1. Is LG at the right IP?
   ```bash
   ping 192.168.1.100
   ```

2. Is SSH port open?
   ```bash
   telnet 192.168.1.100 22
   ```

3. Is network reachable?
   - Same WiFi network?
   - No firewall blocking?
   - VPN not active?

4. Debug code:
   ```dart
   final start = DateTime.now();
   try {
     await _ssh.connect(
       host: '192.168.1.100',
       port: 22,
       timeout: Duration(seconds: 5),
     );
     debugPrint('⏱️ Took ${DateTime.now().difference(start)}');
   } catch (e) {
     debugPrint('❌ Timed out: $e');
   }
   ```

**Solutions**:
- ✅ Check IP address is correct
- ✅ Verify LG is powered on
- ✅ Check network is connected
- ✅ Increase timeout for slow networks
- ✅ Try with `telnet` from command line first

## Authentication Failed

**Symptom**: "Authentication failed" or "Permission denied"

**Check List**:
1. Is username correct?
   - Default LG user: `lg`
   - Not `root`

2. Is password correct?
   - Default LG password: `lg`
   - Check for typos

3. Are credentials in right order?
   ```dart
   // GOOD order
   await ssh.connect(
     host: host,
     username: username, // 'lg'
     password: password, // 'lg'
   );
   ```

4. Debug with prints:
   ```dart
   debugPrint('📋 Connecting:');
   debugPrint('  Host: $host');
   debugPrint('  User: $username');
   debugPrint('  Pass: ${'*' * password.length}');
   ```

**Solutions**:
- ✅ Try default credentials: `lg`/`lg`
- ✅ Verify username is not reversed with password
- ✅ Test via SSH command line
- ✅ Check user account exists on LG

## Connection Refused

**Symptom**: "Connection refused" immediately

**Causes**:
1. SSH service not running on LG
2. LG just booted (needs 1-2 minutes)
3. Wrong port (usually 22)

**Solutions**:
1. Wait 2 minutes after LG boot
2. SSH from terminal to verify:
   ```bash
   ssh lg@192.168.1.100
   ```
3. Check LG is fully booted (web interface responsive)

## Host Not Found / Network Unreachable

**Symptom**: "Host not found" or "Network unreachable"

**Debug**:
```dart
import 'dart:io';

// Test DNS resolution
try {
  final result = await InternetAddress.lookup('192.168.1.100');
  if (result.isNotEmpty) {
    debugPrint('✅ Host found');
  }
} catch (e) {
  debugPrint('❌ DNS failed: $e');
}

// Test network
final socket = await Socket.connect('192.168.1.100', 22,
  timeout: Duration(seconds: 5),
);
socket.close();
```

**Solutions**:
- ✅ Check spelling of IP
- ✅ Verify connected to right network
- ✅ Check firewall rules
- ✅ Try with full IP, not hostname

## Connection Keeps Dropping

**Symptom**: Connected fine, then disconnects randomly

**Causes**:
1. Network is unstable
2. LG goes to sleep
3. SSH timeout too short
4. Not re-connecting after drop

**Solutions**:
```dart
// 1. Increase timeout
await ssh.connect(
  timeout: Duration(seconds: 20), // was 10
);

// 2. Add reconnect logic
Future<void> ensureConnected() async {
  if (!ssh.isConnected) {
    await connect();
  }
}

// 3. Wrap commands in reconnect
Future<String> executeWithReconnect(String cmd) async {
  try {
    return await ssh.execute(cmd);
  } catch (e) {
    // Connection lost, try reconnecting
    await connect();
    return await ssh.execute(cmd);
  }
}

// 4. Disable SSH timeout on LG
// Or keep connection alive with periodic commands
```

## Connection Works, But Commands Fail

**Symptom**: Connected successfully, but `execute()` fails

**Debug**:
```dart
// Test if command is valid
final result = await ssh.execute('echo "Hello"');
debugPrint('Result: $result');

// Test with simpler command
await ssh.execute('ls'); // Should work

// Test with actual LG command
await ssh.execute('echo "http://localhost" > /tmp/query.txt');
```

**Solutions**:
- ✅ Check command syntax (especially quotes)
- ✅ Check file paths exist
- ✅ Try command manually via SSH client
- ✅ Check file permissions

## GUI/Riverpod Connection State Wrong

**Symptom**: UI says connected but it's not, or vice versa

**Debug**:
```dart
// Check actual connection vs state
final state = ref.watch(connectionProvider);
final isActuallyConnected = ssh.isConnected;

debugPrint('State says: ${state.isConnected}');
debugPrint('Actually is: $isActuallyConnected');

if (state.isConnected != isActuallyConnected) {
  debugPrint('❌ STATE MISMATCH');
}
```

**Causes**:
1. Exception thrown but state not updated
2. Connection lost but state not updated
3. Multiple SSH services

**Solutions**:
```dart
// 1. Wrap all commands in try/catch
Future<void> connect(config) async {
  state = state.copyWith(isConnecting: true);
  try {
    final success = await _ssh.connect(...);
    state = state.copyWith(isConnected: success);
  } catch (e) {
    state = state.copyWith(isConnected: false, errorMessage: e.toString());
  } finally {
    state = state.copyWith(isConnecting: false);
  }
}

// 2. Check actual connection on app resume
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    // Re-verify connection is still alive
    if (ref.read(connectionProvider).isConnected) {
      ref.read(connectionProvider.notifier).verify();
    }
  }
}
```

## Memory Leak / Connection Leak

**Symptom**: App uses more memory over time, multiple connections open

**Solutions**:
```dart
// 1. Disconnect on app exit
@override
void dispose() {
  ref.read(connectionProvider.notifier).disconnect();
  super.dispose();
}

// 2. Use onDispose in provider
final sshProvider = Provider((ref) {
  final ssh = SSHService();
  ref.onDispose(() {
    ssh.disconnect();
  });
  return ssh;
});

// 3. Monitor connection count
// Via SSH: ss -tln | grep 22
```

## Quick Debugging Flowchart

```
❌ Connection fails?
├─ 🔌 Can you ping the IP?
│  ├─ No → Network issue, check WiFi
│  └─ Yes → Continue
├─ 🔓 SSH service running?
│  ├─ Use: telnet 192.168.1.100 22
│  ├─ No → Wait for LG to boot
│  └─ Yes → Continue
├─ 🔑 Correct credentials?
│  ├─ Try: ssh lg@192.168.1.100
│  ├─ No → Fix credentials
│  └─ Yes → Bug in code
└─ 💻 Code issue?
   ├─ Check timeout value
   ├─ Check error handling
   ├─ Check for mutations
   └─ File bug report with logs
```

## Testing Checklist

- [ ] Test with real LG device (not emulator)
- [ ] Test on slow network (WiFi)
- [ ] Test after LG reboot
- [ ] Test with wrong credentials
- [ ] Test with LG powered off
- [ ] Test reconnect after disconnect
- [ ] Test commands in terminal first
- [ ] Check connection after app pause/resume

## Next Steps

- Review [SSH Communication](../01-core-patterns/ssh-communication.md)
- Check [SSH Mistakes](../04-anti-patterns/ssh-mistakes.md)
- Read [SSH Code Template](../03-code-templates/ssh-service.dart)

---

**Rule of Thumb**: If network works in terminal, but fails in app, it's a timeout, error handling, or threading issue.
