import { CONFIG, getScreenId } from '../common/config.js';

let canvas, ctx, debugDiv, scoreDiv, gameOverlay;
let screenId = 1;
let socket = null;

// Wait for DOM to be ready
function initDOM() {
  canvas = document.getElementById('canvas');
  debugDiv = document.getElementById('debug');
  scoreDiv = document.getElementById('score');
  gameOverlay = document.getElementById('gameOverlay');
  
  if (!canvas || !debugDiv || !scoreDiv || !gameOverlay) {
    console.error('ERROR: Required DOM elements not found');
    return false;
  }
  
  ctx = canvas.getContext('2d');
  if (!ctx) {
    console.error('ERROR: Canvas context failed');
    return false;
  }
  
  try {
    screenId = getScreenId();
  } catch (e) {
    console.warn('Could not get screen ID, using default:', e);
    screenId = 1;
  }
  
  return true;
}

// Game state
let gameState = {
  state: 'idle',
  score: 0,
  snake: { segments: [], direction: { x: 0, y: -1 } },
  food: [],
  worldWidth: 1080,
  worldHeight: 5760,
  cellSize: 30
};

// Screen viewport
let screenViewport = {
  x: 0,
  y: (screenId - 1) * CONFIG.SCREEN_HEIGHT,
  width: CONFIG.SCREEN_WIDTH,
  height: CONFIG.SCREEN_HEIGHT
};

// Color scheme
const COLORS = {
  background: '#000000',
  snake: '#00FF00',
  snakeHead: '#00FF99',
  food: '#FF0000',
  foodGlow: '#FF6600',
  grid: '#0A3A0A',
  text: '#00FF00'
};

function setup() {
  // Set canvas to screen dimensions
  canvas.width = CONFIG.SCREEN_WIDTH;
  canvas.height = CONFIG.SCREEN_HEIGHT;

  connectSocket();
}

function connectSocket() {
  // Wait for socket.io to be available
  if (typeof io === 'undefined') {
    console.error('ERROR: Socket.io library not loaded');
    debugDiv.textContent = `Screen ${screenId} | Error: Socket.io not loaded`;
    setTimeout(connectSocket, 1000); // Retry after 1 second
    return;
  }
  
  const serverUrl = CONFIG.SERVER_URL || 'http://localhost:3000';
  console.log(`Connecting to: ${serverUrl}`);
  socket = io(serverUrl);

  socket.on('connect', () => {
    console.log('✓ Connected to server');
    if (debugDiv) debugDiv.textContent = `Screen ${screenId} | Connected | Waiting for game...`;
  });

  socket.on('disconnect', () => {
    console.log('✗ Disconnected from server');
    if (debugDiv) debugDiv.textContent = `Screen ${screenId} | Disconnected`;
  });

  socket.on('snake:state', (state) => {
    gameState = state;
    if (scoreDiv) scoreDiv.textContent = `Score: ${gameState.score}`;

    if (gameState.state === 'gameover') {
      showGameOverlay(gameState.score);
    } else if (gameState.state === 'playing') {
      hideGameOverlay();
    }

    // Update debug info
    const snakeLength = gameState.snake.segments.length;
    if (debugDiv) debugDiv.textContent = `Screen ${screenId} | Status: ${gameState.state.toUpperCase()} | Length: ${snakeLength} | Score: ${gameState.score}`;
  });

  // Handle connection errors
  socket.on('connect_error', (error) => {
    console.error('Connection error:', error);
    if (debugDiv) debugDiv.textContent = `Screen ${screenId} | Error: ${error.message}`;
  });
}

function showGameOverlay(score) {
  if (!gameOverlay) return;
  gameOverlay.style.display = 'block';
  const titleEl = document.getElementById('overlayTitle');
  const msgEl = document.getElementById('overlayMessage');
  if (titleEl) titleEl.textContent = 'Game Over!';
  if (msgEl) msgEl.textContent = `Final Score: ${score}`;
}

