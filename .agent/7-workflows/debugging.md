# 🔍 Systematic Debugging Workflow

## From Error to Solution: Step-by-Step Process

This guide helps you debug issues efficiently using a systematic approach.

---

## Quick Debugging Flowchart

```
Error Occurs
    ↓
Step 1: Read Error Message → Known issue? → 8-troubleshooting/
    ↓ Unknown
Step 2: Check Service Layer → API issue? → Fix service
    ↓ Service OK
Step 3: Check State Management → State issue? → Fix provider
    ↓ State OK
Step 4: Review GOLDEN_RULES → Violated rule? → Apply fix
    ↓ Rules OK
Step 5: Add Debug Logging → Find exact failure point
    ↓
Step 6: Minimal Reproduction → Isolate the problem
    ↓
Step 7: Search .agent/ → Find similar solved issue
    ↓
SOLVED ✅
```

---

## Step 1: Read Error Message (2 min)

### 1.1 Capture Complete Error
**DO NOT skip this step!**

❌ **Bad:** "It's not working"
✅ **Good:** Copy the ENTIRE error message including:
- Error type (Exception, Error, etc.)
- Error message
- Stack trace
- Line numbers

**How to capture:**
```dart
// In catch blocks
catch (e, stackTrace) {
  debugPrint('❌ ERROR: $e');
  debugPrint('📍 STACK TRACE: $stackTrace');
}
```

### 1.2 Classify Error Type

**Compilation Errors** (Red squiggles in IDE)
- Missing imports
- Type mismatches
- Undefined methods
- Syntax errors

→ **Fix immediately** in code

**Runtime Errors** (Crashes during execution)
- Null pointer exceptions
- Network errors
- Type cast failures
- Index out of bounds

→ **Continue to Step 2**

**Logic Errors** (Wrong behavior, no crash)
- Wrong calculations
- Incorrect state updates
- UI not updating
- Data not displaying

→ **Skip to Step 4**

### 1.3 Check Known Issues
**Search these files FIRST:**
- [8-troubleshooting/ssh-issues.md](../8-troubleshooting/ssh-issues.md)
- [8-troubleshooting/kml-errors.md](../8-troubleshooting/kml-errors.md)
- [8-troubleshooting/state-bugs.md](../8-troubleshooting/state-bugs.md)
- [8-troubleshooting/api-errors.md](../8-troubleshooting/api-errors.md)

**Find match?** → Apply solution → **DONE** ✅

**No match?** → Continue to Step 2

---

## Step 2: Check Service Layer (10 min)

### 2.1 Verify API Response
**Add logging to service:**
```dart
Future<List<MyData>> fetchData() async {
  try {
    final response = await http.get(Uri.parse(_baseUrl))
        .timeout(const Duration(seconds: 15));
    
    debugPrint('📡 API Response Status: ${response.statusCode}');
    debugPrint('📦 API Response Body: ${response.body}');
    
    if (response.statusCode == 200) {
      // Continue...
    }
  } catch (e) {
    debugPrint('❌ API Error: $e');
    rethrow;
  }
}
```

### 2.2 Common Service Issues

**Issue: Timeout Error**
```
TimeoutException after 0:00:15.000000: Future not completed
```
**Causes:**
- API server is down
- No internet connection
- Firewall blocking request
- API endpoint changed

**Solutions:**
1. Test API in browser/Postman
2. Check internet connection
3. Verify API URL is correct
4. Increase timeout duration

**Issue: 404 Not Found**
```
Status Code: 404
```
**Causes:**
- Wrong endpoint URL
- API version changed
- Missing path parameters

**Solutions:**
1. Check API documentation
2. Verify URL construction
```dart
// Wrong
final url = '$baseUrl/items/$id';  // Missing slash?

// Right
final url = '$baseUrl/items/$id';  // Check carefully
```

**Issue: 200 OK but empty data**
```
Status Code: 200
Body: {"results": []}
```
**Causes:**
- API has no data for your query
- Wrong query parameters
- API requires authentication

**Solutions:**
1. Test with different parameters
2. Check API documentation for requirements
3. Add authentication headers (if needed)

**Issue: JSON Parsing Error**
```
type 'String' is not a subtype of type 'int' in type cast
```
**Causes:**
- API response structure changed
- Null values in JSON
- Wrong type assumptions

