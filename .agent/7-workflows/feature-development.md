# 🚀 Feature Development Workflow

## End-to-End Process for Creating New Features

This workflow guides you through the complete process of adding a new feature to the LG Controller app.

---

## Overview Timeline

```
Phase 1: Planning (30 min)     → Phase 2: Service (1-2 hours)
         ↓                                    ↓
Phase 3: UI (2-3 hours)       → Phase 4: Integration (30 min)
         ↓                                    ↓
Phase 5: Testing (1 hour)     → Phase 6: Documentation (30 min)
         ↓
      COMPLETE ✅
```

**Total Time:** 5-8 hours for a complete feature

---

## Phase 1: Planning & Design (30 min)

### Step 1.1: Define Requirements
**Activate Role:** `lg-brainstormer`

**Questions to answer:**
- What problem does this feature solve?
- Who will use it?
- What data sources are needed?
- Are there free APIs available?

**Output:** Feature brief document

**Example:**
```markdown
# Feature: Flight Path Visualizer

**Problem:** Users want to see flight routes between cities
**Users:** Education, travel planning
**Data:** Airport coordinates (free from OpenFlights API)
**API:** https://openflights.org/data.html (free, no auth)
```

### Step 1.2: Review Existing Patterns
**Read these files:**
- [1-foundations/GOLDEN_RULES.md](../1-foundations/GOLDEN_RULES.md)
- [1-foundations/ARCHITECTURE.md](../1-foundations/ARCHITECTURE.md)
- [2-patterns/service-layer.md](../2-patterns/service-layer.md)

**Check similar features:**
- Browse [3-features/](../3-features/) for examples
- Find closest match to your feature
- Note patterns used

### Step 1.3: Create Implementation Plan
**Activate Role:** `lg-plan-writer`

**Template:**
```markdown
## Implementation Plan

### Service Layer
- [ ] Create `flight_service.dart` in `lib/services/`
- [ ] Define FlightRoute model
- [ ] Implement API integration
- [ ] Add error handling

### UI Layer
- [ ] Create `flight_visualizer/` in features
- [ ] Build FlightVisualizerScreen
- [ ] Add to dashboard
- [ ] Test interactions

### KML Integration
- [ ] Generate flight path KML
- [ ] Send to Liquid Galaxy
- [ ] Test visualization
```

---

## Phase 2: Service Layer (1-2 hours)

### Step 2.1: Create Service File
**Location:** `lib/services/my_feature_service.dart`

**Activate Role:** `lg-exec`

**Template:** Use [5-templates/flutter/service-template.dart](../5-templates/flutter/)

**Checklist:**
- [ ] Import required packages
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
```
- [ ] Define base URL constant
```dart
static const String _baseUrl = 'https://api.example.com';
```
- [ ] Create model classes
```dart
class MyModel {
  final String id;
  final String name;
  
  factory MyModel.fromJson(Map<String, dynamic> json) { ... }
}
```
- [ ] Implement fetch methods
```dart
Future<List<MyModel>> fetchData() async { ... }
```
- [ ] Add error handling with try-catch
- [ ] Add timeouts (10-15 seconds)
- [ ] Add debug logging

### Step 2.2: Define Riverpod Provider
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final my FeatureServiceProvider = Provider<MyFeatureService>((ref) {
  return MyFeatureService();
});
```

### Step 2.3: Test Service
**Method 1:** Unit tests (recommended)
```dart
// test/services/my_feature_service_test.dart
void main() {
  test('fetches data successfully', () async {
    final service = MyFeatureService();
    final result = await service.fetchData();
    expect(result, isNotEmpty);
  });
}
```

**Method 2:** Manual testing in main()
```dart
void main() async {
  final service = MyFeatureService();
  final data = await service.fetchData();
  print('Fetched ${data.length} items');
}
```

---

## Phase 3: UI Layer (2-3 hours)

### Step 3.1: Create Feature Directory
```bash
lib/src/features/my_feature/
├── models/ (if needed)
├── providers/ (if needed)
└── presentation/
    └── my_feature_screen.dart
```

### Step 3.2: Build Screen Widget
**Template:** Use [5-templates/flutter/screen-template.dart](../5-templates/flutter/)

**Checklist:**
- [ ] Extend ConsumerStatefulWidget
```dart
class MyFeatureScreen extends ConsumerStatefulWidget {
  const MyFeatureScreen({super.key});
  
  @override
  ConsumerState<MyFeatureScreen> createState() => _MyFeatureScreenState();
}
```
- [ ] Add state variables
```dart
List<MyModel> _data = [];
bool _isLoading = false;
```
- [ ] Implement initState with data loading
```dart
@override
void initState() {
  super.initState();
  _loadData();
}
```
- [ ] Create loading UI
```dart
if (_isLoading) return const CircularProgressIndicator();
```
- [ ] Build main content (ListView, GridView, etc.)
- [ ] Add error handling with SnackBars
- [ ] Add pull-to-refresh (optional)

