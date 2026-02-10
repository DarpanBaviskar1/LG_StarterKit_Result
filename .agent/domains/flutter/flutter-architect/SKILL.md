---
name: Flutter Architect
description: Expert guidance on building high-quality Flutter applications for Liquid Galaxy, focusing on SSH connectivity, KML management, and clean architecture.
---

# Flutter Architect for Liquid Galaxy 💙

## Overview
This skill provides the best practices for building the "Controller" part of a Liquid Galaxy system using Flutter. Liquid Galaxy controllers are typically tablet apps that communicate with the Master machine via SSH to execute KML commands.

## 🏗 Architecture Principles

### 1. Feature-First Structure
Do not organize by "views" vs "controllers". Organize by **Feature**:
```text
lib/
├── src/
│   ├── features/
│   │   ├── home/
│   │   ├── settings/ (Connection details)
│   │   └── dashboard/ (The controls)
│   ├── common/
│   │   ├── ssh/ (SSH Service)
│   │   └── kml/ (KML Generators)
│   ├── constants/
│   └── utils/
├── main.dart
```

### 2. State Management
Use **Riverpod** (recommended) or BLoC.
- Avoid `setState` for anything beyond simple local widget animations.
- Connection state (Connected/Disconnected) must be global.

### 3. The SSH Service
The core of any LG Flutter app.
- **Library**: Use `dartssh2`.
- **Pattern**: Singleton or Riverpod Provider `ref.watch(sshServiceProvider)`.
- **Functions**:
  - `connect(ip, user, pass, port)`
  - `execute(command)`
  - `sendKml(content, filename)`
  - `cleanSlaves()`: Run commands to clear all screens.

### 4. KML Management
- Do not concatenate strings inline.
- Use a `KMLBuilder` class.
- **Interpolation**: Cleanly inject coordinates.
- **Assets**: Store static KML parts in `assets/kml/`.

## 🛠 Best Practices

- **Strict Typing**: No `dynamic` unless absolutely necessary.
- **Lints**: Enable `flutter_lints` or `very_good_analysis`.
- **Responsiveness**: Use `LayoutBuilder` or `flutter_screenutil` to support different tablet sizes.
- **Error Handling**: Graceful degradation if SSH fails (Show "Reconnecting..." toast).

## 5. Advanced LG Operations (Reference)

When controlling a rig, you often need to manage the slaves (lg2, lg3, etc.) from the Master (lg1). Authentication between machines is handled via `sshpass`.

**Reference Implementation for Power Management:**

