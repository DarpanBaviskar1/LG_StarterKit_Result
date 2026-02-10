# Design Document: Flutter LG Controller App
**Date**: 2026-02-06
**Author**: AntiGravity Agent

## 1. Overview
The goal is to build a professional-grade Flutter application to control a Liquid Galaxy rig. The app will serve as a remote controller allowing users to manage the rig (power, navigation) and display content (Logos, Tours, Real-time data).

## 2. Architecture
We will follow the **Feature-First** architecture recommended by the `Flutter Architect` skill.

### 2.1 Technology Stack
-   **Framework**: Flutter (Stable Channel) - Supports Android/iOS tablets.
-   **State Management**: `flutter_riverpod` - For robust, testable state management.
-   **SSH Client**: `dartssh2` - For communicating with the LG rig (Master/Slaves).
-   **API Client**: `dio` or standard `http` - For fetching ISS data.
-   **UI/UX**: Material 3 with Custom Themes (Dark Mode, Glassmorphism).

### 2.2 Directory Structure
```
lib/
├── src/
│   ├── features/
│   │   ├── connection/      # SSH Connection Settings
│   │   ├── dashboard/       # Main Control Interface
│   │   ├── power_ops/       # Shutdown, Reboot, Relaunch
│   │   ├── content/         # Logos, KML Management
│   │   └── navigation/      # FlyTo, Tours, ISS Tracker
│   ├── core/                # Shared utilities (SSH Service, KML Builder)
│   └── app.dart             # Main App Widget
└── main.dart
```

## 3. User Interface (UI) Design
The UI will prioritize the **"Wow Factor"** suitable for large display demos.

-   **Theme**: Cyber/Space aesthetic using dark backgrounds, neon accents (Blue/Purple), and semi-transparent cards (Glassmorphism).
-   **Layout**:
    -   **Connection Screen**: Clean input form for Host, Port, User, Password. Status indicator.
    -   **Dashboard (Main)**:
        -   **Sidebar/Bottom Nav**: Navigation between "Operations", "Navigation", "Tracker".
        -   **Quick Actions**: Prominent buttons for Clear KML, Clear Logo.
        -   **Power Menu**: Accessible but guarded (confirmation dialogs) for Shutdown/Reboot.
    -   **Smart Feedback**: Toasts/Snackbars for "Command Sent", "Connected", "Reconnecting...".

## 4. Detailed Features

### 4.1 Connection & Core
-   **SSH Service**: Singleton managing connection to `lg1` (Master).
-   **Keep-Alive**: Auto-reconnect logic.

### 4.2 Power Management
-   **Shutdown**: `sshpass ... sudo poweroff` on all rigs.
-   **Reboot**: `sshpass ... sudo reboot` on all rigs.
-   **Relaunch**: Kill/Start Liquid Galaxy processes.
-   *Note*: Requires `sshpass` installed on the rig (standard in LG).

### 4.3 Content Management
-   **Show Logo**: Inject KML with `ScreenOverlay` to Slave screens.
-   **Clear Logo**: Send empty KML to Slave screens.
-   **Clear KML**: Send empty KML to Master (clears tours/pois).

### 4.4 Navigation
-   **Fly to Mumbai**:
    -   Generate `gx:Tour` KML in Dart.
    -   Upload to `/var/www/html/kml/master.kml`.
    -   Wait 1s, then trigger `playtour=Mumbai Tour`.
-   **ISS Tracker**:
    -   Fetch current Lat/Long from `http://api.open-notify.org/iss-now.json`.
    -   Generate `gx:FlyTo` KML dynamically.
    -   Update Map View in real-time or on demand.

## 5. Implementation Plan (High Level)
1.  **Project Init**: Create Flutter app, add `dartssh2`, `riverpod`.
2.  **SSH Layer**: Implement `SSHService` class.
3.  **UI Skeleton**: Create Main Layout and Connection Screen.
4.  **Power Ops**: Implement Shutdown/Reboot/Relaunch functions.
5.  **KML Engine**: Create `reference implementation` for sending KMLs.
6.  **Review**: Verify basic connectivity and ops.
7.  **Advanced**: Implement Mumbai Tour and ISS API logic.
8.  **Final Polish**: Animations, Error handling.

## 6. Verification
-   **Mock SSH**: Use a mock server or local VM for initial testing.
-   **Real Rig**: Final verification on actual LG hardware (if available) or strict command logging check.
