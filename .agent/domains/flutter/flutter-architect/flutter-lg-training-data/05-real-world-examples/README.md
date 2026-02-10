---
title: Real-World Examples
folder: 05-real-world-examples
tags: [examples, patterns, real-projects, learning]
---

# Real-World Examples 🌍

Learn from open-source Liquid Galaxy projects.

## What's Inside

Examples extracted from real LG projects on GitHub.

### Recommended Projects

1. **[Eco-Explorer](https://github.com/LiquidGalaxyLAB/Eco-Explorer)**
   - Voice control integration
   - Real-time environmental data
   - Multi-screen coordination
   - Complex state management

2. **[LG Airport Controller Simulator](https://github.com/LiquidGalaxyLAB/LG-Airport-Controller-Simulator)**
   - Multi-feature app
   - Real-time simulations
   - Advanced KML generation
   - Performance optimization

3. **[Catastrophe Visualizer](https://github.com/LiquidGalaxyLAB/Catastrophe-Visualizer)**
   - Data visualization
   - Historical data playback
   - Complex queries
   - Real-time updates

4. **[Martian Climate Dashboard](https://github.com/LiquidGalaxyLAB/Martian-Climate-Dashboard)**
   - Multi-view dashboard
   - Large datasets
   - Custom graphics
   - Interactive controls

## How to Use

### Learn Architecture
1. Open real project on GitHub
2. Read project README
3. Understand feature structure
4. Note patterns used

### Copy Patterns
1. Find relevant section
2. Understand the approach
3. Adapt to your needs
4. Reference [Implementation Guides](../02-implementation-guides/)

### Study Code
1. Look for interesting patterns
2. Understand why designed this way
3. Recognize tradeoffs
4. Apply to your app

## Common Patterns Found

### State Management
- **Riverpod + StateNotifier**: Global state for connection
- **Nested providers**: Dependency injection
- **Async data**: FutureProvider for API calls

### Navigation
- **Feature-based routing**: Each feature has routes
- **Parameter passing**: Via provider selection
- **Deep linking**: Handled in routing layer

### Services
- **SSH wrapper**: High-level LG commands
- **Data service**: API and local storage
- **Location service**: GPS and coordinate handling

### UI
- **Responsive design**: ScreenUtil for sizing
- **Error states**: LoadingError widgets
- **Custom widgets**: Reusable components

## Project Comparisons

### Eco-Explorer vs Airport Simulator
| Aspect | Eco-Explorer | Airport Simulator |
|--------|-------------|-------------------|
| Features | 5-7 | 10+ |
| Complexity | Medium | High |
| Real-time | Yes | Yes |
| UI Polish | High | Medium |
| Code Examples | Voice control | Multi-feature |

### When to Reference Which

**Starting simple?**
→ Look at Eco-Explorer or Airport Simulator basic features

**Building voice control?**
→ Study Eco-Explorer voice implementation

**Complex simulation?**
→ Study Airport Simulator state management

**Data visualization?**
→ Study Catastrophe Visualizer or Martian Dashboard

## Open Source Learning

### Repository Structure
```
project/
├── lib/
│   └── src/
│       ├── features/
│       ├── services/
│       ├── models/
│       └── widgets/
├── pubspec.yaml
└── README.md
```

### Common Packages
- `flutter_riverpod` - State management
- `dartssh2` - SSH communication
- `google_fonts` - Typography
- `flutter_screenutil` - Responsive design
- `path_provider` - File access

### Common Architecture
```
SSH Connection
    ↓
Services (LG commands)
    ↓
Providers (State management)
    ↓
UI (Widgets and Screens)
```

## Contributing Back

If you create something useful:

1. Follow same architecture as examples
2. Document your approach
3. Consider open-sourcing
4. Reference [Liquid Galaxy Lab](https://github.com/LiquidGalaxyLAB/)

## Next Steps

1. Pick a project that interests you
2. Clone the repository
3. Study the architecture
4. Look for patterns you need
5. Apply to your app
6. Reference [Code Templates](../03-code-templates/) for starting point

## Useful Links

- 📦 [Liquid Galaxy Lab GitHub](https://github.com/LiquidGalaxyLAB/)
- 📚 [Flutter Documentation](https://flutter.dev/docs)
- 🔌 [Riverpod Documentation](https://riverpod.dev)
- 🔑 [dartssh2 Package](https://pub.dev/packages/dartssh2)

---

**Rule of Thumb**: Real code is worth 100 pages of documentation. Learn by reading open-source projects.
