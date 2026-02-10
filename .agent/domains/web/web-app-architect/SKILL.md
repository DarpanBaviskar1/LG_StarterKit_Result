---
name: Web App Architect
description: Expert guidance on building modern, complex Web Apps for Liquid Galaxy (Next.js, React, etc.) beyond the starter kit.
---

# Web App Architect for Liquid Galaxy 🌐

## Overview
This skill guides the creation of advanced Web Applications. While the basic starter kit uses Vanilla JS/HTML for simplicity and performance, advanced projects may require frameworks like **Next.js** or **React**.

## 🏗 Architecture

### 1. Framework Selection
- **Next.js**: Recommended for complex dashboards, auth requirements, or heavy data fetching.
- **Vite + React**: Recommended for purely client-side SPAs that need high interactivity.

### 2. Connection Layer
- **Socket.io**: The bridge between the Web UI and the Liquid Galaxy Server.
- **Pattern**: Create a `useSocket` hook.
```javascript
const useSocket = () => {
  // Connect to the Node.js server that manages the LG
}
```

### 3. State Management
- **Zustand**: Lightweight, fast, recommended for 3D state.
- **Context API**: Fine for simple theme/user settings.

### 4. Visuals & 3D
- **React Three Fiber (R3F)**: The React-way to write Three.js. 
- Use `<Canvas>` components for the content.

## 🛠 Best Practices

- **Performance**: Use `Lighthouse` to check metrics.
- **Responsiveness**: TailwindCSS is recommended for rapid styling.
- **Linting**: ESLint with `next/core-web-vitals`.

## 🚀 Execution Checklist
1. **Init**: `npx create-next-app@latest`.
2. **Deps**: `npm install socket.io-client three @react-three/fiber`.
3. **Structure**: Organize by `components/`, `hooks/`, `layouts/`.
4. **Integration**: Connect to the `server/index.js` provided in the starter kit.
