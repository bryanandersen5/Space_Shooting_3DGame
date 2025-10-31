class Explosion3D {
  PVector position;
  int frame = 0;
  final int maxFrames = 30;
  
  Explosion3D(PVector startPosition) {
    position = startPosition.copy();
  }
  
  void update() {
    frame++;
  }
  
  void display() {
    pushMatrix();
      translate(position.x, position.y, position.z);
      noFill();
      // Fading sphere effect.
      stroke(255, 204, 0, 255 - frame * 8);
      strokeWeight(3);
      sphere(frame * 2);
    popMatrix();
  }
  
  boolean isFinished() {
    return (frame >= maxFrames);
  }
}
