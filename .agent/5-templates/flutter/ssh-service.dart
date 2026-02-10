import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';

/// SSH Service for Liquid Galaxy communication
///
/// Handles all SSH connections and command execution.
/// Always use timeouts and proper error handling.
///
/// Example:
/// ```dart
/// final ssh = SSHService();
/// final success = await ssh.connect(
///   host: '192.168.1.100',
///   username: 'lg',
///   password: 'lg',
/// );
/// if (success) {
///   await ssh.execute('ls /home/lg');
/// }
/// ```
class SSHService {
  SSHClient? _client;
  bool _isDisposed = false;

  /// Check if currently connected
  bool get isConnected => _client != null && !_isDisposed;

  /// Connect to SSH server
  ///
  /// Always specify timeout to prevent hanging.
  /// Returns true if successful, false otherwise.
  Future<bool> connect({
    required String host,
    required String username,
    required String password,
    int port = 22,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (_isDisposed) {
      debugPrint('❌ Service is disposed');
      return false;
    }

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

  /// Disconnect from SSH server
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

  /// Execute command and return output
  ///
  /// Throws exception if not connected.
  /// Always check isConnected before calling.
  Future<String> execute(String command) async {
    if (!isConnected) {
      throw Exception('SSH not connected');
    }

    try {
      debugPrint('🚀 Executing: $command');
      final result = await _client!.run(command);
      debugPrint('✅ Result: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Execution failed: $e');
      rethrow;
    }
  }

  /// Cleanup resources
  void dispose() {
    _isDisposed = true;
    _client?.close();
  }
}