### Step 3.3: Style the UI
**Use AppTheme:**
```dart
Text(
  'Title',
  style: Theme.of(context).textTheme.headlineMedium,
)

Card(
  elevation: 4,
  shape: RoundedRectangleBorder(...),
)
```

**Follow Material Design 3:**
- Use Cards for content blocks
- Use ListTiles for list items
- Use IconButtons for actions
- Use Scaffolds with AppBars

---

## Phase 4: Dashboard Integration (30 min)

### Step 4.1: Add Import
**File:** `lib/src/features/dashboard/presentation/dashboard_screen.dart`

```dart
import 'package:lg_controller/src/features/my_feature/presentation/my_feature_screen.dart';
```

### Step 4.2: Add Dashboard Card
```dart
_ControlCard(
  title: 'My Feature',
  icon: Icons.my_icon,
  color: Colors.blueAccent,
  onTap: () {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const MyFeatureScreen()),
    );
  },
),
```

### Step 4.3: Test Navigation
- [ ] Tap card from dashboard
- [ ] Verify screen loads
- [ ] Test back navigation
- [ ] Verify state persists (if needed)

---

## Phase 5: KML Integration (30-60 min)

### Step 5.1: Generate KML from Data
**Pattern:** 
```dart
Future<void> _sendToLiquidGalaxy() async {
  final kmlBuffer = StringBuffer();
  kmlBuffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
  kmlBuffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">');
  kmlBuffer.writeln('<Document>');
  kmlBuffer.writeln('<name>My Feature</name>');
  
  for (final item in _data) {
    kmlBuffer.writeln('<Placemark>');
    kmlBuffer.writeln('<name>${item.name}</name>');
    kmlBuffer.writeln('<Point>');
    kmlBuffer.writeln('<coordinates>${item.lng},${item.lat},0</coordinates>');
    kmlBuffer.writeln('</Point>');
    kmlBuffer.writeln('</Placemark>');
  }
  
  kmlBuffer.writeln('</Document>');
  kmlBuffer.writeln('</kml>');
  
  final kmlService = ref.read(kmlServiceProvider);
  await kmlService.sendKmlToMaster(kmlBuffer.toString());
}
```

**Reference:** [2-patterns/kml-patterns.md](../2-patterns/kml-patterns.md)

### Step 5.2: Add UI Button
```dart
ElevatedButton.icon(
  onPressed: _sendToLiquidGalaxy,
  icon: const Icon(Icons.map),
  label: const Text('Show on LG'),
)
```

### Step 5.3: Test with Real LG
- [ ] Generate KML
- [ ] Send to master.kml
- [ ] Verify display on LG screens
- [ ] Test with different data
- [ ] Verify cleanup (clear old KML)

---

## Phase 6: Testing (1 hour)

### Step 6.1: Functional Testing
**Checklist:**
- [ ] Feature loads without errors
- [ ] Data fetches successfully
- [ ] UI displays correctly
- [ ] Loading states work
- [ ] Error messages display properly
- [ ] Navigation works both ways
- [ ] KML generates correctly
- [ ] LG displays visualization

### Step 6.2: Edge Case Testing
- [ ] No internet connection
- [ ] API returns empty data
- [ ] API returns error
- [ ] Invalid data format
- [ ] Very large datasets
- [ ] Rapid button clicks
- [ ] Screen rotation (mobile)

### Step 6.3: Performance Testing
- [ ] Load time < 2 seconds
- [ ] Smooth scrolling (60 fps)
- [ ] No memory leaks
- [ ] No excessive rebuilds

### Step 6.4: Code Review
**Activate Role:** `lg-code-reviewer`

**Review against:**
- [1-foundations/GOLDEN_RULES.md](../1-foundations/GOLDEN_RULES.md)
- [2-patterns/](../2-patterns/) (all patterns)
- [4-guides/flutter/common-mistakes.md](../4-guides/flutter/common-mistakes.md)

---

## Phase 7: Documentation (30 min)

### Step 7.1: Create Feature Documentation
**File:** `.agent/3-features/my-feature.md`

