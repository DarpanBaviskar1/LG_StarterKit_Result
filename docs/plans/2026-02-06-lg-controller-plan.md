# Flutter LG Controller App Implementation Plan

**Goal:** Build a production-grade Flutter tablet application to control Liquid Galaxy rigs, featuring power management, content display (Logos, KML), and real-time navigation (ISS Tracker).

**Architecture:** We will use a **Feature-First** Flutter architecture with **Riverpod** for state management. The app observes the **Server-Authoritative** model where the LG Master (server) holds the state (current KML/Tour), and the app (client) simple sends commands and visualizations. The SSH Service will act as the bridge, injecting KML files directly into the rig's filesystem.

**Tech Stack:** Flutter (Dart), flutter_riverpod, dartssh2, Google Earth (KML), generic HTTP/Dio.

**Educational Objectives:**
-   **Separation of Concerns**: Keeping UI, Business Logic (Riverpod), and Infrastructure (SSH) separate.
-   **Asynchronous State**: Managing connection states (Connecting/Connected/Failed) gracefully.
-   **Protocol Engineering**: Understanding how to control remote hardware via low-level SSH commands.
-   **KML Standards**: Learning the correct way to inject Tours vs. Static Overlays in Liquid Galaxy.

---

## 🗺️ Implementation Checklist

- [ ] **Task 1: Project Initialization & Dependencies**
- [ ] **Task 2: SSH Service Implementation (The Core)**
- [ ] **Task 3: Connection Screen & Logic**
- [ ] **Task 4: Dashboard UI Skeleton**
- [ ] **Task 5: Power Management Features**
- [ ] **Task 6: Logo Management (Slave Injection)**
- [ ] **Task 7: KML Management (Master Injection)**
- [ ] **Task 8: Fly To Mumbai (Tour Implementation)**
- [ ] **Task 9: ISS Tracker Integration**

---

### Task 1: Project Initialization & Dependencies

**Files:**
-   Create: `flutter create .` (in new folder or current)
-   Modify: `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`

**Step 1: Architectural Definition**
We need to set up the foundation. We are strictly adding `dartssh2` for communications and `flutter_riverpod` for state. We also need internet permissions to talk to the rig.

**Step 2: Define Logic/Interface**
-   Add dependencies:
    ```yaml
    dependencies:
      flutter_riverpod: ^2.0.0
      dartssh2: ^2.0.0
      google_fonts: ^xxx
    ```
-   Add Permission: `<uses-permission android:name="android.permission.INTERNET"/>`

**Step 3: Verification**
-   Run `flutter pub get`.
-   Run `flutter run` on a device/emulator to ensure blank app starts.

**Step 4: Commit**
```bash
git add .
git commit -m "chore: init project and add dependencies"
```

---

### Task 2: SSH Service Implementation (The Core)

**Files:**
-   Create: `lib/src/core/services/ssh_service.dart`

**Step 1: Architectural Definition**
This is the infrastructure layer. The UI should *never* know about raw SSH sockets. It should just ask `SSHService` to "execute" or "connect". This singleton pattern ensures one connection is shared app-wide.

**Step 2: Define Logic/Interface**
```dart
class SSHService {
  Future<bool> connect(String host, int port, String user, String pass);
  Future<SSHSession?> execute(String command);
  Future<void> disconnect();
  // ... connection state getters
}
```

**Step 3: Verification**
-   We will write a small "scratchpad" test in `test/ssh_test.dart` to try connecting to a mock server or real rig if available.
-   *User Action*: Run the test and see "Connected" printed in console.

**Step 4: Commit**
```bash
git add .
git commit -m "feat: implement basic ssh service"
```

---

### Task 3: Connection Screen & Logic

**Files:**
-   Create: `lib/src/features/connection/presentation/connection_screen.dart`
-   Create: `lib/src/features/connection/data/connection_provider.dart`

**Step 1: Architectural Definition**
The user connects once. This state must persist. We use a Riverpod `StateNotifier` to hold the connection status (Disconnected -> Connecting -> Connected).

**Step 2: Define Logic/Interface**
-   UI: TextFields for Host, Port, User, Password.
-   Logic:
    ```dart
    ref.read(connectionProvider.notifier).connect(host, port...);
    // On success: Navigate to Dashboard
    // On fail: Show SnackBar
    ```

**Step 3: Verification**
-   Run app.
-   Enter credentials.
-   Verify successful navigation to a placeholder Dashboard on success.

**Step 4: Commit**
```bash
git add .
git commit -m "feat: connection screen and provider"
```

---

### Task 4: Dashboard UI Skeleton

**Files:**
-   Create: `lib/src/features/dashboard/presentation/dashboard_screen.dart`

