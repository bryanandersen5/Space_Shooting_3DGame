import ddf.minim.*;
import java.io.FileWriter;
import java.io.IOException;

Minim minim;
AudioPlayer backgroundMusic;
AudioSample shootSound;
AudioSample explosionSound;

// -----------------------------------------------------
// Global Variables
// -----------------------------------------------------
PFont myFont;
PVector planePosition;
float mapSize = 150;  // Size of the mini-map
float mapMargin = 10; // Margin from the screen's edge
float planeYaw = 0;       // Horizontal rotation
float planePitch = 0;     // Vertical rotation
float planeRoll = 0;      // Rolling (bank) effect for turning
float planeSpeed = 5;
float rotationSpeed = 0.03;

ArrayList<Bullet3D> bullets;
ArrayList<Enemy3D> enemies;
ArrayList<EnemyBullet3D> enemyBullets;
ArrayList<Explosion3D> explosions;
PVector[] stars3D;        // Starfield array

// Flags for turning
boolean turnLeft = false, turnRight = false, pitchUp = false, pitchDown = false;

boolean gameStarted = false;
boolean gameOver = false;
int lives = 5, score = 0;

float cameraZOffset = 300;  // Fixed offset for the chase camera

// Hit and explosion tracking
boolean isHit = false;
int hitFrame = 0;
boolean playerCrashed = false;
Explosion3D playerExplosion = null;
int explosionStartFrame = 0;

boolean isPaused = false;

// -----------------------------------------------------
// Setup & Initialization
// -----------------------------------------------------
void setup() {
  size(800, 600, P3D);
  myFont = createFont("Arial", 32);
  textFont(myFont);
  
  // Initialize Minim and load sound files
  minim = new Minim(this);
  backgroundMusic = minim.loadFile("background_music.mp3", 2048);
  backgroundMusic.loop();  // Loop the background music continuously
  shootSound = minim.loadSample("shoot.mp3", 512);
  explosionSound = minim.loadSample("explosion.mp3", 512);
  
  initializeGame();
}

void initializeGame() {
  planePosition = new PVector(0, 0, 0);
  planeYaw = 0;
  planePitch = 0;
  planeRoll = 0;
  
  bullets = new ArrayList<Bullet3D>();
  enemies = new ArrayList<Enemy3D>();
  enemyBullets = new ArrayList<EnemyBullet3D>();
  explosions = new ArrayList<Explosion3D>();
  
  // Create a starfield (300 stars)
  stars3D = new PVector[300];
  for (int i = 0; i < stars3D.length; i++) {
    stars3D[i] = new PVector(random(-width, width), random(-height, height), random(-500, 500));
  }
  
  isHit = false;
  hitFrame = 0;
  playerCrashed = false;
  playerExplosion = null;
  explosionStartFrame = 0;
  
  gameOver = false;
  score = 0;
  lives = 5;
  spawnEnemies3D();
}

// -----------------------------------------------------
// Main Draw Loop
// -----------------------------------------------------
void draw() {
  // --- 1. Start Screen (2D) ---
  if (!gameStarted) {
    background(0);
    fill(255);
    textAlign(CENTER, CENTER);
    textSize(32);
    // Draw text in the center
    text("START GAME", width/2, height/2);
    displayStartButton();
    return;  // Exit draw; wait for the player to start the game.
  }
  
  // --- 2. Game Mode (3D) ---
  if (isPaused) {
    hint(DISABLE_DEPTH_TEST);  // Make sure text isn't hidden by 3D elements
    resetMatrix();             // Reset transforms to identity
    camera();                  // Reset the camera
    textAlign(CENTER);
    fill(255);
    textSize(32);
    text("GAME PAUSED!", width / 2, height / 2 - 40);
    textSize(24);
    text("Press \"P\" to continue", width / 2, height / 2 + 20);
    hint(ENABLE_DEPTH_TEST);   // Re-enable depth for 3D rendering
    return;  // Skip the rest of the draw function to prevent gameplay updates
  }
  
  // --- 3. Game Logic & Updates (This part runs only when not paused) ---
  resetMatrix();
  perspective(PI/3.0, float(width)/float(height), 0.1, 10000);
  
  background(0);
  lights();
  
  // Set the chase camera behind the ship.
  camera(planePosition.x,
         planePosition.y - 200,
         planePosition.z + cameraZOffset,
         planePosition.x,
         planePosition.y,
         planePosition.z,
         0, 1, 0);
  
  // Draw the 3D starfield background.
  drawStars3D();
  
  // Update ship movement if not crashed.
  if (!playerCrashed) {
    movePlane3D();
  }
  
  // Draw the player's ship or the explosion
  if (!playerCrashed) {
    drawPlayerShip();
  } else {
    if (playerExplosion != null) {
      playerExplosion.update();
      playerExplosion.display();
    }
    // After about 2 seconds (120 frames), transition to game over.
    if (frameCount - explosionStartFrame >= 120) {
      gameOver = true;
    }
  }
  
  // Update and display other game objects.
  manageBullets3D();
  if (!playerCrashed) {
    manageEnemies3D();
    manageEnemyBullets3D();
    checkCollisions3D();
  }
  manageExplosions3D();
  
  // --- 4. Overlay: HUD or Game Over (2D) ---
  pushMatrix();
    if (gameOver) {
      displayGameOver();
    } else if (enemies.size() == 0 && !gameOver) {
      displayGameWin();
    } else {
      drawHUD();
    }
  popMatrix();
}