```dart
class LGOperations {
  // ... connection setup ...

  /// Shuts down all rigs in the cluster
  Future<bool> shutdown(SSHClient client, int rigs, String password) async {
    try {
      for (int i = 1; i <= rigs; i++) {
        // Execute shutdown on remote machine via sshpass
        // IMPORTANT: Use subshell with sleep to ensure sudo receives password
        final command = 'sshpass -p "$password" ssh -o StrictHostKeyChecking=no lg$i "(echo $password; sleep 1) | sudo -S poweroff"';
        await client.run(command);
      }
      return true;
    } catch (e) {
      debugPrint('Failed to shutdown: $e');
      return false;
    }
  }

  /// Reboots all rigs
  Future<bool> reboot(SSHClient client, int rigs, String password) async {
    try {
      for (int i = 1; i <= rigs; i++) {
        // Execute reboot on remote machine via sshpass
        // IMPORTANT: Use subshell with sleep to ensure sudo receives password
        final command = 'sshpass -p "$password" ssh -o StrictHostKeyChecking=no lg$i "(echo $password; sleep 1) | sudo -S reboot"';
        await client.run(command);
      }
      return true;
    } catch (e) {
      debugPrint('Failed to reboot: $e');
      return false;
    }
  }

  /// Relaunches the Liquid Galaxy application
  Future<void> relaunch(SSHClient client, int rigs, String password) async {
    const relaunchScript = """
      if [ -f /etc/init/lxdm.conf ]; then
        export SERVICE=lxdm
      elif [ -f /etc/init/lightdm.conf ]; then
        export SERVICE=lightdm
      else
        exit 1
      fi
      if [[ \\\$(service \\\$SERVICE status) =~ 'stop' ]]; then
        (echo $password; sleep 1) | sudo -S service \\\${SERVICE} start
      else
        (echo $password; sleep 1) | sudo -S service \\\${SERVICE} restart
      fi
    """;

    try {
      for (var i = rigs; i >= 1; i--) {
        // IMPORTANT: Use subshell with sleep to ensure sudo receives password
        final command = 'sshpass -p "$password" ssh -o StrictHostKeyChecking=no lg$i "$relaunchScript"';
        await client.run(command);
      }
    } catch (e) {
      debugPrint('Relaunch failed: $e');
    }
  }

  Future<bool> sendLogo({
    required String screenNumber,
    required String imageUrl,
  }) async {
    // LOGO MANAGEMENT: Use slave-specific KML for static overlays
    // See Slave Screen Management section below
    try {
      final kml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" 
     xmlns:gx="http://www.google.com/kml/ext/2.2">
  <Document>
    <name>Logo</name>
    <Folder>
      <name>Logo</name>
      <ScreenOverlay>
        <name>Logo</name>
        <Icon>
          <href>$imageUrl</href>
        </Icon>
        <overlayXY x="0" y="1" xunits="fraction" yunits="fraction"/>
        <screenXY x="0.05" y="0.95" xunits="fraction" yunits="fraction"/>
        <rotationXY x="0" y="0" xunits="fraction" yunits="fraction"/>
        <size x="200" y="200" xunits="pixels" yunits="pixels"/>
      </ScreenOverlay>
    </Folder>
  </Document>
</kml>''';
      
      final kmlPath = '/var/www/html/kml/slave_$screenNumber.kml';
      final escapedKml = kml.replaceAll('"', '\\"').replaceAll('\$', '\\\$');
      final kmlCommand = 'echo "$escapedKml" > $kmlPath';
      
      await _client!.run(kmlCommand);
      await _forceRefresh('slave_$screenNumber.kml');
      
      debugPrint('Logo sent to slave screen $screenNumber');
      return true;
    } catch (e) {
      debugPrint('Failed to send logo: $e');
      return false;
    }
  }

  Future<bool> clearLogos() async {
    // LOGO CLEANUP: Clear slave screen KMLs
    try {
      const blankKml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document><name>Empty</name></Document>
</kml>''';
      
      final screenNumber = _calculateLeftMostScreen();
      final kmlPath = '/var/www/html/kml/slave_$screenNumber.kml';
      final escapedKml = blankKml.replaceAll('"', '\\"').replaceAll('\$', '\\\$');
      
      await _client!.run('echo "$escapedKml" > $kmlPath');
      await _forceRefresh('slave_$screenNumber.kml');
      
      debugPrint('Logo cleared from slave screen $screenNumber');
      return true;
    } catch (e) {
      debugPrint('Failed to clear logos: $e');
      return false;
    }
  }

  /// Clears all KMLs from the Master
  Future<bool> clearKMLs(SSHClient client) async {
    const blankKml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <name>Empty</name>
  </Document>
</kml>''';
    
    try {
      await client.run("echo '$blankKml' > /var/www/html/kml/master.kml");
      return true;
    } catch (e) {
      debugPrint('Failed to clear KMLs: $e');
      return false;
    }
  }

  /// Flies to a specific location and plays a tour
  /// IMPORTANT: This function demonstrates the correct pattern for flying
  /// For production use, see: .agent/skills/flutter-lg-training-data/03-code-templates/fly-to-tour.dart
  ///
  /// Key Pattern:
  /// 1. Generate KML with gx:Tour + Camera (NOT LookAt, NOT asset-loaded KML)
  /// 2. Write to /var/www/html/kml/master.kml (ONLY injection point for tours)
  /// 3. Call _forceRefresh() to update myplaces.kml
  /// 4. CRITICAL: Wait 1 second for Google Earth to parse the file
  /// 5. Trigger tour via playtour query.txt command
  /// 6. Clear KML when done
  Future<void> fly2() async {
    try {
      // CORRECT: Generate tour KML with gx:Tour structure
      final mumbaiKml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2"
  xmlns:gx="http://www.google.com/kml/ext/2.2">
<Document>
    <name>Mumbai Tour</name>
    <gx:Tour>
        <name>Mumbai Overview</name>
        <gx:Playlist>
            <gx:FlyTo>
                <gx:duration>5000</gx:duration>
                <Camera>
                    <longitude>72.8456</longitude>
                    <latitude>19.0123</latitude>
                    <altitude>1500</altitude>
                    <heading>0</heading>
                    <tilt>45</tilt>
                    <roll>0</roll>
                    <altitudeMode>relativeToGround</altitudeMode>
                </Camera>
            </gx:FlyTo>
        </gx:Playlist>
    </gx:Tour>
</Document>
</kml>''';

      const kmlPath = '/var/www/html/kml/master.kml'; // CORRECT path
      final escapedKml = mumbaiKml.replaceAll('"', '\\"').replaceAll('\$', '\\\$');
      final kmlCommand = 'echo "$escapedKml" > $kmlPath';
      
      await _client!.run(kmlCommand);
      await _forceRefresh('master.kml');
      
      // CRITICAL: Wait for Earth to parse the file
      await Future.delayed(const Duration(seconds: 1));
      
      // Trigger the tour by name
      await playTour('Mumbai Overview');
      
      // Clean up after tour completes
      await Future.delayed(const Duration(seconds: 8));
      await clearKMLs();
    } catch (e) {
      debugPrint('fly2() failed: $e');
    }
  }

  /// Plays a Liquid Galaxy tour
  /// Tour must already be defined in master.kml with <gx:Tour>
  /// This function just triggers playback
  Future<bool> playTour(String tourName) async {
    try {
      final command = 'echo "playtour=$tourName" > /tmp/query.txt';
      await _client!.run(command);
      debugPrint('Tour "$tourName" started');
      return true;
    } catch (e) {
      debugPrint('Failed to play tour: $e');
      return false;
    }
  }

  /// Force refresh of KML for all screens (Master and Slave)
  /// This toggles the refresh interval in myplaces.kml to force Google Earth to reload the KML
  /// 
  /// For MASTER: Uses ~/earth/kml/master/myplaces.kml
  /// For SLAVE: Uses ~/earth/kml/slave/myplaces.kml
  /// 
  /// Pattern:
  /// 1. Add refreshMode=onInterval with 1 second interval
  /// 2. Wait for Google Earth to process
  /// 3. Remove the refresh tag to revert to clean state
  Future<void> _forceRefresh(String kmlFileName) async {
    try {
      final escapedFile = kmlFileName.replaceAll('/', '\/');
      
      // Determine if this is master or slave based on filename
      final isMaster = kmlFileName.contains('master');
      final myplacesPath = isMaster 
          ? '~/earth/kml/master/myplaces.kml'
          : '~/earth/kml/slave/myplaces.kml';
      
      // 1. Force refresh on interval
      final addCommand = 'sed -i "s|<href>[^<]*$escapedFile<\/href>|&<refreshMode>onInterval<\/refreshMode><refreshInterval>1<\/refreshInterval>|" $myplacesPath';
      await _client!.run(addCommand);
      debugPrint('Refresh interval added for $kmlFileName');

      await Future.delayed(const Duration(seconds: 1));

      // 2. Revert to clean state
      final removeCommand = 'sed -i "s|<href>[^<]*$escapedFile<\/href><refreshMode>onInterval<\/refreshMode><refreshInterval>[0-9]\+<\/refreshInterval>|<href>##LG_PHPIFACE##kml/$escapedFile<\/href>|" $myplacesPath';
      await _client!.run(removeCommand);
      debugPrint('Refresh interval removed for $kmlFileName');
    } catch (e) {
      debugPrint('Force refresh failed: $e');
    }
  }
}
```

