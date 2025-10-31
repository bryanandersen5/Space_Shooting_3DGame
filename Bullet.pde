class Bullet3D {
  PVector position;
  PVector direction;
  float speed = 10;
  
  // Constructor that accepts a starting position and a direction.
  // This allows the bullet to follow your spaceship's facing.
  Bullet3D(PVector startPosition, PVector dir) {
    position = startPosition.copy();
    direction = dir.copy();
    direction.normalize();  // Ensure a consistent speed regardless of vector magnitude
  }
  
  // Optionally, you can keep the original constructor (which defaults to moving straight along -Z).
  Bullet3D(PVector startPosition) {
    position = startPosition.copy();
    // Set a default direction: moving in the negative Z direction.
    direction = new PVector(0, 0, -1);
  }
  
  void update() {
    // Moves the bullet along its direction vector.
    position.add(PVector.mult(direction, speed));
  }
  
  void display() {
    pushMatrix();
      translate(position.x, position.y, position.z);
      fill(255, 255, 0);
      sphere(5);
    popMatrix();
  }
  
  boolean isOutOfBounds() {
    return position.z < -1000 || position.z > 1000;
  }
}
