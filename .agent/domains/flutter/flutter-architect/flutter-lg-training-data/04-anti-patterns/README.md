---
title: Anti-Patterns & Mistakes Overview
folder: 04-anti-patterns
tags: [overview, mistakes, anti-patterns, what-not-to-do]
---

# Anti-Patterns 🚫

What NOT to do when building LG apps.

## What's Inside

Common mistakes and how to fix them.

### Files

1. **[SSH Connection Anti-Patterns](ssh-mistakes.md)**
   - No timeout
   - Not checking connection
   - Hard-coded credentials
   - Not handling exceptions
   - Blocking UI thread
   - Not cleaning up
   - And 4 more...

2. **[KML Generation Anti-Patterns](kml-mistakes.md)**
   - Invalid coordinates
   - Missing XML declaration
   - Unescaped special characters
   - Wrong coordinate order
   - No altitude in tour
   - Invalid tilt values
   - And 4 more...

3. **[State Management Anti-Patterns](state-management-mistakes.md)**
   - Mutating state
   - No copyWith
   - Mixing setState with Riverpod
   - Creating new instances every build
   - Hard-coded dependencies
   - Not handling async errors
   - And 4 more...

4. **[UI/UX Anti-Patterns](ui-ux-mistakes.md)**
   - Coming soon with common UI mistakes

## How to Use

### When Building a Feature
1. Write your code
2. Compare with anti-patterns file
3. Check if you're doing any of these ❌
4. Fix if found

### When Debugging
1. Bug not making sense?
2. Check anti-patterns
3. Likely you're doing one of these

### When Code Reviewing
1. Open anti-patterns file
2. Check each pattern
3. Mark if found
4. Ask developer to fix

## Key Anti-Patterns

### SSH Mistakes to Avoid
- ❌ No timeout (app freezes)
- ❌ Not checking connected (crashes)
- ❌ Hard-coded credentials (security)
- ❌ No error handling (confusing)
- ❌ Blocks UI (frozen app)
- ❌ No cleanup (leaks)
- ❌ Password in memory (insecure)
- ❌ No input validation (crashes)
- ❌ Infinite retries (wastes CPU)
- ❌ Logic in widgets (untestable)

### KML Mistakes to Avoid
- ❌ Invalid coordinates (silent failure)
- ❌ No XML declaration (rejected)
- ❌ Unescaped & (parsing fails)
- ❌ Lat,Lng instead of Lng,Lat (wrong place)
- ❌ Missing altitude (positioning fails)
- ❌ Tilt > 90 (breaks view)
- ❌ Wrong namespace (not recognized)
- ❌ Duration as int (wrong speed)
- ❌ No Document wrapper (invalid)
- ❌ Not validating (fails silently)

### State Mistakes to Avoid
- ❌ Direct mutation (no updates)
- ❌ No copyWith (can't update properly)
- ❌ Mix setState + Riverpod (conflicts)
- ❌ New instances (memory waste)
- ❌ Hard-coded deps (untestable)
- ❌ Ignore exceptions (user confused)
- ❌ Watch whole state (too many rebuilds)
- ❌ Use FutureProvider wrong (hard to control)
- ❌ No Equatable (unnecessary rebuilds)
- ❌ No cleanup (memory leak)

## Prevention Checklist

Use this before each commit:

### SSH Layer
- [ ] Have timeout?
- [ ] Check connected before execute?
- [ ] Handle all exceptions?
- [ ] Show error to user?
- [ ] Doesn't block UI?
- [ ] Resources cleaned up?

### KML Layer
- [ ] Coordinates validated?
- [ ] XML declaration present?
- [ ] Special chars escaped?
- [ ] Lng,Lat order correct?
- [ ] Validated before sending?

### State Layer
- [ ] Using copyWith not mutation?
- [ ] Have copyWith implementation?
- [ ] No setState in ConsumerWidget?
- [ ] Dependencies injected?
- [ ] All exceptions handled?
- [ ] Resources disposed?

### UI Layer
- [ ] Loading state shown?
- [ ] Errors displayed?
- [ ] Inputs validated?
- [ ] Disabled during loading?

## Learn By Doing

### Example: Bad Code
```dart
// ❌ BAD
Future<void> connect() async {
  _ssh.connect(host, user, pass);  // No timeout, no error handling
  _isConnected = true;  // Direct mutation
  setState(() {});  // setState in ConsumerWidget
}
```

### Example: Fixed Code
```dart
// ✅ GOOD
Future<void> connect(config) async {
  state = state.copyWith(isConnecting: true);
  try {
    final success = await _ssh.connect(
      host: config.host,
      username: config.username,
      password: config.password,
      timeout: Duration(seconds: 10),
    );
    state = state.copyWith(
      isConnecting: false,
      isConnected: success,
    );
  } catch (e) {
    state = state.copyWith(
      isConnecting: false,
      errorMessage: e.toString(),
    );
  }
}
```

## Next Steps

1. Read anti-patterns for areas you work on
2. Check your code against them
3. Before committing, use prevention checklist
4. When debugging, check anti-patterns first
5. Reference [Code Templates](../03-code-templates/) for examples of doing it right

---

**Rule of Thumb**: Most bugs come from these 30 anti-patterns. Learn them, avoid them.