// -----------------------------------------------------
// 3D Drawing Functions
// -----------------------------------------------------
void drawStars3D() {
  for (PVector star : stars3D) {
    pushMatrix();
      translate(star.x, star.y, star.z);
      fill(255);
      noStroke();
      sphere(2);
    popMatrix();
    // Simulate forward star movement.
    star.z += 10;
    if (star.z > 0) {
      star.z = -500;
    }
  }
}

void drawPlayerShip() {
  pushMatrix();
    translate(planePosition.x, planePosition.y, planePosition.z);
    rotateY(-planeYaw + PI);
    rotateX(-planePitch);
    rotateZ(planeRoll);
    
    // Flash orange if hit.
    if (isHit && frameCount - hitFrame < 6) {
      fill(255, 165, 0);
    } else {
      fill(50, 200, 255);
    }
    box(30, 10, 80);
    
    // Draw wings.
    fill(150);
    translate(0, 10, 0);
    box(100, 5, 10);
    
    // Draw tail wing.
    translate(0, -20, -30);
    box(30, 10, 10);
  popMatrix();
  
  // Reset hit flag after display.
  if (frameCount - hitFrame >= 6) {
    isHit = false;
  }
}

void movePlane3D() {
  if (turnLeft)   planeYaw -= rotationSpeed;
  if (turnRight)  planeYaw += rotationSpeed;
  if (pitchUp)    planePitch -= rotationSpeed;
  if (pitchDown)  planePitch += rotationSpeed;
  
  // Calculate a smooth roll effect when turning.
  float targetRoll = 0;
  if (turnLeft) {
    targetRoll = PI / 6;
  } else if (turnRight) {
    targetRoll = -PI / 6;
  }
  planeRoll = lerp(planeRoll, targetRoll, 0.1);
  
  planePosition.x += sin(planeYaw) * cos(planePitch) * planeSpeed;
  planePosition.y += sin(planePitch) * planeSpeed;
  planePosition.z -= cos(planeYaw) * cos(planePitch) * planeSpeed;
}

void spawnEnemies3D() {
  enemies.clear();
  // Add one "HQ" enemy.
  enemies.add(new Enemy3D(new PVector(0, 0, -1000), true));
  
  int smallCount = 10;
  float radius = 400;
  for (int i = 0; i < smallCount; i++) {
    float angle = TWO_PI / smallCount * i;
    float ex = cos(angle) * radius;
    float ez = -1000 + sin(angle) * radius;
    enemies.add(new Enemy3D(new PVector(ex, 0, ez), false));
  }
}

void manageBullets3D() {
  for (int i = bullets.size() - 1; i >= 0; i--) {
    Bullet3D b = bullets.get(i);
    b.update();
    b.display();
    if (b.isOutOfBounds()) {
      bullets.remove(i);
    }
  }
}

void manageEnemies3D() {
  for (int i = enemies.size() - 1; i >= 0; i--) {
    Enemy3D e = enemies.get(i);
    e.update();
    e.display();
  }
}

void manageEnemyBullets3D() {
  for (int i = enemyBullets.size() - 1; i >= 0; i--) {
    EnemyBullet3D eb = enemyBullets.get(i);
    eb.update();
    eb.display();
    if (eb.isOutOfBounds()) {
      enemyBullets.remove(i);
    } else if (eb.hitsPlayer(planePosition)) {
      isHit = true;
      hitFrame = frameCount;
      lives--;
      enemyBullets.remove(i);
      if (lives <= 0) {
        playerCrashed = true;
        explosionStartFrame = frameCount;
        playerExplosion = new Explosion3D(planePosition);
      }
    }
  }
}

