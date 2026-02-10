# Liquid Galaxy Antigravity Kit 🌌

A professional, "Google Developer Expert" level starter kit for building high-performance Liquid Galaxy applications using **Standard Web Technologies** or **Flutter**.

## 🚀 Unified Features

- **Multi-Platform Support**:
  - **Web**: Node.js Server + Socket.io + Three.js for synchronized displays.
  - **Flutter**: A native Controller App template with SSH and KML automation.
- **Agent-Hardened**: Includes a suite of AI Agent Skills (`.agent/dist`) to guide you from idea to graduation.
- **Professional Tooling**: ESLint, Prettier, Dart Analyze, and Vitest pre-configured.

## 📱 The Flutter Controller (`flutter_app/`)

A standalone starter project for building tablet controllers.

- **Features**:
  - SSH Connectivity (using `dartssh2`)
  - KML Builder Utility
  - Feature-First Architecture
  - Riverpod State Management
  - External API Integration Example (ISS Tracker)
- **Run**:
  ```bash
  cd flutter_app
  flutter pub get
  flutter run
  ```

## 🌐 The Web Visualizer (`server/` + `public/`)

The classic synchronized visualizer.

- **Run**:
  ```bash
  npm install
  npm start
  ```

## 🤖 Expert Agent Pipeline

This repository includes custom AI skills:

1.  **`flutter-architect`**: Guidance on building Flutter controllers.
2.  **`web-app-architect`**: Guidance on React/Next.js/Three.js apps.
3.  **`lg-code-reviewer`**: Audits both JS and Dart code for quality.
4.  **`lg-plan-writer`**: Creates implementation plans.

## 🎓 Educational Notes

- **Separation of Concerns**: The Flutter app handles *Control*, the Web app handles *Visualization*.
- **Best Practices**: We enforce strict linting to ensure your code is readable and maintainable.
