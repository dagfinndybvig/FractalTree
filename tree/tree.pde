// tree.pde — a recursive fractal tree with wind and chimes
// The capstone for pushMatrix/popMatrix/rotate — now with sound:
// filtered noise for the wind, pentatonic chimes as the tree breathes.
// Press 'm' to mute.

import processing.sound.*;

WhiteNoise wind;     // white noise -> lowpass filter = wind
LowPass windFilter;

SinOsc chime;        // always running, silent until triggered
float chimeAmp = 0;

float t = 0;
int lastStep = -1;
boolean muted = false;

// A pentatonic scale — anything in it sounds consonant with anything else
float[] notes = {220.0, 261.63, 293.66, 329.63, 392.0, 440.0, 523.25};

void setup() {
  size(640, 960);   // portrait — matches how it looks on a phone

  // Wind: quiet noise through a lowpass whose cutoff follows the gusts
  wind = new WhiteNoise(this);
  windFilter = new LowPass(this);
  wind.play(0.08);
  windFilter.process(wind, 600);

  // Chime: start silent (amplitude 0), ring it by raising the amplitude
  chime = new SinOsc(this);
  chime.play(440, 0);
}

void draw() {
  background(15, 18, 30);
  t += 0.005;

  // One noise value drives both the sound filter and the branch wobble,
  // so you can *hear* the gusts that bend the tree
  float gust = noise(t * 2, 100);
  windFilter.freq(map(gust, 0, 1, 300, 2500));

  // Ground
  noStroke();
  fill(30, 36, 55);
  rect(0, height - 20, width, 20);

  // Start at the bottom center, grow upward.
  // The 0.72 branching shape grows to 3.5x the trunk length,
  // so trunk = available height / 3.5 fills the screen.
  translate(width / 2, height - 20);
  branch((height - 20) / 3.5);

  // Chime fade-out: shrink the amplitude a little every frame
  if (!muted) {
    if (chimeAmp > 0.001) {
      chimeAmp *= 0.96;
      chime.amp(chimeAmp);
    } else {
      chime.amp(0);
    }
  }
}

void branch(float len) {
  // The tree breathes on its own — a slow sine sweep through the scale
  float baseAngle = map(sin(t * 0.4), -1, 1, 0.05, PI / 2.2);
  float windWobble = (noise(t, len * 0.01) - 0.5) * 0.35;

  // Ring a chime whenever the spread enters a new step of the scale
  int step = int(map(baseAngle, 0.05, PI / 2.2, 0, notes.length));
  step = constrain(step, 0, notes.length - 1);
  if (step != lastStep && !muted) {
    chime.freq(notes[step]);
    chimeAmp = 0.25;
    chime.amp(chimeAmp);
  }
  lastStep = step;

  strokeWeight(len * 0.07);
  stroke(90 + len * 0.2, 70, 50);          // thicker = browner, thin = lighter
  line(0, 0, 0, -len);
  translate(0, -len);

  if (len > 9) {
    float childLen = len * 0.72;

    pushMatrix();
    rotate(baseAngle + windWobble);
    branch(childLen);
    popMatrix();

    pushMatrix();
    rotate(-baseAngle + windWobble);
    branch(childLen);
    popMatrix();
  } else {
    // Leaf / blossom at the tip
    noStroke();
    float bloom = noise(t * 2, len);
    fill(255, 140 + bloom * 60, 170, 180);
    ellipse(0, 0, 7 + bloom * 5, 7 + bloom * 5);
  }
}

void keyPressed() {
  if (key == 'm') {
    muted = !muted;
    if (muted) {
      wind.amp(0);
      chime.amp(0);
      chimeAmp = 0;
    } else {
      wind.amp(0.08);
    }
  }
}