## 6. Engineering Notes: KML & Tours

### ⚠️ CRITICAL: Master KML Standard
**ALWAYS use `/var/www/html/kml/master.kml` for:**
- Flying and tours (gx:Tour with Camera)
- Interactive KML content (Points, Polygons that respond to clicks)
- Anything that needs immediate refresh and playback

**NEVER use:**
- `master_1.kml` (deprecated, old pattern)
- `slave_*.kml` for flying/tours (slave files are for static overlays only)
- Asset-loaded KML (outdated pattern: `await rootBundle.loadString()`)

### Flying Feature: Reference Implementation
For a complete, production-tested flying implementation, see:
**[→ fly-to-tour.dart template](../../flutter-lg-training-data/03-code-templates/fly-to-tour.dart)**

This template includes:
- `fly2()`: Complete function with gx:Tour structure
- `playTour()`: Tour trigger via query.txt
- `_forceRefresh()`: Unified refresh for master and slave
- `clearKml()`: Clean shutdown of tours
- Critical timing documentation (1 second delay requirement)

### KML Injection Mechanics
To act as the "Master" controller, your app must inject KML directly into the Liquid Galaxy filesystem.
- **Target Path**: `/var/www/html/kml/master.kml` (ONLY valid for tours)
- **Protocol**: SSH `echo` command with proper escaping.
- **Critical Escaping**: Escape double quotes and dollar signs for shell safety.
    ```dart
    final escapedKml = kmlContent.replaceAll('"', '\\"').replaceAll('\$', '\\\$');
    await client.run('echo "$escapedKml" > /var/www/html/kml/master.kml');
    ```

