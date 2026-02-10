import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connection Form Widget
///
/// Provides UI for users to enter Liquid Galaxy credentials.
/// Handles form validation and submission.
///
/// Usage:
/// ```dart
/// ConnectionForm(
///   onConnected: () {
///     // Navigate to next screen
///   },
/// )
/// ```
class ConnectionForm extends ConsumerStatefulWidget {
  final VoidCallback? onConnected;

  const ConnectionForm({this.onConnected});

  @override
  ConsumerState<ConnectionForm> createState() => _ConnectionFormState();
}

class _ConnectionFormState extends ConsumerState<ConnectionForm> {
  late TextEditingController _hostController;
  late TextEditingController _userController;
  late TextEditingController _passController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _hostController = TextEditingController();
    _userController = TextEditingController(text: 'lg');
    _passController = TextEditingController(text: 'lg');
  }

  @override
  void dispose() {
    _hostController.dispose();
    _userController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch connection state
    final state = ref.watch(connectionProvider);

    return Form(
      key: _formKey,
      child: Column(
        spacing: 16,
        children: [
          // IP Address input
          TextFormField(
            controller: _hostController,
            decoration: InputDecoration(
              labelText: 'Liquid Galaxy IP',
              hintText: '192.168.1.100',
              prefixIcon: Icon(Icons.router),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return 'Please enter IP address';
              }
              return null;
            },
            enabled: !state.isConnecting,
          ),

          // Username input
          TextFormField(
            controller: _userController,
            decoration: InputDecoration(
              labelText: 'Username',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(),
            ),
            enabled: !state.isConnecting,
          ),

          // Password input
          TextFormField(
            controller: _passController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock),
              border: OutlineInputBorder(),
            ),
            enabled: !state.isConnecting,
          ),

          // Connect button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: state.isConnecting ? null : _handleConnect,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
              ),
              child: state.isConnecting
                  ? SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text('Connect'),
            ),
          ),

          // Error message
          if (state.errorMessage != null)
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red),
              ),
              child: Row(
                spacing: 8,
                children: [
                  Icon(Icons.error, color: Colors.red),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _handleConnect() async {
    if (!_formKey.currentState!.validate()) return;

    final config = ConnectionConfig(
      host: _hostController.text,
      username: _userController.text,
      password: _passController.text,
    );

    await ref.read(connectionProvider.notifier).connect(config);

    if (mounted && ref.read(connectionProvider).isConnected) {
      widget.onConnected?.call();
    }
  }
}
