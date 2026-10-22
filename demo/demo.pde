// Flow Field — a Processing demo
// Thousands of particles drift through a Perlin noise field,
// leaving luminous trails. Click to scatter them; press any key to save a frame.

int NUM_PARTICLES = 3000;
float time = 0;

Particle[] particles;

void setup() {
  size(960, 600);
  colorMode(HSB, 360, 100, 100, 100);
  background(0);
  particles = new Particle[NUM_PARTICLES];
  for (int i = 0; i < NUM_PARTICLES; i++) {
    particles[i] = new Particle();
  }
}

void draw() {
  // Fade previous frames slightly, so trails glow and dissolve
  noStroke();
  fill(0, 0, 0, 4);
  rect(0, 0, width, height);

  for (Particle p : particles) {
    p.update();
  }
  time += 0.002;
}

void mousePressed() {
  for (Particle p : particles) {
    p.respawn();
  }
  background(0);
}

void keyPressed() {
  saveFrame("flowfield-####.png");
}

class Particle {
  float x, y;
  float hue;

  Particle() {
    respawn();
  }

  void respawn() {
    x = random(width);
    y = random(height);
    hue = random(180, 300);
  }

  void update() {
    // Angle from 3D noise: two spatial dims + time, so the field evolves
    float angle = noise(x * 0.003, y * 0.003, time) * TWO_PI * 2;
    float dx = cos(angle) * 1.8;
    float dy = sin(angle) * 1.8;

    stroke(hue, 80, 90, 35);
    line(x, y, x - dx, y - dy);

    x += dx;
    y += dy;

    if (x < 0 || x > width || y < 0 || y > height) {
      respawn();
    }
  }
}