**Template:**
```markdown
# My Feature

## Overview
Brief description of what this feature does.

## API Integration
- **API:** [Name and URL]
- **Authentication:** Yes/No
- **Cost:** Free/Paid
- **Rate Limits:** X requests per minute

## Service Implementation
- **File:** `lib/services/my_feature_service.dart`
- **Key Methods:** 
  - `fetchData()` - Description
  - `processData()` - Description

## UI Implementation
- **File:** `lib/src/features/my_feature/presentation/my_feature_screen.dart`
- **Features:**
  - Feature 1
  - Feature 2

## KML Generation
- **Pattern:** [Describe KML structure]
- **Example:** [Show sample KML]

## Usage Example
[Code snippet showing how to use the feature]

## Testing
[How to test this feature]

## Future Enhancements
- [ ] Idea 1
- [ ] Idea 2
```

### Step 7.2: Update Project README
Add feature to the features list in main README.md

### Step 7.3: Add Code Comments
Ensure all public methods have documentation comments:
```dart
/// Fetches flight routes between two cities
/// 
/// Parameters:
/// - [origin]: IATA code of origin airport
/// - [destination]: IATA code of destination airport
/// 
/// Returns: List of FlightRoute objects
/// 
/// Throws: Exception if API call fails
Future<List<FlightRoute>> getFlightRoutes(
  String origin,
  String destination,
) async {
  // Implementation
}
```

---

## Phase 8: Git Workflow (15 min)

### Step 8.1: Create Feature Branch
```bash
git checkout -b feature/my-awesome-feature
```

### Step 8.2: Commit Changes
```bash
git add .
git commit -m "feat: Add my awesome feature

- Created MyFeatureService
- Built MyFeatureScreen UI
- Integrated with dashboard
- Added KML generation
- Wrote tests and documentation"
```

### Step 8.3: Push and PR
```bash
git push origin feature/my-awesome-feature
```

Create pull request with:
- Feature description
- Screenshots
- Testing checklist
- Breaking changes (if any)

---

## Common Workflow Variations

### Quick Feature (2-3 hours)
**For simple features:**
1. Copy existing similar feature
2. Modify service URL and models
3. Update UI text and styling
4. Test and ship

### Complex Feature (1-2 days)
** For advanced features:**
1. Detailed planning with mockups
2. Multiple service integrations
3. Custom UI components
4. Extensive testing
5. Performance optimization

### API-less Feature (1-2 hours)
**For LG-only features:**
1. Skip service layer
2. Focus on KML generation
3. Direct SSH commands
4. UI for parameter input

---

## Troubleshooting

### Service Issues
→ See [8-troubleshooting/api-errors.md](../8-troubleshooting/api-errors.md)

### SSH Issues
→ See [8-troubleshooting/ssh-issues.md](../8-troubleshooting/ssh-issues.md)

### UI Issues
→ See [4-guides/flutter/common-mistakes.md](../4-guides/flutter/common-mistakes.md)

### KML Issues
→ See [8-troubleshooting/kml-errors.md](../8-troubleshooting/kml-errors.md)

---

## Quality Checklist

Before marking feature as complete:

**Code Quality:**
- [ ] Follows GOLDEN_RULES
- [ ] Uses established patterns
- [ ] No hardcoded values
- [ ] Proper error handling
- [ ] Code commented
- [ ] No compiler warnings

**Functionality:**
- [ ] Feature works as designed
- [ ] All edge cases handled
- [ ] Performance is acceptable
- [ ] No crashes or freezes

**Integration:**
- [ ] Dashboard navigation works
- [ ] Doesn't break existing features
- [ ] KML integrates properly
- [ ] State management works

**Documentation:**
- [ ] Feature documented in .agent/
- [ ] Code comments added
- [ ] README updated
- [ ] Known issues noted

**Testing:**
- [ ] Manual testing complete
- [ ] Unit tests written (if applicable)
- [ ] Tested on real LG
- [ ] Tested edge cases

---

## Success Metrics

A well-implemented feature should achieve:

- ✅ **Load time** < 2 seconds
- ✅ **User completion rate** > 90%
- ✅ **Error rate** < 5%
- ✅ **Code coverage** > 70% (if tested)
- ✅ **Documentation completeness** 100%

---

## Next Steps After Completion

1. **Share:** Demo the feature to stakeholders
2. **Monitor:** Watch for user feedback
3. **Iterate:** Plan version 2 improvements
4. **Document lessons:** Update .agent/ with insights

---

**See also:**
- [QUICK_REFERENCE.md](../QUICK_REFERENCE.md) - Quick lookups
- [2-patterns/](../2-patterns/) - Implementation patterns  
- [5-templates/](../5-templates/) - Code templates
- [3-features/](../3-features/) - Feature examples

**Last Updated:** 2026-02-10