**Solutions:**
1. Print raw JSON response
2. Verify model class matches API
3. Add null safety
```dart
// Wrong
final tsunami = json['tsunami'] as String;

// Right
final tsunami = json['tsunami']?.toString() ?? 'false';
```

### 2.3 Test Service in Isolation
**Create test file:**
```dart
// test/services/my_service_test.dart
void main() async {
  final service = MyFeatureService();
  
  try {
    final data = await service.fetchData();
    print('✅ Success: Got ${data.length} items');
    print('First item: ${data.first}');
  } catch (e) {
    print('❌ Error: $e');
  }
}
```

**Run test:**
```bash
dart test/services/my_service_test.dart
```

---

## Step 3: Check State Management (15 min)

### 3.1 Verify Provider Setup
**Check provider definition:**
```dart
// ✅ Correct
final myServiceProvider = Provider<MyService>((ref) {
  return MyService();
});

// ❌ Wrong - missing Provider wrapper
final myService = MyService();
```

**Check provider usage:**
```dart
// ✅ Correct
final service = ref.read(myServiceProvider);

// ❌ Wrong - not using provider
final service = MyService();  // Creates new instance!
```

### 3.2 Check State Updates
**Issue: UI not updating after data change**

**Cause 1: Not calling setState**
```dart
// ❌ Wrong
void _loadData() async {
  _data = await service.fetchData();
  // UI won't update!
}

// ✅ Correct
void _loadData() async {
  final data = await service.fetchData();
  setState(() {
    _data = data;
  });
}
```

**Cause 2: Using Provider instead of StateProvider**
```dart
// ❌ Wrong - Provider is immutable
final counterProvider = Provider<int>((ref) => 0);

// ✅ Correct - StateProvider for mutable state
final counterProvider = StateProvider<int>((ref) => 0);
```

**Cause 3: Not watching provider**
```dart
// ❌ Wrong - read() doesn't listen to changes
final count = ref.read(counterProvider);

// ✅ Correct - watch() rebuilds on changes
final count = ref.watch(counterProvider);
```

### 3.3 Check Async State
**Issue: Data shows then disappears**

**Cause: Widget rebuilds and resets state**
```dart
// ❌ Wrong - state resets on rebuild
class MyWidget extends ConsumerWidget {
  @override
  Widget build(context, ref) {
    List<Data> data = [];  // ← Resets every build!
    // ...
  }
}

// ✅ Correct - state persists
class MyWidget extends ConsumerStatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends ConsumerState<MyWidget> {
  List<Data> _data = [];  // ← Persists across rebuilds
  // ...
}
```

---

## Step 4: Review GOLDEN_RULES (5 min)

### 4.1 SSH Communication Rules
**From:** [1-foundations/GOLDEN_RULES.md](../1-foundations/GOLDEN_RULES.md)

**Rule 1:** ALWAYS use `client!.run(command)`
```dart
// ❌ WRONG - execute() doesn't exist
await client!.execute('echo "test"');

// ✅ CORRECT
final result = await client!.run('echo "test"');
```

**Rule 2:** Check connection before commands
```dart
if (client == null) {
  throw Exception('Not connected to LG');
}
```

**Rule 3:** Add timeouts to SSH commands
```dart
await client!.run(command).timeout(const Duration(seconds: 10));
```

### 4.2 KML Management Rules

**Rule 1:** Only send to master.kml
```dart
// ❌ WRONG
await sshService.sendKml(kml, targetFile: 'custom.kml');

// ✅ CORRECT
await sshService.sendKml(kml, targetFile: 'master.kml');
```

**Rule 2:** Proper KML structure
```xml
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <!-- Content here -->
  </Document>
</kml>
```

**Rule 3:** Escape special characters
```dart
// ❌ WRONG - quotes break command
final kml = '''<name>Joe's Place</name>''';

// ✅ CORRECT
final kml = '''<name>Joe&apos;s Place</name>''';
```

### 4.3 State Management Rules

