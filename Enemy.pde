class Enemy3D {
  PVector position;
  float speed;
  int health;
  boolean isHQ;
  int fireCooldown;
  
  Enemy3D(PVector startPosition, boolean isHQ) {
    position = startPosition.copy();
    this.isHQ = isHQ;
    if (isHQ) {
      health = 10;
      speed = 0;  // HQ remains stationary.
      fireCooldown = int(random(100,200));
    } else {
      health = 1;
      speed = random(1, 3);
      fireCooldown = int(random(60,120));
    }
  }
  
  void update() {
    if (!isHQ) {
      // Chase the player
      PVector direction = PVector.sub(planePosition, position);
      direction.normalize();
      position.add(PVector.mult(direction, speed));
    }
    
    // Fire bullets at intervals.
    fireCooldown--;
    if (fireCooldown <= 0) {
      enemyBullets.add(new EnemyBullet3D(position, PVector.sub(planePosition, position)));
      if (isHQ) {
        fireCooldown = int(random(100,200));
      } else {
        fireCooldown = int(random(60,120));
      }
    }
  }
  
  void display() {
    pushMatrix();
      translate(position.x, position.y, position.z);
      if (!isHQ) {
        // Rotate enemy ship so that it faces the player.
        rotateY(atan2(planePosition.x - position.x, planePosition.z - position.z));
      }
      if (isHQ) {
        scale(1.5);  // Make the HQ larger.
        fill(200, 100, 255);  // Distinct purple-ish color.
      } else {
        fill(255, 0, 0);
      }
      
      // Draw enemy spaceship in the same shape as the player's ship.
      box(30, 10, 80);
      fill(150);
      translate(0, 10, 0);
      box(100, 5, 10);
      translate(0, -20, -30);
      box(30, 10, 10);
    popMatrix();
  }
}
