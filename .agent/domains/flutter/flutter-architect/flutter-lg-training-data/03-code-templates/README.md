---
title: Code Templates Overview
folder: 03-code-templates
tags: [overview, templates, copy-paste, ready-to-use]
---

# Code Templates 📝

Copy-paste ready code for common patterns.

## What's Inside

Production-ready code snippets you can use directly in your app.

### Files

1. **[ssh-service.dart](ssh-service.dart)**
   - Complete SSHService class
   - Connection management
   - Command execution
   - Error handling

2. **[kml-builder.dart](kml-builder.dart)**
   - KML generation functions
   - FlyTo, Placemark, Tour builders
   - Coordinate validation
   - XML escaping

3. **[connection-provider.dart](connection-provider.dart)**
   - ConnectionNotifier class
   - Connection state management
   - Riverpod provider setup
   - Execute command helper

4. **[connection-form.dart](connection-form.dart)**
   - ConnectionForm widget
   - Input validation
   - Loading state UI
   - Error display

5. **[lg-service.dart](lg-service.dart)**
   - LGService class
   - High-level LG commands
   - KML sending
   - Cleanup/dispose

## How to Use

### Copy & Paste
1. Open template file
2. Copy entire content
3. Create file in your project
4. Paste code
5. Adjust imports if needed

### Customize
- Update package names
- Adjust timeouts
- Add missing error handling
- Extend with more features

### Example

```dart
// 1. Copy ssh-service.dart to lib/src/services/
// 2. Copy connection-provider.dart to lib/src/features/connection/providers/
// 3. Copy connection-form.dart to lib/src/features/connection/widgets/
// 4. Update imports in files
// 5. Use in your app!
```

## What Each File Provides

### SSHService
- Connect to Liquid Galaxy
- Execute commands
- Handle timeouts
- Cleanup resources

**When to use**: When you need direct SSH access

### KMLBuilder
- Generate FlyTo KML
- Generate Placemark KML
- Generate Tour KML
- Validate coordinates

**When to use**: When generating KML commands

### ConnectionProvider
- Global connection state
- ConnectionNotifier for state management
- SSH service integration
- Execute commands on connected LG

**When to use**: When you need global connection state

### ConnectionForm
- UI for entering credentials
- Form validation
- Loading indicator
- Error display

**When to use**: When building login/connection screen

### LGService
- High-level LG commands
- FlyTo command
- Service cleanup

**When to use**: When you want simplified LG interface

## Template Usage Pattern

```
SSHService (low-level)
    ↓
LGService (mid-level)
    ↓
ConnectionProvider (state management)
    ↓
Widgets (UI)
```

## Layering

### Layer 1: Services
```
SSHService → SSH connection + commands
LGService → High-level LG operations
```

### Layer 2: State
```
ConnectionProvider → Global state management
```

### Layer 3: UI
```
ConnectionForm → User input
Widgets → Display state
```

## Customization Examples

### Change Default Port
```dart
// In ssh-service.dart
static const int SSH_PORT = 22; // Change here
```

### Change Default Credentials
```dart
// In connection-form.dart
_userController = TextEditingController(text: 'your-user');
_passController = TextEditingController(text: 'your-pass');
```

### Add Command Logging
```dart
// In ssh-service.dart
Future<String> execute(String command) async {
  debugPrint('>>> $command');
  final result = await _client!.run(command);
  debugPrint('<<< $result');
  return result;
}
```

## Testing Templates

Use templates in unit/widget tests:

```dart
test('SSHService can connect', () async {
  final ssh = SSHService();
  final success = await ssh.connect(
    host: '192.168.1.100',
    username: 'lg',
    password: 'lg',
  );
  expect(success, true);
  await ssh.disconnect();
});

test('KMLBuilder generates valid KML', () {
  final kml = KMLBuilder.buildFlyTo(
    latitude: 40.6892,
    longitude: -74.0445,
    altitude: 0,
  );
  expect(kml.contains('<?xml'), true);
  expect(kml.contains('<kml'), true);
});
```

## Next Steps

1. Copy templates to your project
2. Update imports
3. Customize as needed
4. Reference [Implementation Guides](../02-implementation-guides/) for examples
5. Check [Anti-Patterns](../04-anti-patterns/) to avoid mistakes

---

**Rule of Thumb**: These templates are battle-tested. Use them as-is first, customize second.