void manageExplosions3D() {
  for (int i = explosions.size() - 1; i >= 0; i--) {
    Explosion3D exp = explosions.get(i);
    exp.update();
    exp.display();
    if (exp.isFinished()) {
      explosions.remove(i);
    }
  }
}

void checkCollisions3D() {
  for (int i = bullets.size() - 1; i >= 0; i--) {
    Bullet3D b = bullets.get(i);
    for (int j = enemies.size() - 1; j >= 0; j--) {
      Enemy3D e = enemies.get(j);
      if (dist(b.position.x, b.position.y, b.position.z,
               e.position.x, e.position.y, e.position.z) < 20) {
        explosions.add(new Explosion3D(e.position));
        // Trigger explosion sound effect
        explosionSound.trigger();
        e.health--;
        bullets.remove(i);
        if (e.health <= 0) {
          enemies.remove(j);
          score += (e.isHQ) ? 5 : 1;
        }
        break;
      }
    }
  }
}

// -----------------------------------------------------
// HUD / 2D UI Functions
// -----------------------------------------------------
void drawHUD() {
  pushMatrix();
    hint(DISABLE_DEPTH_TEST);  // Make sure text isn't hidden by 3D elements
    resetMatrix();             // Reset transforms to identity
    camera();                  // Reset the camera
    textAlign(RIGHT, TOP);
    fill(255);
    textSize(24);
    text("Score: " + score, width - 10, 10);
    
    textAlign(LEFT, TOP);
    text("Lives: " + lives, 10, 10);
    hint(ENABLE_DEPTH_TEST);   // Re-enable depth for 3D rendering
    drawMiniMap();
  popMatrix();
}

void drawMiniMap() {
  // Define the position of the map (bottom-right)
  float mapX = width - mapSize - mapMargin;
  float mapY = height - mapSize - mapMargin;
  
  // Draw the map border (white circle)
  noFill();
  stroke(255);
  strokeWeight(2);
  ellipse(mapX + mapSize / 2, mapY + mapSize / 2, mapSize, mapSize);
  
  float offsetX = 75;
  float offsetY = 150;  // Move the dots down

  // Draw the user's spaceship as a blue dot
  float userMapX = map(planePosition.x, -500, 500, mapX - mapSize / 3, mapX + mapSize / 3);
  userMapX += offsetX;
  float userMapY = map(planePosition.z, -500, 500, mapY - mapSize / 3, mapY + mapSize / 3);
  userMapY += offsetY;  // Apply vertical offset (move down)
  fill(0, 0, 255);  // Blue color
  noStroke();
  ellipse(userMapX, userMapY, 8, 8);  // Blue dot for player's ship
  
  // Draw enemy ships as red dots
  for (Enemy3D enemy : enemies) {
    float enemyMapX = map(enemy.position.x, -500, 500, mapX - mapSize / 3, mapX + mapSize / 3);
    enemyMapX += offsetX;
    float enemyMapY = map(enemy.position.z, -500, 500, mapY - mapSize / 3, mapY + mapSize / 3);
    enemyMapY += offsetY;  // Apply vertical offset (move down)
    fill(255, 0, 0);  // Red color
    ellipse(enemyMapX, enemyMapY, 8, 8);  // Red dot for enemy ship
  }
  
  // Draw enemy HQ as a purple dot
  for (Enemy3D enemy : enemies) {
    if (enemy.isHQ) {
      float hqMapX = map(enemy.position.x, -500, 500, mapX - mapSize / 3, mapX + mapSize / 3);
      hqMapX += offsetX;
      float hqMapY = map(enemy.position.z, -500, 500, mapY - mapSize / 3, mapY + mapSize / 3);
      hqMapY += offsetY;  // Apply vertical offset (move down)
      fill(128, 0, 128);  // Purple color
      ellipse(hqMapX, hqMapY, 10, 10);  // Purple dot for enemy HQ
    }
  }
  
  // Debugging: Draw a small circle at the center of the mini-map for testing.
  fill(255, 255, 0);
  ellipse(mapX + mapSize / 2, mapY + mapSize / 2, 5, 5); // Mini-map center

  // Visualize and adjust the scale for enemies (debug lines)
  for (Enemy3D enemy : enemies) {
    float debugX = map(enemy.position.x, -500, 500, mapX - mapSize / 3, mapX + mapSize / 3);
    debugX += offsetX;
    float debugY = map(enemy.position.z, -500, 500, mapY - mapSize / 3, mapY + mapSize / 3);
    debugY += offsetY;  // Apply vertical offset (move down)
    stroke(255, 255, 0);  // Yellow color for debug lines
    line(debugX - 3, debugY - 3, debugX + 3, debugY + 3); // Debug diagonal line
    line(debugX + 3, debugY - 3, debugX - 3, debugY + 3); // Debug diagonal line
  }
}

