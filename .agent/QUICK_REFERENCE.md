# ⚡ Quick Reference - AI Agent Cheat Sheet

**1-page overview of the most important information for AI agents**

---

## 🚨 CRITICAL RULES (Never Break These)

```dart
// ✅ ALWAYS use client!.run() for SSH commands
await _sshService.client!.run(command);

// ❌ NEVER use execute() method
await _sshService.execute(command); // WRONG!

// ✅ ALWAYS await SSH commands
await _sshService.client!.run('command');

// ✅ ALWAYS send KML to master only (use sendKmlToMaster)
await kmlService.sendKmlToMaster(kml);

// ❌ NEVER use numbered slaves directly
await kmlService.sendKml(kml, slave: 1); // WRONG!
```

**Source:** [1-foundations/GOLDEN_RULES.md](1-foundations/GOLDEN_RULES.md)

---

## 📋 Common Tasks → Quick Links

| Task | Go To | Time |
|------|-------|------|
| **Create new feature** | [7-workflows/feature-development.md](7-workflows/feature-development.md) | Full guide |
| **Add SSH command** | [2-patterns/ssh-patterns.md](2-patterns/ssh-patterns.md) | 2 min |
| **Generate KML** | [2-patterns/kml-patterns.md](2-patterns/kml-patterns.md) + [5-templates/kml/](5-templates/kml/) | 5 min |
| **Create Flutter screen** | [5-templates/flutter/screen-template.dart](5-templates/flutter/screen-template.dart) | Copy-paste |
| **Add service layer** | [2-patterns/service-layer.md](2-patterns/service-layer.md) | 10 min |
| **Fix SSH error** | [8-troubleshooting/ssh-issues.md](8-troubleshooting/ssh-issues.md) | Lookup |
| **Fix KML error** | [8-troubleshooting/kml-errors.md](8-troubleshooting/kml-errors.md) | Lookup |
| **Review code** | [6-roles/lg-code-reviewer.md](6-roles/lg-code-reviewer.md) | Role |

---

## 🏗️ Project Architecture Overview

```
Flutter App (Dart/UI)
    ↓
Service Layer (lib/services/)
    ↓
SSH Service (client!.run())
    ↓
Liquid Galaxy (SSH commands)
```

**State Management:** Riverpod 3.x (NOT Provider)  
**SSH Library:** `dartssh2`  
**Pattern:** Service → Provider → ConsumerWidget

---

## 📁 File Organization

```
lg_controller/lib/
├── services/              ← HTTP/API services (agent, nominatim, weather, earthquake)
├── src/
│   ├── common/           ← Shared utilities
│   ├── features/         ← Feature modules
│   │   ├── dashboard/    ← Main navigation
│   │   ├── kml_agent/    ← AI KML generation
│   │   ├── location_lookup/
│   │   ├── weather_overlay/
│   │   └── earthquake_tracker/
│   └── home/
│       └── data/         ← Core services (lg_service, kml_service, ssh_service)
```

---

## 🎯 AI Role Selection

| Situation | Activate This Role |
|-----------|-------------------|
| User starting new project | [lg-init](6-roles/lg-init.md) |
| Brainstorming features | [lg-brainstormer](6-roles/lg-brainstormer.md) |
| Creating detailed plan | [lg-plan-writer](6-roles/lg-plan-writer.md) |
| Writing code | [lg-exec](6-roles/lg-exec.md) |
| Reviewing code | [lg-code-reviewer](6-roles/lg-code-reviewer.md) |
| Testing knowledge | [lg-quiz-master](6-roles/lg-quiz-master.md) |

---

## 🔧 Flutter Code Patterns

### Service Creation
```dart
class MyService {
  static const String _baseUrl = 'https://api.example.com';
  
  Future<List<MyModel>> fetchData() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/endpoint'))
        .timeout(const Duration(seconds: 15));
        
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data as List).map((item) => MyModel.fromJson(item)).toList();
      }
      
      throw Exception('Failed: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
```

### Screen Creation
```dart
class MyScreen extends ConsumerStatefulWidget {
  const MyScreen({super.key});
  
  @override
  ConsumerState<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends ConsumerState<MyScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Feature')),
      body: // Your UI
    );
  }
}
```

### Provider Creation
```dart
final myServiceProvider = Provider((ref) => MyService());

// In widget:
final service = ref.read(myServiceProvider);
```

---

## 🌐 Free APIs Integration

| API | Purpose | Auth Required | Docs |
|-----|---------|---------------|------|
| **Nominatim** | Geocoding | No (User-Agent header) | [3-features/location-lookup/](3-features/location-lookup/) |
| **Open-Meteo** | Weather | No | [3-features/weather-overlay/](3-features/weather-overlay/) |
| **USGS** | Earthquakes | No | [3-features/earthquake-tracker/](3-features/earthquake-tracker/) |
| **Gemini AI** | KML Generation | Yes (API key) | [3-features/kml-agent/](3-features/kml-agent/) |

---

## 🚨 Common Mistakes & Solutions

| Mistake | Solution | Reference |
|---------|----------|-----------|
| Using `.execute()` on SSH | Use `client!.run()` | [GOLDEN_RULES](1-foundations/GOLDEN_RULES.md) |
| Not awaiting SSH | Always `await` | [ssh-patterns](2-patterns/ssh-patterns.md) |
| Sending to numbered slaves | Use `sendKmlToMaster()` | [kml-patterns](2-patterns/kml-patterns.md) |
| Using Provider | Use Riverpod 3.x | [state-management](2-patterns/state-management.md) |
| Hardcoding values | Use service layer | [service-layer](2-patterns/service-layer.md) |

---

## 📐 KML Structure

```xml
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>Feature Name</name>
    
    <!-- Placemark (location marker) -->
    <Placemark>
      <name>Location</name>
      <description>Details</description>
      <Point>
        <coordinates>lng,lat,altitude</coordinates>
      </Point>
    </Placemark>
    
    <!-- Tour (camera movement) -->
    <gx:Tour>
      <gx:Playlist>
        <gx:FlyTo>
          <gx:duration>5.0</gx:duration>
          <LookAt>
            <latitude>lat</latitude>
            <longitude>lng</longitude>
            <range>1000</range>
            <tilt>60</tilt>
          </LookAt>
        </gx:FlyTo>
      </gx:Playlist>
    </gx:Tour>
  </Document>
</kml>
```

**Templates:** [5-templates/kml/](5-templates/kml/)

---

## 🐛 Debugging Checklist

```
□ Read error message completely
□ Check 8-troubleshooting/ for known issues
□ Verify SSH connection (test_rig.md)
□ Validate KML syntax
□ Check service imports
□ Verify provider registration
□ Test with debugPrint() statements
□ Review GOLDEN_RULES compliance
```

---

## 📞 Need More Detail?

- **For WHY:** → [1-foundations/](1-foundations/)
- **For HOW:** → [2-patterns/](2-patterns/) or [4-guides/](4-guides/)
- **For CODE:** → [5-templates/](5-templates/)
- **For EXAMPLES:** → [3-features/](3-features/)
- **For HELP:** → [8-troubleshooting/](8-troubleshooting/)

---

## ✅ Pre-Implementation Checklist

Before writing any code, verify:

- [ ] Read GOLDEN_RULES.md
- [ ] Checked relevant pattern docs
- [ ] Found similar feature in 3-features/
- [ ] Selected appropriate template from 5-templates/
- [ ] Understood the workflow from 7-workflows/
- [ ] Know which role to activate (6-roles/)

---

**Remember:** This is a QUICK reference. For deep understanding, read the full documentation in respective folders.

**Last updated:** 2026-02-10