**Step 1: Architectural Definition**
The main control center. We need a layout that works well on tablets (Row with NavigationRail or just large GridView).

**Step 2: Define Logic/Interface**
-   Implement a basic layout with tabs/sections: "Power", "Logos", "Navigation".
-   Use `Glassmorphism` containers for style (Wow factor).

**Step 3: Verification**
-   Visual check: Does it look professional? Are the buttons accessible?

**Step 4: Commit**
```bash
git add .
git commit -m "feat: dashboard ui skeleton"
```

---

### Task 5: Power Management Features

**Files:**
-   Modify: `lib/src/features/dashboard/presentation/dashboard_screen.dart`
-   Modify: `lib/src/core/services/ssh_service.dart` (Add `shutdown`, `reboot` helpers)

**Step 1: Architectural Definition**
These are destructive actions. We must wrap the logic helper functions and UI access with confirmation dialogs.

**Step 2: Define Logic/Interface**
-   Logic:
    ```dart
    // In service
    Future<void> shutdown() async {
       await execute('echo $pass | sudo -S poweroff'); // simplified
    }
    ```
-   UI: Add buttons with `showDialog` confirmation.

**Step 3: Verification**
-   **Critical**: Test on a rig (or mock).
-   Verify: Clicking "Shutdown" -> Confirm -> Sends command (check logs).

**Step 4: Commit**
```bash
git add .
git commit -m "feat: power management ops"
```

---

### Task 6: Logo Management (Slave Injection)

**Files:**
-   Create: `lib/src/features/content/services/logo_service.dart`
-   Modify: `lib/src/features/dashboard/presentation/dashboard_screen.dart`

**Step 1: Architectural Definition**
Logos go to **Slave** screens as `ScreenOverlays`. This requires writing to `slave_X.kml` and Force Refreshing. We are separating this logic into a `LogoService`.

**Step 2: Define Logic/Interface**
-   Input: Image URL.
-   Logic: Generate KML -> `echo` to slave path -> trigger refresh.

**Step 3: Verification**
-   Run app.
-   Click "Send Logo".
-   Verify: Logo appears on the specified slave screen on the rig.

**Step 4: Commit**
```bash
git add .
git commit -m "feat: logo sending and clearing"
```

---

### Task 7: KML Management (Master Injection)

**Files:**
-   Modify: `lib/src/core/services/ssh_service.dart` (Add `clearKml`)
-   Modify: `lib/src/features/dashboard/presentation/dashboard_screen.dart`

**Step 1: Architectural Definition**
Clearing the Master KML removes Tours, Points, and Polygons. This is a "Reset" button for the experience.

**Step 2: Define Logic/Interface**
-   Logic: Write empty KML to `master.kml`.

**Step 3: Verification**
-   Send some KML (or ensure something is on screen).
-   Click "Clear KML".
-   Verify: Google Earth clears the scene.

**Step 4: Commit**
```bash
git add .
git commit -m "feat: clear master kml"
```

---

### Task 8: Fly To Mumbai (Tour Implementation)

**Files:**
-   Create: `lib/src/features/navigation/services/navigation_service.dart`

**Step 1: Architectural Definition**
Flying requires a `gx:Tour` + `gx:FlyTo` + `playtour` query commands. We don't just "LookAt". We create a cinematic movement.

**Step 2: Define Logic/Interface**
-   Logic:
    1.  Construct `Mumbai Tour` KML.
    2.  Upload to `master.kml`.
    3.  Wait 1s.
    4.  Send `playtour=Mumbai Tour`.

**Step 3: Verification**
-   Click "Fly to Mumbai".
-   Verify: Rig smoothly flies to Mumbai (not an instant jump).

**Step 4: Commit**
```bash
git add .
git commit -m "feat: fly to mumbai tour"
```

---

### Task 9: ISS Tracker Integration

**Files:**
-   Create: `lib/src/features/navigation/services/iss_service.dart`
-   Modify: `lib/src/features/dashboard/presentation/dashboard_screen.dart`

**Step 1: Architectural Definition**
The app fetches external data (Client Side), converts it to KML (Logic), and sends it to the Server (Rig). This demonstrates the full data pipeline.

**Step 2: Define Logic/Interface**
-   `Dio` fetch `http://api.open-notify.org/iss-now.json`.
-   Parse Lat/Long.
-   Generate `gx:FlyTo` KML targeting that location.
-   Execute FlyTo logic.

**Step 3: Verification**
-   Click "Track ISS".
-   Verify: App shows "Fetching...", then Rig flies to a random point in the ocean (usually where ISS is).

**Step 4: Commit**
```bash
git add .
git commit -m "feat: iss tracker integration"
```