void displayStartButton() {
  background(0);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(32);
  // Draw text in the center
  text("START GAME", width/2, height/2);
}

void displayGameOver() {
  fill(0, 150); // Semi-transparent black
  //rectMode(CENTER);
  //noStroke();
  //rect(width / 2, height / 2, 400, 200);

  //fill(255);
  //textAlign(CENTER, CENTER);
  //textSize(48);
  //text("GAME OVER", width / 2, height / 2 - 40);
  
  //textSize(32);
  //text("Final Score: " + score, width / 2, height / 2 + 20);

  //textSize(24);
  //text("Click to Restart", width / 2, height / 2 + 60);
  
  
  pushMatrix();
    hint(DISABLE_DEPTH_TEST);  // Make sure text isn't hidden by 3D elements
    resetMatrix();             // Reset transforms to identity
    camera();                  // Reset the camera
    textAlign(CENTER);
    fill(255);
    textSize(48);
    text("GAME OVER", width / 2, height / 2 - 40);
  
    textSize(32);
    text("Final Score: " + score, width / 2, height / 2 + 20);
    
    textSize(24);
    text("Click to Restart", width / 2, height / 2 + 60);
    hint(ENABLE_DEPTH_TEST);   // Re-enable depth for 3D rendering
    drawMiniMap();
  popMatrix();
}

void displayGameWin() {
  hint(DISABLE_DEPTH_TEST);  // Make sure text isn't hidden by 3D elements
    resetMatrix();             // Reset transforms to identity
    camera();                  // Reset the camera
    textAlign(CENTER);
    fill(255);
    textSize(48);
    text("YOU WON", width / 2, height / 2 - 40);
  
    textSize(32);
    text("Final Score: " + score, width / 2, height / 2 + 20);
    
    textSize(24);
    text("Click to Restart", width / 2, height / 2 + 60);
    hint(ENABLE_DEPTH_TEST);   // Re-enable depth for 3D rendering
}

// -----------------------------------------------------
// Input Handling
// -----------------------------------------------------
void keyPressed() {
  if (!gameStarted) return;
  
  // Check for 'P' to toggle pause
  if (key == 'p' || key == 'P') {
    togglePause();
  }
  
  if (key == 's' || key == 'S') {
    // Save spaceship coordinates when 'S' key is pressed
    writeCoordinatesToFile();
  }
  
  if (keyCode == UP)    pitchUp = true;
  if (keyCode == DOWN)  pitchDown = true;
  if (keyCode == LEFT)  turnLeft = true;
  if (keyCode == RIGHT) turnRight = true;

  // Fire a bullet when space is pressed.
  if (key == ' ' && gameStarted) {
    PVector forward = new PVector(
      sin(planeYaw) * cos(planePitch),
      sin(planePitch),
      -cos(planeYaw) * cos(planePitch)
    );
    forward.normalize();
    PVector bulletStart = PVector.add(planePosition, PVector.mult(forward, 50));
    bullets.add(new Bullet3D(bulletStart, forward));
    // Trigger shooting sound
    shootSound.trigger();
  }
}

void keyReleased() {
  if (keyCode == UP)    pitchUp = false;
  if (keyCode == DOWN)  pitchDown = false;
  if (keyCode == LEFT)  turnLeft = false;
  if (keyCode == RIGHT) turnRight = false;
}

void mousePressed() {
  if (!gameStarted) {
    // In the start screen, a mouse click starts the game.
    gameStarted = true;
    initializeGame();
  } else if (gameOver) {
    // On game over, a click restarts the game.
    gameOver = false;
    initializeGame();
  } else if (enemies.size() == 0 && !gameOver) {
    gameOver = false;
    initializeGame();
  }
}

void writeCoordinatesToFile() {
  // Get the spaceship's coordinates
  float x = planePosition.x;
  float y = planePosition.y;
  float z = planePosition.z;

  // Create or open the file to write
  try {
    FileWriter writer = new FileWriter(dataPath("spaceship_coordinates.txt"), true);
    writer.write("Spaceship Coordinates: x=" + x + ", y=" + y + ", z=" + z + "\n");
    writer.close();
  } catch (IOException e) {
    println("Error writing to file: " + e.getMessage());
  }
}

void togglePause() {
  isPaused = !isPaused;
}

void stop() {
  backgroundMusic.close();
  shootSound.close();
  explosionSound.close();
  minim.stop();
  super.stop();
}
