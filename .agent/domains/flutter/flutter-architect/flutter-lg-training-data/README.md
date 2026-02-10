# Flutter + Liquid Galaxy Training Data - README

## 📚 Overview

This skill provides comprehensive training data for building Flutter applications that integrate with Liquid Galaxy systems. All materials are based on open-source projects from https://github.com/LiquidGalaxyLAB/.

## 📁 Contents

### 1. **SKILL.md** - Main Training Document
Core principles, patterns, and best practices for Flutter + LG development:
- SSH communication patterns
- KML management architecture
- Project structure guidelines
- State management with Riverpod
- Error handling and user feedback
- Configuration management
- Training data sources
- Common anti-patterns to avoid
- Best practices checklist

### 2. **best-practices.md** - Comprehensive Guidelines
Detailed best practices covering:
- Architecture patterns (feature-first)
- SSH communication management
- KML generation strategies
- State management patterns
- UI/UX guidelines
- Testing strategies
- Performance optimization

### 3. **repository-examples.md** - Real-World Examples
Patterns and examples from actual LG projects:
- Key repositories to study
- Common implementation patterns
- SSH connection singleton
- LG commands utility
- KML file management
- Connection settings UI
- Tour implementation
- Orbit controller
- Logo/overlay management
- Data visualization patterns
- Debugging and testing patterns

### 4. **code-templates.md** - Production-Ready Templates
Copy-paste templates for common scenarios:
- Basic SSH service implementation
- LG service layer
- KML builder utilities
- Connection state with Riverpod
- Connection screen UI
- Storage service
- App setup (main.dart)
- pubspec.yaml dependencies
- Quick start guide
- Usage examples

### 5. **common-mistakes.md** - Anti-Patterns Guide
Learn from common mistakes:
- Not checking connection state
- Inline KML string building
- Missing error handling
- Hardcoded configuration
- Shell command injection risks
- Poor state management
- Blocking UI thread
- Not cleaning slaves
- Missing timeouts
- Poor file organization
- Password security issues
- No input validation
- Missing user feedback
- Memory leaks
- Not testing connections

## 🎯 How to Use This Training Data

### For Learning:
1. Start with **SKILL.md** for core concepts
2. Study **repository-examples.md** for real-world patterns
3. Review **best-practices.md** for detailed guidelines
4. Check **common-mistakes.md** to avoid pitfalls

### For Implementation:
1. Use **code-templates.md** for quick scaffolding
2. Reference **best-practices.md** during development
3. Verify against **common-mistakes.md** during code review
4. Study **repository-examples.md** for complex features

### For Code Review:
1. Check against **best-practices checklist**
2. Verify no **common-mistakes** are present
3. Ensure patterns match **repository-examples**
4. Confirm templates follow **code-templates**

## 🔑 Key Principles

### 1. **Connection First**
Always verify SSH connection before operations:
```dart
if (!connectionState.isConnected) {
  // Handle not connected state
  return;
}
```

### 2. **Modular KML**
Never build KML strings inline:
```dart
// Use builders
final kml = KMLBuilder.buildPlacemark(...);
```

### 3. **Error Handling**
All operations must handle errors:
```dart
final result = await ssh.execute(command);
if (result.isFailure) {
  // Handle error
}
```

### 4. **State Management**
Use Riverpod for global state:
```dart
final connectionProvider = StateNotifierProvider<...>(...);
```

### 5. **User Feedback**
Always inform users about operations:
```dart
ScaffoldMessenger.of(context).showSnackBar(...);
```

## 📊 Training Data Sources

All examples are derived from:
- **LiquidGalaxyLAB GitHub**: https://github.com/LiquidGalaxyLAB/
- GSoC student projects
- Production controller apps
- Community best practices
- Official examples and templates

## 🎓 Learning Path

### Beginner:
1. Understand SSH basics (SKILL.md)
2. Learn KML structure (code-templates.md)
3. Set up basic connection (code-templates.md)
4. Avoid common mistakes (common-mistakes.md)

### Intermediate:
1. Implement state management (best-practices.md)
2. Build modular KML generators (repository-examples.md)
3. Create feature-first architecture (best-practices.md)
4. Study real-world examples (repository-examples.md)

### Advanced:
1. Implement tours and orbits (repository-examples.md)
2. Add data visualization (repository-examples.md)
3. Optimize performance (best-practices.md)
4. Contribute to LG community projects

## ✅ Quality Checklist

Before considering a Flutter LG app complete:

**Architecture:**
- [ ] Feature-first folder structure
- [ ] Separation of concerns
- [ ] Service layer abstraction
- [ ] Proper dependency injection

**SSH & Connectivity:**
- [ ] Connection state management
- [ ] Error handling on all operations
- [ ] Timeout handling
- [ ] Graceful disconnection

**KML Management:**
- [ ] Modular KML builders
- [ ] XML escaping
- [ ] Clean slave screens
- [ ] Proper KML validation

**State Management:**
- [ ] Riverpod providers
- [ ] Global connection state
- [ ] Feature-specific state
- [ ] No setState for global state

**UI/UX:**
- [ ] Connection status indicator
- [ ] Loading states
- [ ] Error messages
- [ ] User feedback on operations

**Security:**
- [ ] Secure password storage
- [ ] Input validation
- [ ] Shell command escaping
- [ ] No hardcoded credentials

**Code Quality:**
- [ ] Resource disposal
- [ ] Memory leak prevention
- [ ] No blocking operations
- [ ] Proper error boundaries

**Testing:**
- [ ] Unit tests for services
- [ ] Widget tests for UI
- [ ] Connection testing
- [ ] KML validation tests

## 🚀 Quick Start

1. **Copy templates** from code-templates.md
2. **Set up dependencies** from pubspec.yaml template
3. **Implement SSH service** using provided template
4. **Create connection screen** from UI template
5. **Build dashboard** with LG controls
6. **Test thoroughly** before deployment

## 📖 Additional Resources

- **Liquid Galaxy Official**: https://www.liquidgalaxy.eu/
- **GitHub Organization**: https://github.com/LiquidGalaxyLAB/
- **KML Reference**: https://developers.google.com/kml/documentation/kmlreference
- **dartssh2 Package**: https://pub.dev/packages/dartssh2
- **Riverpod Documentation**: https://riverpod.dev/
- **Flutter Documentation**: https://docs.flutter.dev/

## 🤝 Contributing

This training data is continuously updated based on:
- New LiquidGalaxyLAB projects
- Community feedback
- Emerging best practices
- Flutter ecosystem updates

All contributions to LG projects should be open-sourced at https://github.com/LiquidGalaxyLAB/

## 📝 Notes

- All code examples are production-ready
- Patterns follow Flutter best practices
- Examples tested with real LG systems
- Templates compatible with latest Flutter SDK
- Regularly updated with new patterns

---

**Goal**: Enable developers to create professional, maintainable Flutter applications for Liquid Galaxy systems using proven patterns and best practices from the community.

**Maintained for**: LGWebStarterKit project - A perfect starter kit for creating Flutter apps for Liquid Galaxy.