**Rule 1:** Use Riverpod 3.x
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
// NOT: import 'package:provider/provider.dart';
```

**Rule 2:** Extend ConsumerStatefulWidget for screens
```dart
class MyScreen extends ConsumerStatefulWidget {
  // Not StatefulWidget!
}
```

**Rule 3:** Read in callbacks, watch in build
```dart
Widget build(context, ref) {
  final data = ref.watch(dataProvider);  // ✅ Rebuilds on change
  
  return ElevatedButton(
    onPressed: () {
      ref.read(dataProvider.notifier).update();  // ✅ One-time read
    },
  );
}
```

---

## Step 5: Add Debug Logging (10 min)

### 5.1 Strategic Log Placement
**Add logs at key points:**

```dart
import 'package:flutter/foundation.dart';

void _loadData() async {
  debugPrint('🔵 START: Loading data...');
  
  setState(() {
    _isLoading = true;
    debugPrint('🟡 STATE: isLoading = true');
  });
  
  try {
    final service = ref.read(myServiceProvider);
    debugPrint('🟢 SERVICE: Got service instance');
    
    final data = await service.fetchData();
    debugPrint('🟢 DATA: Fetched ${data.length} items');
    
    setState(() {
      _data = data;
      _isLoading = false;
      debugPrint('🟡 STATE: Updated data, isLoading = false');
    });
    
    debugPrint('✅ COMPLETE: Data load successful');
  } catch (e, stackTrace) {
    debugPrint('❌ ERROR: $e');
    debugPrint('📍 STACK: $stackTrace');
    
    setState(() {
      _isLoading = false;
      debugPrint('🟡 STATE: isLoading = false (error)');
    });
  }
}
```

### 5.2 Log Analysis
**Run app and watch logs:**

**Good output (no errors):**
```
🔵 START: Loading data...
🟡 STATE: isLoading = true
🟢 SERVICE: Got service instance
🟢 DATA: Fetched 25 items
🟡 STATE: Updated data, isLoading = false
✅ COMPLETE: Data load successful
```

**Bad output (error found):**
```
🔵 START: Loading data...
🟡 STATE: isLoading = true
🟢 SERVICE: Got service instance
❌ ERROR: type 'int' is not a subtype of type 'String'
📍 STACK: ...line 45...
```
→ **Error occurs at line 45** → Focus debugging there

### 5.3 Conditional Logging
**Use kDebugMode for production:**
```dart
if (kDebugMode) {
  debugPrint('Debug info: $someValue');
}
```

---

## Step 6: Minimal Reproduction (15 min)

### 6.1 Isolate the Problem
**Create minimal test case:**

**Original complex code (100 lines):**
```dart
class ComplexScreen extends StatefulWidget {
  // 100 lines of code
  // Multiple features
  // Many dependencies
}
```

**Minimal reproduction (20 lines):**
```dart
void main() async {
  // Just the failing part
  final service = MyService();
  final data = await service.fetchData();
  print(data);  // ← Does this work?
}
```

### 6.2 Test Each Layer

**Layer 1: API only**
```dart
void main() async {
  final response = await http.get(Uri.parse('https://api.example.com/data'));
  print(response.body);  // ← Does API respond?
}
```

**Layer 2: Service only**
```dart
void main() async {
  final service = MyService();
  final data = await service.fetchData();
  print(data);  // ← Does parsing work?
}
```

**Layer 3: UI only**
```dart
void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: Center(
        child: MyWidget(),  // ← Does widget render?
      ),
    ),
  ));
}
```

### 6.3 Binary Search Debugging
**Comment out half the code:**
```dart
void buggyFunction() {
  // part1();  // ← Comment this half
  // part2();
  // part3();
  part4();  // ← Keep this half
  part5();
  part6();
}
```

**Does error go away?**
- Yes → Bug is in commented code
- No → Bug is in remaining code

**Repeat until you find the exact line.**

---

## Step 7: Search .agent/ (5 min)

### 7.1 Search by Error Message
**Use grep to find similar issues:**

**Windows PowerShell:**
```powershell
cd .agent
Get-ChildItem -Recurse -Filter *.md | Select-String "error_message_here"
```

**Search terms to try:**
- Exact error message
- Error type ("TimeoutException", "FormatException")
- API name ("USGS", "Nominatim")
- Feature name ("earthquake", "weather")

### 7.2 Search by Symptom
**Alternative searches:**
- "not displaying" → UI issues
- "null" → Null safety issues
- "type cast" → Type errors
- "timeout" → API issues

### 7.3 Check Similar Features
**Find working examples:**
```
If debugging: Earthquake Tracker
Look at: Weather Overlay (similar API pattern)
Compare: Service implementation, error handling, data parsing
```

---

## Step 8: Advanced Techniques (30+ min)

### 8.1 Flutter DevTools

**Launch DevTools:**
```bash
flutter pub global activate devtools
flutter pub global run devtools
```

**Use Inspector:**
- View widget tree
- Check widget properties
- Find state issues

**Use NetworkTab:**
- Monitor HTTP requests
- Check response times
- Find failed requests

### 8.2 Print Debugging
**Print everything:**
```dart
print('Variables: a=$a, b=$b, c=$c');
print('Type of x: ${x.runtimeType}');
print('JSON raw: $jsonString');
print('Parsed: ${jsonDecode(jsonString)}');
```

### 8.3 Debugger Breakpoints
**Use IDE debugger:**
1. Click line number to add breakpoint
2. Run in debug mode (F5)
3. Step through code (F10)
4. Inspect variables

---

## Common Issue Patterns

### Pattern 1: "Works on first run, fails on second"
**Cause:** State not being reset
**Solution:** Add cleanup in dispose()
```dart
@override
void dispose() {
  _data.clear();
  _controller.dispose();
  super.dispose();
}
```

### Pattern 2: "Works locally, fails on LG"
**Cause:** Network/SSH issues
**Solution:** Check LG connection, test SSH commands manually

### Pattern 3: "Random crashes"
**Cause:** Race conditions, null values
**Solution:** Add null checks, use async/await properly

### Pattern 4: "Slow performance"
**Cause:** Too many rebuilds, large lists
**Solution:** Use const constructors, ListView.builder, memoization

---

## Debugging Checklist

Before asking for help, verify:

**Basic Checks:**
- [ ] Read complete error message
- [ ] Searched 8-troubleshooting/
- [ ] Checked service layer
- [ ] Verified state management
- [ ] Reviewed GOLDEN_RULES
- [ ] Added debug logging
- [ ] Created minimal reproduction

**Code Quality:**
- [ ] No hardcoded values
- [ ] Proper error handling
- [ ] Null safety
- [ ] Timeouts on network calls
- [ ] Following established patterns

**Testing:**
- [ ] Tested service in isolation
- [ ] Tested UI in isolation
- [ ] Tested on real device
- [ ] Tested edge cases

---

## When to Ask for Help

Ask for help if:
- ✅ Spent 2+ hours debugging
- ✅ Completed all checklist items
- ✅ Have minimal reproduction
- ✅ Have complete error message and logs

**How to ask:**
```markdown
## Problem
[Describe what's not working]

## Expected Behavior
[What should happen]

## Actual Behavior
[What actually happens]

## Error Message
[Complete error with stack trace]

## Steps to Reproduce
1. Do this
2. Then this
3. Error occurs

## What I Tried
- Tried X → Result
- Tried Y → Result

## Code
[Minimal reproduction]

## Context
- Flutter version: X.X.X
- Device: Android/iOS/Desktop
- Feature: [Name]
```

---

## Success Stories

### Case Study 1: Earthquake Tracker
**Problem:** "Not displaying anything"
**Process:**
1. Checked logs → Found type cast error
2. Tested API → Response OK
3. Checked JSON parsing → Found tsunami field was int, not string
4. Fixed type handling → Worked!

**Time:** 30 minutes

### Case Study 2: SSH Connection Fails
**Problem:** "Connection timeout"
**Process:**
1. Tested LG manually → LG responding
2. Checked code → Used execute() instead of run()
3. Reviewed GOLDEN_RULES → Found correct pattern
4. Fixed to use run() → Worked!

**Time:** 15 minutes

---

**See also:**
- [QUICK_REFERENCE.md](../QUICK_REFERENCE.md) - Quick fixes
- [8-troubleshooting/](../8-troubleshooting/) - Known issues
- [1-foundations/GOLDEN_RULES.md](../1-foundations/GOLDEN_RULES.md) - Critical rules
- [2-patterns/](../2-patterns/) - Correct patterns

**Last Updated:** 2026-02-10
