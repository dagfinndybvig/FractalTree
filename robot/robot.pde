// robot.pde — an articulated walking robot
// Demonstrates hierarchical transforms: pushMatrix() / rotate() / popMatrix()
// at every joint, so each limb swings in its parent's coordinate space.

float t = 0;

void setup() {
  size(960, 640);
  rectMode(CENTER);
  ellipseMode(CENTER);
}

void draw() {
  background(20, 24, 38);
  t += 0.02;

  // Floor line and shadow
  stroke(45, 52, 75);
  strokeWeight(3);
  line(100, 560, width - 100, 560);
  noStroke();
  fill(0, 70);
  ellipse(width / 2, 562, 240 + sin(t * 2) * 8, 24);

  // Base of the robot, with a walking bob
  pushMatrix();
  translate(width / 2, 560);
  translate(0, sin(t * 2) * 6);
  drawRobot();
  popMatrix();
}

// Everything is drawn relative to the point between the robot's feet.
void drawRobot() {
  // --- Legs: swing opposite each other from the hips
  pushMatrix();
  translate(-28, -70);
  rotate(sin(t * 2) * 0.5);
  leg();
  popMatrix();

  pushMatrix();
  translate(28, -70);
  rotate(sin(t * 2 + PI) * 0.5);
  leg();
  popMatrix();

  // --- Torso: slight sway
  pushMatrix();
  translate(0, -150);
  rotate(sin(t) * 0.03);
  torso();

  // --- Arms: attached to the torso, swing opposite each other
  pushMatrix();
  translate(-62, -55);
  rotate(sin(t * 2 + PI) * 0.7 - 0.15);
  arm();
  popMatrix();

  pushMatrix();
  translate(62, -55);
  rotate(sin(t * 2) * 0.7 + 0.15);
  arm();
  popMatrix();

  // --- Head: attached to the torso, gentle tilt
  pushMatrix();
  translate(0, -105);
  rotate(sin(t * 0.7) * 0.08);
  head();
  popMatrix();

  popMatrix(); // torso
}

void leg() {
  stroke(70, 80, 105);
  strokeWeight(4);
  fill(120, 132, 160);
  rect(0, 35, 26, 70, 8);          // upper+lower leg as one piece
  fill(90, 100, 125);
  rect(6, 66, 40, 14, 6);          // foot, shifted forward
  noStroke();
}

void torso() {
  stroke(70, 80, 105);
  strokeWeight(4);
  fill(140, 152, 180);
  rect(0, 0, 130, 150, 14);        // chest

  fill(90, 100, 125);
  rect(0, 30, 90, 40, 8);          // belly panel

  // Blinking chest light
  float blink = (sin(t * 4) + 1) / 2;
  fill(lerpColor(color(80, 90, 110), color(255, 120, 90), blink));
  ellipse(0, 30, 16, 16);
  noStroke();
}

void arm() {
  stroke(70, 80, 105);
  strokeWeight(4);
  fill(120, 132, 160);
  rect(0, 45, 22, 90, 10);         // arm hangs down from the shoulder joint
  fill(90, 100, 125);
  ellipse(0, 95, 26, 26);          // hand
  noStroke();

  // Shoulder joint cap drawn at the local origin
  fill(160, 172, 200);
  ellipse(0, 0, 30, 30);
}

void head() {
  stroke(70, 80, 105);
  strokeWeight(4);
  fill(150, 162, 190);
  rect(0, -40, 90, 70, 12);        // head sits above the neck joint

  // Eyes glow and blink
  float blink = (sin(t * 4) + 1) / 2;
  fill(lerpColor(color(60, 200, 255), color(200, 255, 255), blink));
  ellipse(-20, -45, 14, 14);
  ellipse(20, -45, 14, 14);

  // Mouth: a small equalizer bar
  fill(90, 100, 125);
  rect(0, -22, 34, 6, 3);
  noStroke();

  // Antenna with a pulsing tip, wobbling in the head's space
  pushMatrix();
  translate(0, -75);
  rotate(sin(t * 3) * 0.25);
  stroke(70, 80, 105);
  strokeWeight(4);
  line(0, 0, 0, -28);
  noStroke();
  float pulse = (sin(t * 6) + 1) / 2;
  fill(lerpColor(color(255, 200, 60), color(255, 240, 150), pulse));
  ellipse(0, -34, 12 + pulse * 4, 12 + pulse * 4);
  popMatrix();
}