function hideGameOverlay() {
  if (!gameOverlay) return;
  gameOverlay.style.display = 'none';
}

function restartGame() {
  if (!socket) {
    console.error('Socket not connected');
    return;
  }
  hideGameOverlay();
  socket.emit('snake:reset');
  socket.emit('snake:start');
}

function startGame() {
  if (!socket) {
    console.error('Socket not connected');
    return;
  }
  socket.emit('snake:reset');
  socket.emit('snake:start');
}

function draw() {
  // Safety check - ensure canvas and context are available
  if (!canvas || !ctx) {
    console.warn('Canvas not ready, retrying...');
    requestAnimationFrame(draw);
    return;
  }

  // Clear canvas
  ctx.fillStyle = COLORS.background;
  ctx.fillRect(0, 0, canvas.width, canvas.height);

  // Draw grid (optional, for reference)
  drawGrid();

  // Draw food
  drawFood();

  // Draw snake
  drawSnake();

  // Draw score
  drawScore();

  requestAnimationFrame(draw);
}

function drawGrid() {
  ctx.strokeStyle = COLORS.grid;
  ctx.lineWidth = 0.5;

  const cellSize = gameState.cellSize;

  // Vertical lines
  for (let x = 0; x <= canvas.width; x += cellSize) {
    ctx.beginPath();
    ctx.moveTo(x, 0);
    ctx.lineTo(x, canvas.height);
    ctx.stroke();
  }

  // Horizontal lines
  for (let y = 0; y <= canvas.height; y += cellSize) {
    ctx.beginPath();
    ctx.moveTo(0, y);
    ctx.lineTo(canvas.width, y);
    ctx.stroke();
  }
}

function drawFood() {
  gameState.food.forEach((food) => {
    const screenPos = worldToScreen(food.x, food.y);
    if (isInViewport(screenPos.x, screenPos.y)) {
      // Draw food with glow effect
      ctx.fillStyle = COLORS.foodGlow;
      ctx.beginPath();
      ctx.arc(
        screenPos.x + gameState.cellSize / 2,
        screenPos.y + gameState.cellSize / 2,
        gameState.cellSize / 2 + 3,
        0,
        Math.PI * 2
      );
      ctx.fill();

      ctx.fillStyle = COLORS.food;
      ctx.beginPath();
      ctx.arc(
        screenPos.x + gameState.cellSize / 2,
        screenPos.y + gameState.cellSize / 2,
        gameState.cellSize / 2,
        0,
        Math.PI * 2
      );
      ctx.fill();
    }
  });
}

function drawSnake() {
  if (!gameState.snake.segments || gameState.snake.segments.length === 0) return;

  // Draw body
  gameState.snake.segments.forEach((segment, index) => {
    const screenPos = worldToScreen(segment.x, segment.y);

    if (isInViewport(screenPos.x, screenPos.y)) {
      // Head is brighter
      if (index === 0) {
        ctx.fillStyle = COLORS.snakeHead;
        // Draw head with glow
        ctx.shadowColor = COLORS.snakeHead;
        ctx.shadowBlur = 10;
      } else {
        ctx.fillStyle = COLORS.snake;
        ctx.shadowColor = 'rgba(0, 255, 0, 0.5)';
        ctx.shadowBlur = 5;
      }

      // Draw segment as square
      ctx.fillRect(
        screenPos.x,
        screenPos.y,
        gameState.cellSize,
        gameState.cellSize
      );

      // Remove shadow for performance
      ctx.shadowColor = 'rgba(0, 0, 0, 0)';
      ctx.shadowBlur = 0;
    }
  });
}

