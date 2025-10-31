class EnemyBullet3D {
  PVector position;
  PVector direction;
  float speed = 8;
  
  EnemyBullet3D(PVector startPosition, PVector directionVector) {
    position = startPosition.copy();
    direction = directionVector.copy().normalize();
  }
  
  void update() {
    position.add(PVector.mult(direction, speed));
  }
  
  void display() {
    pushMatrix();
      translate(position.x, position.y, position.z);
      fill(255, 0, 0);
      noStroke();
      sphere(5);
    popMatrix();
  }
  
  boolean isOutOfBounds() {
    return (position.z > 1000 || position.z < -1000 ||
            position.x < -width/2 || position.x > width/2 ||
            position.y < -height/2 || position.y > height/2);
  }
  
  boolean hitsPlayer(PVector playerPos) {
    return (dist(position.x, position.y, position.z, playerPos.x, playerPos.y, playerPos.z) < 20);
  }
}
