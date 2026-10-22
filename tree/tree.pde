// tree.pde — a recursive fractal tree with wind and chimes
// The capstone for pushMatrix/popMatrix/rotate — now with sound:
// filtered noise for the wind, pentatonic chimes as the tree breathes.
// Tap (or 'm') to mute. Double-tap (or 's') shuffles the whole scene:
// speeds, palette, tree shape, musical scale.

import processing.sound.*;

WhiteNoise wind;     // white noise -> lowpass filter = wind
LowPass windFilter;

SinOsc chime;        // always running, silent until triggered
float chimeAmp = 0;

float t = 0;
int lastStep = -1;
boolean muted = false;

// --- everything a double-tap can shuffle ---
float timeStep = 0.005;      // how fast the scene's clock runs
float breatheRate = 0.4;     // speed of the breathing sweep
float gustRate = 2;          // speed of the gust noise
float wobbleAmt = 0.35;      // how much the wind bends branches
float branchRatio = 0.72;    // child length / parent length
float angleMax = PI / 2.2;   // how wide the tree spreads
float chimeDecay = 0.96;     // chime fade-out per frame
float chimeVol = 0.25;
float windVol = 0.08;
float filterLow = 300, filterHigh = 2500;  // wind filter sweep range
float[] notes = {220.0, 261.63, 293.66, 329.63, 392.0, 440.0, 523.25};
int paletteIdx = 0;
float trunkLen = 0;          // set each frame, used for branch coloring

// {background, ground, trunk (thick end), twig (thin end), blossom}
int[][] palettes = {
  {0xFF0F121E, 0xFF1E2437, 0xFF8E4632, 0xFF5C4632, 0xFFFF8CAA},  // midnight
  {0xFF101A16, 0xFF1E3028, 0xFF6E7846, 0xFF465A3C, 0xFFFFE296},  // moss
  {0xFF1E1410, 0xFF32241A, 0xFFA05A2D, 0xFF784628, 0xFFFF783C},  // ember
  {0xFF231420, 0xFF3C2837, 0xFF965A6E, 0xFF6E465A, 0xFFFFB4D2},  // cherry
  {0xFF0A1620, 0xFF182C3A, 0xFF5A788C, 0xFF3C5A6E, 0xFFB4E6FF},  // tide
  {0xFF12161E, 0xFF28303C, 0xFFAAB4C8, 0xFF788296, 0xFFDCEBFF},  // frost
};

// double-tap detection: the first tap schedules a mute toggle, the second
// tap inside the window cancels it and shuffles instead
int lastTap = 0;
boolean mutePending = false;
int muteAt = 0;

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
  background(palettes[paletteIdx][0]);
  t += timeStep;

  // One noise value drives both the sound filter and the branch wobble,
  // so you can *hear* the gusts that bend the tree
  float gust = noise(t * gustRate, 100);
  windFilter.freq(map(gust, 0, 1, filterLow, filterHigh));

  // Ground
  noStroke();
  fill(palettes[paletteIdx][1]);
  rect(0, height - 20, width, 20);

  // Trunk sized so the tree fills the screen: the vertical extent is at
  // most trunk / (1 - branchRatio) (when the branches point straight up)
  trunkLen = (height - 20) * (1 - branchRatio) * 1.02;
  translate(width / 2, height - 20);
  branch(trunkLen);

  // A scheduled single tap becomes a mute toggle now that the
  // double-tap window has passed
  if (mutePending && millis() >= muteAt) {
    mutePending = false;
    toggleMute();
  }

  // Chime fade-out: shrink the amplitude a little every frame
  if (!muted) {
    if (chimeAmp > 0.001) {
      chimeAmp *= chimeDecay;
      chime.amp(chimeAmp);
    } else {
      chime.amp(0);
    }
  }
}

void branch(float len) {
  // The tree breathes on its own — a slow sine sweep through the scale
  float baseAngle = map(sin(t * breatheRate), -1, 1, 0.05, angleMax);
  float windWobble = (noise(t, len * 0.01) - 0.5) * wobbleAmt;

  // Ring a chime whenever the spread enters a new step of the scale
  int step = int(map(baseAngle, 0.05, angleMax, 0, notes.length));
  step = constrain(step, 0, notes.length - 1);
  if (step != lastStep && !muted) {
    chime.freq(notes[step]);
    chimeAmp = chimeVol;
    chime.amp(chimeAmp);
  }
  lastStep = step;

  float shade = constrain(map(len, 9, trunkLen, 0, 1), 0, 1);
  strokeWeight(len * 0.07);
  stroke(lerpColor(palettes[paletteIdx][3], palettes[paletteIdx][2], shade));
  line(0, 0, 0, -len);
  translate(0, -len);

  if (len > 9) {
    float childLen = len * branchRatio;

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
    color bl = palettes[paletteIdx][4];
    fill(red(bl), green(bl) + bloom * 40, blue(bl), 180);
    ellipse(0, 0, 7 + bloom * 5, 7 + bloom * 5);
  }
}

// One tap: mute toggle (delayed so a second tap can cancel it).
// Two taps: shuffle the whole scene.
void tap() {
  int now = millis();
  if (now - lastTap < 350) {
    lastTap = 0;
    mutePending = false;
    shuffleScene();
  } else {
    lastTap = now;
    mutePending = true;
    muteAt = now + 300;
  }
}

void mousePressed() {
  tap();
}

void shuffleScene() {
  timeStep = random(0.003, 0.008);
  breatheRate = random(0.25, 0.6);
  gustRate = random(1.2, 3.0);
  wobbleAmt = random(0.2, 0.5);
  branchRatio = random(0.70, 0.735);   // higher values explode the branch count
  angleMax = random(PI / 3.2, PI / 1.9);
  chimeDecay = random(0.94, 0.975);
  chimeVol = random(0.2, 0.3);
  windVol = random(0.05, 0.11);
  filterLow = random(250, 450);
  filterHigh = random(1800, 3000);
  paletteIdx = int(random(palettes.length));

  // A new minor-pentatonic scale on a random root — anything in the scale
  // still sounds consonant with anything else
  float[] roots = {196.0, 220.0, 246.94, 261.63, 293.66};
  float root = roots[int(random(roots.length))];
  int[] semis = {0, 3, 5, 7, 10, 12, 15};
  for (int i = 0; i < notes.length; i++) {
    notes[i] = root * pow(2, semis[i] / 12.0);
  }

  windFilter.freq(filterLow);
  if (!muted) {
    wind.amp(windVol);
  }
  lastStep = -1;   // let the new scale ring immediately
}

void toggleMute() {
  muted = !muted;
  if (muted) {
    wind.amp(0);
    chime.amp(0);
    chimeAmp = 0;
  } else {
    wind.amp(windVol);
  }
}

void keyPressed() {
  if (key == 'm') {
    toggleMute();
  } else if (key == 's') {
    shuffleScene();
  }
}
