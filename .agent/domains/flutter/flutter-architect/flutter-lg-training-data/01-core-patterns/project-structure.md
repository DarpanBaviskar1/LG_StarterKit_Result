---
title: Project Structure (Feature-First)
folder: 01-core-patterns
tags: [architecture, folder-structure, organization]
related:
  - ../02-implementation-guides/
  - ../flutter-architect/folder-structures.md
difficulty: beginner
time-to-read: 8 min
---

# Project Structure: Feature-First Organization 📁

Good structure = easier development. Bad structure = debugging nightmare.

## Why Feature-First?

**Feature-First**: Group by feature
```
lib/src/features/
├── connection/    ← All connection-related code
├── dashboard/     ← All dashboard-related code
└── settings/      ← All settings-related code
```

**Type-First** (Don't do this):
```
lib/
├── models/        ← All models everywhere
├── screens/       ← All screens everywhere
├── services/      ← All services everywhere
```

**Why feature-first is better:**
- ✅ Related code stays together
- ✅ Easy to find what you need
- ✅ Easy to delete entire feature
- ✅ Easy to reuse between projects
- ✅ Scales as project grows

## Complete Structure

```
lib/
├── main.dart                           # App entry point
├── app.dart                            # MaterialApp setup
│
└── src/
    ├── features/
    │   ├── connection/
    │   │   ├── models/
    │   │   │   └── connection_config.dart
    │   │   ├── providers/
    │   │   │   ├── connection_provider.dart
    │   │   │   └── ssh_provider.dart
    │   │   ├── screens/
    │   │   │   └── connection_screen.dart
    │   │   └── widgets/
    │   │       ├── connection_form.dart
    │   │       └── connection_status.dart
    │   │
    │   ├── dashboard/
    │   │   ├── models/
    │   │   ├── providers/
    │   │   ├── screens/
    │   │   │   └── dashboard_screen.dart
    │   │   └── widgets/
    │   │       ├── location_card.dart
    │   │       └── control_panel.dart
    │   │
    │   └── settings/
    │       ├── models/
    │       ├── providers/
    │       ├── screens/
    │       └── widgets/
    │
    ├── services/                       # Shared services
    │   ├── ssh_service.dart
    │   ├── lg_service.dart
    │   └── storage_service.dart
    │
    ├── utils/                          # Utilities
    │   ├── kml/
    │   │   ├── kml_builder.dart
    │   │   └── kml_validator.dart
    │   ├── helpers/
    │   └── extensions.dart
    │
    ├── constants/
    │   ├── app_constants.dart
    │   └── lg_constants.dart
    │
    ├── models/                         # Shared models
    │   └── lg_config.dart
    │
    ├── widgets/                        # Shared widgets
    │   └── custom_app_bar.dart
    │
    └── theme/                          # Theming
        └── app_theme.dart
```

## What Goes Where?

### Features/ Folder

Each feature (connection, dashboard, etc) contains:

**models/** - Data classes
```dart
// connection/models/connection_config.dart
class ConnectionConfig {
  final String host;
  final String username;
  final String password;
  
  const ConnectionConfig({...});
}
```

**providers/** - Riverpod providers
```dart
// connection/providers/connection_provider.dart
final connectionProvider = StateNotifierProvider<...>(...);
```

**screens/** - Full pages
```dart
// connection/screens/connection_screen.dart
class ConnectionScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) { ... }
}
```

**widgets/** - Reusable UI components
```dart
// connection/widgets/connection_form.dart
class ConnectionForm extends StatefulWidget {
  @override
  State<ConnectionForm> createState() => _ConnectionFormState();
}
```

### Services/ Folder

Shared across features:
```dart
// ssh_service.dart
class SSHService { ... }

// lg_service.dart
class LGService { ... }

// storage_service.dart
class StorageService { ... }
```

### Utils/ Folder

Helper functions and utilities:
```dart
// kml/kml_builder.dart
class KMLBuilder {
  static String buildFlyTo(...) { ... }
}

// helpers/validators.dart
class Validators {
  static bool isValidIP(String ip) { ... }
}
```

### Constants/ Folder

App-wide constants:
```dart
// app_constants.dart
class AppConstants {
  static const String appName = 'LG Controller';
  static const Duration defaultTimeout = Duration(seconds: 10);
}

// lg_constants.dart
class LGConstants {
  static const int screenCount = 3;
  static const String masterHost = '192.168.1.100';
}
```

## Naming Conventions

### Files
- Use snake_case: `connection_screen.dart`
- Match class name: `ConnectionScreen` in `connection_screen.dart`
- Keep names descriptive: `ssh_service.dart` not `service.dart`

### Classes
- Use PascalCase: `class ConnectionScreen { }`
- Use suffix for type:
  - Screens: `ConnectionScreen`
  - Widgets: `ConnectionForm`
  - Services: `SSHService`
  - Providers: Use final variable names
  - Models: `ConnectionConfig`

### Variables
- Use camelCase: `var connectionConfig = ...`
- Private with underscore: `var _privateValue`
- Constants: `const String appName = ...`

## Imports Pattern

```dart
// 1. Dart imports
import 'dart:convert';
import 'dart:async';

// 2. Package imports
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 3. Relative imports
import '../models/connection_config.dart';
import '../providers/ssh_provider.dart';
```

## Feature Isolation

Each feature should be semi-independent:

```dart
// connection_screen.dart - GOOD (isolated)
class ConnectionScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only uses connection providers
    final state = ref.watch(connectionProvider);
    return ...
  }
}

// dashboard_screen.dart - BAD (too dependent)
class DashboardScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Uses connection, settings, and ui providers
    // Too tightly coupled
    final connection = ref.watch(connectionProvider);
    final settings = ref.watch(settingsProvider);
    final ui = ref.watch(uiProvider);
    return ...
  }
}
```

## Adding New Feature

When adding a new feature, create:

```
lib/src/features/my_feature/
├── models/
│   └── my_model.dart
├── providers/
│   └── my_provider.dart
├── screens/
│   └── my_screen.dart
└── widgets/
    └── my_widget.dart
```

Then:
1. Create `models/`
2. Create `providers/` (use models)
3. Create `widgets/` (use providers)
4. Create `screens/` (use widgets)

## Avoiding Common Mistakes

### ❌ Don't put everything in lib/
```dart
// BAD - Flat structure
lib/
├── main.dart
├── connection_screen.dart
├── dashboard_screen.dart
├── settings_screen.dart
├── ssh_service.dart
├── lg_service.dart
└── storage_service.dart
```

### ❌ Don't duplicate code across features
```dart
// BAD - Same widget in multiple features
connection/widgets/status_indicator.dart
dashboard/widgets/status_indicator.dart
settings/widgets/status_indicator.dart

// GOOD - Shared widget
widgets/status_indicator.dart
```

### ❌ Don't create god classes
```dart
// BAD - One file with everything
class LGController {
  // SSH code
  // KML code
  // Storage code
  // UI logic
  // State management
}

// GOOD - Separated concerns
class SSHService { ... }
class KMLBuilder { ... }
class StorageService { ... }
class LGService { ... }
```

### ❌ Don't import across feature hierarchy
```dart
// BAD - Circular dependency
dashboard/screens/dashboard_screen.dart
  imports from settings/providers/settings_provider.dart
settings/screens/settings_screen.dart
  imports from dashboard/providers/dashboard_provider.dart

// GOOD - Share through root providers
both import from services/ or utils/
```

## Best Practices

✅ Keep features focused  
✅ Share code in services/ or utils/  
✅ Use providers for all state  
✅ Organize by feature not type  
✅ One public class per file  
✅ Use consistent naming  
✅ Import in order (dart, packages, relative)  
✅ Private with underscore  

## Scaling Example

As project grows, break features further:

```
connection/
├── data/
│   ├── models/
│   └── repositories/
├── domain/
│   └── usecases/
└── presentation/
    ├── providers/
    ├── screens/
    └── widgets/
```

This is **clean architecture** - ideal for large apps.

## Next Steps

- Reference this structure when creating new features
- Use as template for other LG apps
- Adapt to team standards if needed
- Keep it consistent across project

---

**Rule of Thumb**: Structure follows features. If you delete a feature, delete one folder. If you can't, the structure is wrong.
