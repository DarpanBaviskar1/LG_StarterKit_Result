# Liquid Galaxy Web Starter Kit

A professional, "Google Developer Expert" level starter kit for building high-performance Liquid Galaxy applications using standard Web Technologies. 

This project demonstrates how to build synchronized multi-screen applications using **Node.js**, **Socket.io**, **Three.js**, and **HTML5 Canvas**. It serves as a reference implementation for maintaining frame-perfect state across multiple displays.

## 🚀 Key Features

*   **Unified State Architecture**: A single "Authoritative Server" calculates physics (3D position, velocity) and broadcasts state to all clients 60 times per second.
*   **Dual Visualizers**:
    *   **2D Mode**: High-performance HTML5 Canvas implementation using coordinate shifting.
    *   **3D Mode**: Advanced Three.js implementation using `camera.setViewOffset` for seamless panoramic rendering across screens.
*   **"The Aquarium" 3D Demo**: Features a transparent glass box, synchronized camera orbiting (parallax), and dynamic view zooming.
*   **Dynamic Rig Sizing**: Configurable for any number of screens (3, 5, 7, etc.) via environment variables.
*   **Virtual Viewport**: Automatically scales the massive Liquid Galaxy resolution (e.g., 3240x1920) to fit inside your laptop screen for easy testing.
*   **Mobile Controller**: A responsive UI to control:
    *   Ball Speed & Color
    *   Gravity Mode
    *   **Live 3D Camera Zoom**
    *   Reset Simulation

## 🛠️ Installation

1.  **Clone the repository**
2.  **Install dependencies**:
    ```bash
    npm install
    ```

## 🏁 Running the Project

### Standard Start (3 Screens)
The default mode assumes a standard 3-screen Liquid Galaxy rig.
```bash
npm start
```

### Custom Rig Size
You can configure the number of screens using the `SCREENS` environment variable. The system will automatically recalculate the world logic and client configurations.
```bash
# Example: 5-Screen Rig
SCREENS=5 npm start
```

### Accessing the Views
Once the server is running (default port `3000`), open your browser:

*   **Controller**: [http://localhost:3000/controller](http://localhost:3000/controller)
*   **2D Visualizer**:
    *   Screen 1: [http://localhost:3000/2d?screen=1](http://localhost:3000/2d?screen=1)
    *   Screen 2: [http://localhost:3000/2d?screen=2](http://localhost:3000/2d?screen=2)
    *   Screen 3: [http://localhost:3000/2d?screen=3](http://localhost:3000/2d?screen=3)
*   **3D Visualizer**:
    *   Screen 1: [http://localhost:3000/3d?screen=1](http://localhost:3000/3d?screen=1)
    *   Screen 2: [http://localhost:3000/3d?screen=2](http://localhost:3000/3d?screen=2)
    *   ...etc

## 🏗️ Architecture Overview

The project follows a **Server-Authoritative** model to ensure synchronization.

### 1. The Server (`server/index.js`)
*   **Physics Loop**: Runs at 60 ticks/second. Updates the position (`x, y, z`) of all objects and the camera (`orbit`).
*   **Dynamic Config**: Intercepts requests to `/common/config.js` to serve custom dimensions based on the `SCREENS` env var.
*   **Broadcaster**: Emits the full `gameState` object to all connected clients.

### 2. The Clients (`public/`)
*   **Dumb Terminals**: The clients do not calculate physics. They simply interpolate and render the data received from the server. This guarantees that Screen 1 and Screen 3 see the ball at the exact same moment.
*   **Config (`public/common/config.js`)**: Shared constants for resolution (Defaults to **1080x1920 Portrait** per screen).
*   **Viewport Scaling**: A custom utility (`viewport.js`) scales the render canvas to fit your dev window while maintaining the strict 1:1 aspect ratio of the production screens.

### 3. The "Magic" (Multi-Screen Rendering)
*   **2D**: Uses `globalOffsetX`. Screen 2 draws the world shifted left by 1080px.
*   **3D**: Uses `camera.setViewOffset()`. This modifies the internal projection matrix to skew the view frustum. It allows 3 separate cameras to act as "slices" of one giant wide-angle lens.

## 📱 Controller Controls
*   **Speed**: Multiplier for the ball's velocity vector.
*   **Color**: Live hex code update for the ball material.
*   **3D Camera Zoom**: Moves the camera closer/further from the center.
    *   *Low value (0.5)*: Close-up action.
    *   *High value (3.0+)*: Full view of the "Aquarium".
*   **Gravity**: Enables Y-axis gravity simulation.

## 🎓 Educational Notes
*   **Best Practices**: Code uses `geometry.dispose()` and `material.dispose()` in Three.js to prevent memory leaks—critical for long-running installations.
*   **CSS Variables**: Styling uses `:root` variables for easy theming.
*   **No Magic Numbers**: All dimensions are derived from the `CONFIG` object, making the system adaptable to different screen resolutions.