function drawScore() {
  // Score is already drawn in HTML, but we could add more info here
  ctx.fillStyle = COLORS.text;
  ctx.font = 'bold 14px monospace';
  ctx.shadowColor = COLORS.snakeHead;
  ctx.shadowBlur = 5;
  ctx.fillText(
    `Screen ${screenId} |  FPS: ${Math.round(1000 / 16.67)}`,
    10,
    canvas.height - 10
  );
  ctx.shadowColor = 'rgba(0, 0, 0, 0)';
  ctx.shadowBlur = 0;
}

function worldToScreen(worldX, worldY) {
  return {
    x: worldX,
    y: worldY - screenViewport.y
  };
}

function isInViewport(screenX, screenY) {
  return (
    screenX + gameState.cellSize > 0 &&
    screenX < canvas.width &&
    screenY + gameState.cellSize > 0 &&
    screenY < canvas.height
  );
}

// --- Input Handling ---
const keys = {};

window.addEventListener('keydown', (e) => {
  keys[e.key] = true;

  let direction = null;

  switch (e.key) {
    case 'ArrowUp':
    case 'w':
    case 'W':
      direction = { x: 0, y: -1 };
      e.preventDefault();
      break;
    case 'ArrowDown':
    case 's':
    case 'S':
      direction = { x: 0, y: 1 };
      e.preventDefault();
      break;
    case 'ArrowLeft':
    case 'a':
    case 'A':
      direction = { x: -1, y: 0 };
      e.preventDefault();
      break;
    case 'ArrowRight':
    case 'd':
    case 'D':
      direction = { x: 1, y: 0 };
      e.preventDefault();
      break;
    case ' ':
      // Space to start game if idle
      if (gameState.state === 'idle') {
        startGame();
      } else if (gameState.state === 'playing') {
        if (socket) socket.emit('snake:pause');
      } else if (gameState.state === 'paused') {
        if (socket) socket.emit('snake:resume');
      }
      e.preventDefault();
      break;
    case 'r':
    case 'R':
      if (gameState.state === 'gameover') {
        restartGame();
      }
      e.preventDefault();
      break;
  }

  if (direction) {
    if (socket) socket.emit('snake:input', direction);
  }
});

window.addEventListener('keyup', (e) => {
  keys[e.key] = false;
});

// Touch/Swipe support (optional)
let touchStartX = 0;
let touchStartY = 0;

if (canvas) {
  canvas.addEventListener('touchstart', (e) => {
    touchStartX = e.touches[0].clientX;
    touchStartY = e.touches[0].clientY;
  });

  canvas.addEventListener('touchmove', (e) => {
    if (!socket) return; // Skip touch processing if socket not ready
    
    e.preventDefault();
    const touchX = e.touches[0].clientX;
    const touchY = e.touches[0].clientY;
    const deltaX = touchX - touchStartX;
    const deltaY = touchY - touchStartY;

    if (Math.abs(deltaX) > Math.abs(deltaY)) {
      // Horizontal swipe
      if (deltaX > 50) {
        socket.emit('snake:input', { x: 1, y: 0 }); // Right
        touchStartX = touchX;
      } else if (deltaX < -50) {
        socket.emit('snake:input', { x: -1, y: 0 }); // Left
        touchStartX = touchX;
      }
    } else {
      // Vertical swipe
      if (deltaY > 50) {
        socket.emit('snake:input', { x: 0, y: 1 }); // Down
        touchStartY = touchY;
      } else if (deltaY < -50) {
        socket.emit('snake:input', { x: 0, y: -1 }); // Up
        touchStartY = touchY;
      }
    }
  });
}

// Expose functions globally
window.restartGame = restartGame;
window.startGame = startGame;

// Start the application when DOM is ready
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', () => {
    console.log('🐍 Snake Game - DOM Ready');
    if (initDOM()) {
      setup();
      draw();
    } else {
      console.error('Failed to initialize DOM');
    }
  });
} else {
  console.log('🐍 Snake Game - DOM Already Ready');
  if (initDOM()) {
    setup();
    draw();
  } else {
    console.error('Failed to initialize DOM');
  }
}
