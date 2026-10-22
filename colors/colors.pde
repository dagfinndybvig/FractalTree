// colors.pde — a quick tour of color in Processing
// An HSB color wheel, saturation & brightness ramps, and an animated
// lerpColor blend. The hue sweeps continuously so everything cycles.

PImage wheel;
final int R = 220;

void setup() {
  size(960, 620);
  colorMode(HSB, 360, 100, 100);
  wheel = makeWheel(R);
}

void draw() {
  background(0, 0, 12);
  float t = millis() * 0.001;

  // --- 1. HSB color wheel: hue = angle, saturation = distance from center
  imageMode(CENTER);
  image(wheel, 250, 310);

  // Rotating pointer showing the "current" hue
  float hue = (t * 40) % 360;
  float a = radians(hue);
  stroke(0, 0, 100);
  strokeWeight(2);
  line(250, 310, 250 + cos(a) * R, 310 + sin(a) * R);
  noStroke();

  // --- 2. Saturation ramp (top) and brightness ramp (bottom)
  for (int x = 0; x < 380; x++) {
    float v = map(x, 0, 379, 0, 100);
    stroke(hue, v, 100);
    line(500 + x, 180, 500 + x, 280);   // saturation: gray -> full color
    stroke(hue, 100, v);
    line(500 + x, 340, 500 + x, 440);   // brightness: black -> full color
  }

  // --- 3. lerpColor: smooth blend between two opposite hues, animated
  color c1 = color(hue, 90, 95);
  color c2 = color((hue + 180) % 360, 90, 95);
  for (int x = 0; x < 380; x++) {
    float amt = map(x, 0, 379, 0, 1);
    stroke(lerpColor(c1, c2, amt));
    line(500 + x, 500, 500 + x, 560);
  }

  // Labels
  fill(0, 0, 90);
  textAlign(CENTER);
  text("HSB wheel — hue is angle, saturation is radius", 250, 580);
  textAlign(LEFT);
  text("saturation", 500, 165);
  text("brightness", 500, 325);
  text("lerpColor", 500, 485);
}

// Render the wheel once into an image
PImage makeWheel(int r) {
  PImage img = createImage(2 * r, 2 * r, ARGB);
  img.loadPixels();
  for (int y = 0; y < img.height; y++) {
    for (int x = 0; x < img.width; x++) {
      float dx = x - r, dy = y - r;
      float d = sqrt(dx*dx + dy*dy);
      int i = y * img.width + x;
      if (d <= r) {
        float h = degrees(atan2(dy, dx));
        if (h < 0) h += 360;
        img.pixels[i] = color(h, map(d, 0, r, 0, 100), 100);
      } else {
        img.pixels[i] = color(0, 0, 0, 0); // transparent outside the circle
      }
    }
  }
  img.updatePixels();
  return img;
}
