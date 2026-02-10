# Snake Game for LG Multi-Screen Display - Architecture Design

**Goal:** Create a synchronized multi-screen snake game where the snake can grow across multiple vertical screens, with real-time input control and synchronized rendering.

**Target:** 3× vertical LG screens (1080×1920 each) = 1080×5760 total canvas

---

## 🎮 Core Concepts

### Game World
- **World Width:** 1080px (single screen width) - Game stays on one logical screen
- **World Height:** 5760px (3 screens stacked vertically)
- **Camera View:** Each screen shows its viewport of the world
- **Grid:** 30×30px cells for snake movement (36×192 grid)

### Snake Mechanics
- **Starting Position:** Center of screen
- **Movement:** 8 directions (up, down, left, right, diagonals)
- **Growth:** Each food eaten adds 2 segments
- **Speed:** Increases with score (base: 5 segments/second)
- **Collision:** With walls (game over) or self (game over)

### Food Mechanics
- **Spawn:** Random position in world
- **Score:** +10 points per food
- **Respawn:** Immediate after eaten

### Multi-Screen Sync
- **Server Authority:** Game state maintained on server
- **Physics Tick:** 60 FPS server-side simulation
- **Client Rendering:** Each screen renders its viewport via Canvas
- **Input Handling:** Client sends movement commands via Socket.io
- **State Broadcast:** Server broadcasts full game state to all clients

---

## 📁 File Structure

### Server Updates
```
server/
  ├── index.js (extend with snake game handler)
  ├── games/
  │   └── snake.js (new: game logic, physics, collision detection)
  ├── utils.js (existing: keep as is)
```

### Public Visualization
```
public/
  ├── snake/
  │   ├── index.html
  │   ├── sketch.js (canvas rendering)
  │   └── input-handler.js (keyboard/touch input)
```

### Web App Control Panel
```
web_app/app/
  ├── snake/
  │   └── page.tsx (game control dashboard)
```

---

## 🔄 Data Flow

### Server → All Clients (Every 60ms)
```javascript
{
  type: "game:state",
  snake: {
    segments: [[540, 2880], [540, 2910], ...],  // x, y positions
    direction: {x: 0, y: -1},                  // current direction
    nextDirection: {x: 0, y: -1}               // buffered input
  },
  food: [[720, 1440]],  // array of food positions
  score: 150,
  gameState: "playing", // "playing", "paused", "gameover", "idle"
  worldWidth: 1080,
  worldHeight: 5760,
  screenWidth: 1080,
  screenHeight: 1920
}
```

### Client → Server (On Input)
```javascript
{
  type: "game:input",
  direction: {x: 1, y: 0}  // Requested direction
}
```

---

## 🎯 Game States

| State | Description | Actions |
|-------|-------------|---------|
| `idle` | Ready to start | Start button → `playing` |
| `playing` | Active gameplay | Input processed, physics running |
| `paused` | Game paused | Resume button → `playing` |
| `gameover` | Snake hit wall/self | Restart button → `idle` |

---

## 🔧 Implementation Strategy

### Phase 1: Server-Side Game Logic
1. Create `snake.js` game engine
2. Implement collision detection
3. Add physics loop integration
4. Broadcast state to clients every tick

### Phase 2: Client Visualization
1. Create Canvas-based rendering
2. Implement screen-specific viewport clipping
3. Display snake, food, score
4. Add input handling (keyboard/touch)

### Phase 3: Input Control
1. Set up Socket.io input handlers
2. Implement direction queueing (buffer input)
3. Add gamepad support (optional)

### Phase 4: Dashboard UI
1. Create Next.js control page
2. Add game start/pause/reset controls
3. Display live score and statistics
4. Show multiscreen sync status

---

## 🎮 Input Mapping

### Keyboard
- `ArrowUp` / `W` → Direction up
- `ArrowDown` / `S` → Direction down
- `ArrowLeft` / `A` → Direction left
- `ArrowRight` / `D` → Direction right
- `Space` → Pause/Resume
- `R` → Restart

### Touch (Optional)
- Swipe up/down/left/right to control snake

---

## 📊 Score System

- **Base:** +10 per food
- **Speed Multiplier:** Food × (speed / 10)
- **Display:** Real-time on each screen

---

## 🚀 Expected Behavior

1. **Startup:** All screens connect, show "Waiting for Game..."
2. **Start Game:** One screen's input handler sends start → all screens sync
3. **Game Running:** 
   - Server updates positions every ~17ms
   - Each screen renders viewport continuously
   - User input buffered and processed
   - Snake grows smoothly across screens
4. **Food Eaten:** Visual feedback, score increases
5. **Collision:** Game transitions to gameover state
6. **Reset:** Ready for next game

---

## 🔐 Synchronization Guarantees

- **Authoritative Server:** Only server calculates physics
- **Deterministic:** Same input = same output (no floating-point drift)
- **Network Resilient:** Clients catch up if packets drop
- **Low Latency:** 60 FPS server tick = 16.67ms physics update

---

## 📝 Next Steps

1. Implement snake game logic framework
2. Create server event handlers
3. Build Canvas visualization
4. Test on single screen
5. Deploy to multi-screen setup
6. Tune performance and visuals