### Tour Orchestration
Running a `gx:Tour` involves a three-step process:
1.  **Upload**: Send the KML containing the `<gx:Tour>` definition to master.kml
2.  **Wait**: Critical 1-second delay for Google Earth to parse the file
3.  **Trigger**: Send the `playtour` query to `/tmp/query.txt` which Liquid Galaxy monitors
    ```dart
    // Step 1: Upload
    const kmlPath = '/var/www/html/kml/master.kml';
    await client.run('echo "$escapedKml" > $kmlPath');
    
    // Step 2: Force refresh
    await _forceRefresh('master.kml');
    
    // Step 3: Wait (CRITICAL - Google Earth needs time to reload)
    await Future.delayed(const Duration(seconds: 1));
    
    // Step 4: Trigger tour by name
    await client.run('echo "playtour=TourName" > /tmp/query.txt');
    ```

### Common Pitfalls
- **Race Conditions**: If you send `playtour` immediately after uploading KML, Google Earth may not have parsed it, causing "Tour not found" silent failure. **Always add a 1-2 second delay.**
- **Permissions**: Ensure SSH user (usually `lg`) has write permissions to `/var/www/html/kml/` and `/tmp/`.
- **Wrong KML Path**: Using `master_1.kml` or `slave_*.kml` for tours will silently fail.
- **Asset Loading**: Loading KML from assets is outdated. Generate KML directly in code.

### Slave Screen Management (Static Overlays & Logos)
Liquid Galaxy allows displaying static overlays on specific screens (Slaves). This is different from tours.

**When to Use Slave KML:**
- Static logos, watermarks, UI elements
- Screen-specific content that doesn't need immediate refresh
- Non-interactive overlays via `<ScreenOverlay>`

**Implementation Pattern:**
1. Create KML with `<ScreenOverlay>` referencing image URL
2. Write to slave-specific file: `/var/www/html/kml/slave_3.kml`
3. Force refresh using `_forceRefresh()` which auto-detects slave path
    ```dart
    final kml = '''...ScreenOverlay referencing http://lg1:81/images/logo.png...''';
    final kmlPath = '/var/www/html/kml/slave_$screenNumber.kml';
    await client.run('echo "$escapedKml" > $kmlPath');
    await _forceRefresh('slave_$screenNumber.kml'); // Uses ~/earth/kml/slave/myplaces.kml
    ```

**Force Refresh for Slave:**
- Slaves use `~/earth/kml/slave/myplaces.kml` (NOT master path)
- Must use `sed` to temporarily add refresh interval
- Same `_forceRefresh()` function handles both master and slave auto-detection
 
## 7. Execution Checklist
1. **Add Dependencies**: `flutter pub add dartssh2 flutter_riverpod google_fonts`.
2. **Setup Permission**: Add internet permission in `AndroidManifest.xml`.
3. **Connection Screen**: The first screen must allow editing connection credentials.
4. **Test**: Use the Mock SSH Server or a real LG Rig.
