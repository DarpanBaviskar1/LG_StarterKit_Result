---
title: Core Patterns Overview
folder: 01-core-patterns
tags: [overview, patterns, foundations]
---

# Core Patterns 🧱

Foundational knowledge every LG developer needs.

## What's Inside

This folder contains the fundamental building blocks for Flutter + Liquid Galaxy apps.

### Files

1. **[SSH Communication](ssh-communication.md)** (10 min)
   - How to connect to Liquid Galaxy
   - Command execution patterns
   - Error handling and timeouts
   - Integration with Riverpod

2. **[KML Management](kml-management.md)** (12 min)
   - KML generation for LG commands
   - FlyTo, Placemark, Tour patterns
   - Coordinate systems and validation
   - Best practices and common mistakes

3. **[State Management](state-management.md)** (12 min)
   - Riverpod fundamentals
   - StateNotifier pattern
   - Provider setup and usage
   - Common state patterns

4. **[Project Structure](project-structure.md)** (8 min)
   - Folder organization (feature-first)
   - Naming conventions
   - What goes where
   - Scaling patterns

## Learning Path

### Beginner (30 min)
1. Read [Project Structure](project-structure.md) - Understand file organization
2. Skim [SSH Communication](ssh-communication.md) - Know what's possible
3. Skim [KML Management](kml-management.md) - Know what KML can do

### Intermediate (60 min)
1. Read [SSH Communication](ssh-communication.md) - Deep dive on connections
2. Read [KML Management](kml-management.md) - Master KML generation
3. Read [State Management](state-management.md) - Riverpod patterns

### Advanced (90 min)
1. Study all 4 patterns
2. Reference [Code Templates](../03-code-templates/)
3. Build first feature using these patterns

## Key Principles

✅ **Timeouts**: Always set timeouts on SSH connections  
✅ **Validation**: Always validate coordinates before KML  
✅ **Immutability**: Use copyWith(), never mutate state  
✅ **Dependency Injection**: Pass dependencies via providers  
✅ **Separation**: Keep UI, services, and state separate  
✅ **Error Handling**: Handle all exceptions gracefully  

## Next Steps

- If starting new app: Read [Project Structure](project-structure.md)
- If building connection: Read [SSH Communication](ssh-communication.md)
- If adding navigation: Read [KML Management](kml-management.md)
- If managing state: Read [State Management](state-management.md)
- If stuck: Check [Troubleshooting](../07-troubleshooting/)
- If making mistakes: Check [Anti-Patterns](../04-anti-patterns/)

## Quick Links

- 📁 **Structure**: [Project Structure](project-structure.md)
- 🔌 **Connection**: [SSH Communication](ssh-communication.md)
- 📍 **Navigation**: [KML Management](kml-management.md)
- 🎛️ **State**: [State Management](state-management.md)
- 🔨 **Templates**: [../03-code-templates/](../03-code-templates/)
- 🚫 **Avoid**: [../04-anti-patterns/](../04-anti-patterns/)
- 🐛 **Fix**: [../07-troubleshooting/](../07-troubleshooting/)

---

**Rule of Thumb**: Understand these 4 patterns and you can build any LG app.
