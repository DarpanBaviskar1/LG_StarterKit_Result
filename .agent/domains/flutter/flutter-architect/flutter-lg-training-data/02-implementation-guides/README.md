---
title: Implementation Guides Overview
folder: 02-implementation-guides
tags: [overview, guides, tutorials, step-by-step]
---

# Implementation Guides 🚀

Step-by-step walkthroughs for building real features.

## What's Inside

Complete examples with code for common LG app features.

### Files

1. **[Building a Connection Feature](connection-feature.md)** (15 min)
   - Create connection models
   - Build SSH service
   - Setup Riverpod providers
   - Build UI form and status widgets
   - Wire everything together

2. **[Implementing Fly-To Navigation](fly-to-location.md)** (12 min)
   - Create Location model
   - Build KML flyTo commands
   - Setup LG service
   - Create navigation provider
   - Build location cards and screen

### Planned Files

3. **Tour Feature** (coming soon)
   - Multi-point animation tours
   - Tour playback and control
   - User-defined tour creation

4. **Data Visualization** (coming soon)
   - Displaying data on LG map
   - Real-time data updates
   - Performance optimization

## How to Use These Guides

### Step 1: Read Through
- Understand the overall structure
- See how components fit together
- Copy code snippets

### Step 2: Copy Files
- Create folder structure shown
- Copy code into files
- Follow naming conventions

### Step 3: Test
- Connect to real LG device
- Test each step
- Check logs for errors

### Step 4: Customize
- Adapt code to your needs
- Add your own features
- Reference [Code Templates](../03-code-templates/)

## Feature Checklist

Before shipping your feature:

- [ ] Models created and tested
- [ ] Services implemented with error handling
- [ ] Providers setup correctly
- [ ] Widgets built and styled
- [ ] Screen integrated
- [ ] Tested on real LG device
- [ ] Error cases handled
- [ ] Loading states shown
- [ ] Used [Quality Checklist](../06-quality-standards/code-review-checklist.md)
- [ ] No [Anti-Patterns](../04-anti-patterns/) found

## Common Patterns Across Guides

### Folder Structure
```
lib/src/features/feature_name/
├── models/
├── providers/
├── screens/
└── widgets/
```

### Provider Pattern
```dart
// Service provider
final serviceProvider = Provider(...);

// State notifier
class FeatureNotifier extends StateNotifier<FeatureState> { ... }

// Feature provider
final featureProvider = StateNotifierProvider(...);
```

### Error Handling
```dart
try {
  // Do thing
  state = state.copyWith(isLoading: true);
  await action();
  state = state.copyWith(success: true);
} catch (e) {
  state = state.copyWith(errorMessage: e.toString());
}
```

### UI Pattern
```dart
class FeatureWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(featureProvider);
    
    return state.isLoading
        ? LoadingWidget()
        : state.errorMessage != null
            ? ErrorWidget(state.errorMessage)
            : SuccessWidget();
  }
}
```

## Learning Paths

### First LG App
1. Follow [Connection Feature](connection-feature.md)
2. Then [Fly-To Navigation](fly-to-location.md)
3. You now have a working app!

### Add More Features
1. Pick feature you want
2. Follow corresponding guide
3. Reference [Code Templates](../03-code-templates/)
4. Check [Anti-Patterns](../04-anti-patterns/) to avoid mistakes

### Need More Help?
- [SSH Communication](../01-core-patterns/ssh-communication.md) - Connection details
- [KML Management](../01-core-patterns/kml-management.md) - Navigation details
- [State Management](../01-core-patterns/state-management.md) - Riverpod patterns
- [Troubleshooting](../07-troubleshooting/) - Fix problems

## Next Steps

1. Choose feature you want to build
2. Open corresponding implementation guide
3. Follow step-by-step instructions
4. Copy code snippets
5. Test on real LG device
6. Reference other docs as needed

---

**Rule of Thumb**: These guides teach by doing. Follow them, don't just read them.
