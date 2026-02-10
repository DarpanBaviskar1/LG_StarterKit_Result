/**
 * Snake Game Engine
 * Server-side game logic with collision detection and physics
 */

export class SnakeGame {
  constructor(worldWidth, worldHeight, cellSize = 30) {
    this.worldWidth = worldWidth;
    this.worldHeight = worldHeight;
    this.cellSize = cellSize;

    // Grid dimensions
    this.gridWidth = Math.floor(worldWidth / cellSize);
    this.gridHeight = Math.floor(worldHeight / cellSize);

    // Game state
    this.state = "idle"; // idle, playing, paused, gameover
    this.score = 0;
    this.level = 1;
    this.frameCount = 0;

    // Snake
    this.snake = {
      segments: [], // Array of {x, y} positions in pixels
      direction: { x: 0, y: -1 }, // Current direction
      nextDirection: { x: 0, y: -1 }, // Buffered next direction
      moveTimer: 0,
      moveInterval: 1000 / 5, // 5 moves per second (base speed)
    };

    // Food
    this.food = [];
    this.foodSpawnChance = 0.02; // Spawn new food 2% of ticks

    this.reset();
  }

  reset() {
    this.state = "idle";
    this.score = 0;
    this.level = 1;
    this.frameCount = 0;

    // Initialize snake in center
    const centerX = Math.floor((this.worldWidth / 2) / this.cellSize) * this.cellSize;
    const centerY = Math.floor((this.worldHeight / 2) / this.cellSize) * this.cellSize;

    this.snake = {
      segments: [
        { x: centerX, y: centerY },
        { x: centerX, y: centerY + this.cellSize },
        { x: centerX, y: centerY + this.cellSize * 2 },
      ],
      direction: { x: 0, y: -1 },
      nextDirection: { x: 0, y: -1 },
      moveTimer: 0,
      moveInterval: 1000 / 5,
    };

    this.food = this.spawnFood(3); // Start with 3 food items
  }

  start() {
    if (this.state === "idle") {
      this.state = "playing";
      this.reset();
    }
  }

  pause() {
    if (this.state === "playing") {
      this.state = "paused";
    }
  }

  resume() {
    if (this.state === "paused") {
      this.state = "playing";
    }
  }

  gameOver() {
    this.state = "gameover";
  }

  // Input handling from clients
  setNextDirection(directionObject) {
    const { x, y } = directionObject;

    // Prevent 180-degree turn (moving backwards)
    if (x === -this.snake.direction.x && y === -this.snake.direction.y) {
      return;
    }

    this.snake.nextDirection = { x, y };
  }

  // Physics update - called every tick (e.g., every 16.67ms at 60 FPS)
  update(deltaTime = 16.67) {
    if (this.state !== "playing") return;

    this.frameCount++;
    this.snake.moveTimer += deltaTime;

    // Check if it's time to move the snake
    if (this.snake.moveTimer >= this.snake.moveInterval) {
      this.snake.moveTimer = 0;

      // Apply buffered direction
      this.snake.direction = this.snake.nextDirection;

      // Calculate new head position
      const head = this.snake.segments[0];
      const newHead = {
        x: head.x + this.snake.direction.x * this.cellSize,
        y: head.y + this.snake.direction.y * this.cellSize,
      };

      // Check collisions
      if (this.checkWallCollision(newHead)) {
        this.gameOver();
        return;
      }

      if (this.checkSelfCollision(newHead)) {
        this.gameOver();
        return;
      }

      // Add new head
      this.snake.segments.unshift(newHead);

      // Check food collision
      const foodIndex = this.checkFoodCollision(newHead);
      if (foodIndex !== -1) {
        // Eat food - grow by 2 segments
        this.food.splice(foodIndex, 1);
        this.score += 10;
        this.snake.segments.push(
          { x: this.snake.segments[this.snake.segments.length - 1].x, y: this.snake.segments[this.snake.segments.length - 1].y },
          { x: this.snake.segments[this.snake.segments.length - 1].x, y: this.snake.segments[this.snake.segments.length - 1].y }
        );

        // Increase difficulty slightly
        this.snake.moveInterval = Math.max(100, 1000 / (5 + this.score / 50));

        // Spawn new food
        this.spawnNewFood();
      } else {
        // No food eaten - remove tail
        this.snake.segments.pop();
      }

      // Periodically spawn new food
      if (Math.random() < this.foodSpawnChance && this.food.length < 5) {
        this.spawnNewFood();
      }
    }
  }

  checkWallCollision(pos) {
    return (
      pos.x < 0 ||
      pos.x >= this.worldWidth ||
      pos.y < 0 ||
      pos.y >= this.worldHeight
    );
  }

  checkSelfCollision(pos) {
    return this.snake.segments.some(
      (segment) => segment.x === pos.x && segment.y === pos.y
    );
  }

  checkFoodCollision(pos) {
    return this.food.findIndex(
      (f) => f.x === pos.x && f.y === pos.y
    );
  }

  spawnFood(count = 1) {
    const foods = [];
    for (let i = 0; i < count; i++) {
      foods.push(this.getRandomFoodPosition());
    }
    return foods;
  }

  spawnNewFood() {
    const newFood = this.getRandomFoodPosition();
    if (!this.food.some((f) => f.x === newFood.x && f.y === newFood.y)) {
      this.food.push(newFood);
    }
  }

  getRandomFoodPosition() {
    let x, y, isValidPosition;

    do {
      isValidPosition = true;
      x = Math.floor(Math.random() * this.gridWidth) * this.cellSize;
      y = Math.floor(Math.random() * this.gridHeight) * this.cellSize;

      // Don't spawn food on snake
      if (this.snake.segments.some((s) => s.x === x && s.y === y)) {
        isValidPosition = false;
      }

      // Don't spawn food on existing food
      if (this.food.some((f) => f.x === x && f.y === y)) {
        isValidPosition = false;
      }
    } while (!isValidPosition);

    return { x, y };
  }

  // Get public game state for broadcasting
  getState() {
    return {
      state: this.state,
      score: this.score,
      level: this.level,
      snake: {
        segments: this.snake.segments,
        direction: this.snake.direction,
      },
      food: this.food,
      worldWidth: this.worldWidth,
      worldHeight: this.worldHeight,
      cellSize: this.cellSize,
      frameCount: this.frameCount,
    };
  }
}

export default SnakeGame;
