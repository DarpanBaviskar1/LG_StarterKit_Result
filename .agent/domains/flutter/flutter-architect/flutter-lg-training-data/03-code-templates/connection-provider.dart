```dart
/// IMPORTANT: This template uses Riverpod 3.x with the new Notifier API
/// For Riverpod 2.x, use StateNotifier instead
/// https://riverpod.dev/docs/migration/v3_introduction
import '../features/connection/models/connection_state.dart';
import '../features/connection/models/connection_config.dart';
import '../services/ssh_service.dart';

/// SSH Service Provider
///
/// Singleton instance of SSH service.
/// Use this provider when you need to execute SSH commands directly.
///
/// Example:
/// ```dart
/// final ssh = ref.watch(sshServiceProvider);
/// final result = await ssh.execute('ls');
/// ```
final sshServiceProvider = Provider<SSHService>((ref) {
  return SSHService();
});

/// Connection State Provider
///
/// Manages global connection state.
/// Use this to check if connected or to connect/disconnect.
///
/// Example:
/// ```dart
/// final state = ref.watch(connectionProvider);
/// if (state.isConnected) {
///   // User is connected
/// }
/// ```
///
/// ✅ CORRECT for Riverpod 3.x: Use Notifier (not StateNotifier)
/// ❌ WRONG for Riverpod 3.x: StateNotifier with StateNotifierProvider
class ConnectionNotifier extends Notifier<ConnectionState> {
  late final SSHService _ssh;

  @override
  ConnectionState build() {
    _ssh = ref.watch(sshServiceProvider);
    return const ConnectionState();
  }

  /// Connect to Liquid Galaxy
  Future<void> connect(ConnectionConfig config) async {
    state = state.copyWith(isConnecting: true, errorMessage: null);

    try {
      final success = await _ssh.connect(
        host: config.host,
        username: config.username,
        password: config.password,
        port: config.port,
        timeout: config.timeout,
      );

      if (success) {
        state = state.copyWith(
          isConnected: true,
          isConnecting: false,
          config: config,
        );
      } else {
        state = state.copyWith(
          isConnected: false,
          isConnecting: false,
          errorMessage: 'Connection failed',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isConnected: false,
        isConnecting: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Disconnect from Liquid Galaxy
  Future<void> disconnect() async {
    await _ssh.disconnect();
    state = const ConnectionState();
  }

  /// Execute command on connected LG
  Future<String> execute(String command) async {
    if (!state.isConnected) {
      throw Exception('Not connected to Liquid Galaxy');
    }
    return await _ssh.execute(command);
  }
}

/// Global connection provider
///
/// Use ref.watch(connectionProvider) to get connection state
/// Use ref.read(connectionProvider.notifier) to connect/disconnect
///
/// ✅ CORRECT for Riverpod 3.x: NotifierProvider (not StateNotifierProvider)
final connectionProvider = NotifierProvider<
    ConnectionNotifier,
    ConnectionState>(() {
  return ConnectionNotifier();
});

