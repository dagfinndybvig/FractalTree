package io.github.dagfinndybvig.fractaltree;

import processing.core.*;
import processing.sound.*;

// The tree sketch, Android edition: fullScreen() instead of size(),
// sound via the Sound library's built-in Android audio output.
// mouseX/mouseY follow touch automatically. Single tap toggles mute;
// double-tap shuffles the whole scene: speeds, palette, tree shape,
// musical scale.
public class TreeSketch extends PApplet {
    WhiteNoise wind;
    LowPass windFilter;
    SinOsc chime;
    float chimeAmp = 0;
    boolean muted = false;

    float t = 0;
    int lastStep = -1;

    // --- everything a double-tap can shuffle ---
    float timeStep = 0.005f;
    float breatheRate = 0.4f;
    float gustRate = 2;
    float wobbleAmt = 0.35f;
    float branchRatio = 0.72f;
    float angleMax = PI / 2.2f;
    float chimeDecay = 0.96f;
    float chimeVol = 0.25f;
    float windVol = 0.08f;
    float filterLow = 300, filterHigh = 2500;
    float[] notes = {220.0f, 261.63f, 293.66f, 329.63f, 392.0f, 440.0f, 523.25f};
    int paletteIdx = 0;
    float trunkLen = 0;

    // {background, ground, trunk (thick end), twig (thin end), blossom}
    int[][] palettes = {
        {0xFF0F121E, 0xFF1E2437, 0xFF8E4632, 0xFF5C4632, 0xFFFF8CAA},  // midnight
        {0xFF101A16, 0xFF1E3028, 0xFF6E7846, 0xFF465A3C, 0xFFFFE296},  // moss
        {0xFF1E1410, 0xFF32241A, 0xFFA05A2D, 0xFF784628, 0xFFFF783C},  // ember
        {0xFF231420, 0xFF3C2837, 0xFF965A6E, 0xFF6E465A, 0xFFFFB4D2},  // cherry
        {0xFF0A1620, 0xFF182C3A, 0xFF5A788C, 0xFF3C5A6E, 0xFFB4E6FF},  // tide
        {0xFF12161E, 0xFF28303C, 0xFFAAB4C8, 0xFF788296, 0xFFDCEBFF},  // frost
    };

    // double-tap detection: the first tap schedules a mute toggle, the
    // second tap inside the window cancels it and shuffles instead
    int lastTap = 0;
    boolean mutePending = false;
    int muteAt = 0;

    public void settings() {
        fullScreen();
    }

    public void setup() {
        wind = new WhiteNoise(this);
        windFilter = new LowPass(this);
        wind.play(0.08f);
        windFilter.process(wind, 600);

        chime = new SinOsc(this);
        chime.play(440, 0);
    }

    public void draw() {
        background(palettes[paletteIdx][0]);
        t += timeStep;

        // One noise value drives both the sound filter and the branch wobble
        float gust = noise(t * gustRate, 100);
        windFilter.freq(map(gust, 0, 1, filterLow, filterHigh));

        noStroke();
        fill(palettes[paletteIdx][1]);
        rect(0, height - 40, width, 40);

        // Trunk sized so the tree fills the screen: the vertical extent is
        // at most trunk / (1 - branchRatio) (branches pointing straight up)
        trunkLen = (height - 40) * (1 - branchRatio) * 1.02f;
        translate(width / 2f, height - 40);
        branch(trunkLen);

        // A scheduled single tap becomes a mute toggle now that the
        // double-tap window has passed
        if (mutePending && millis() >= muteAt) {
            mutePending = false;
            toggleMute();
        }

        if (!muted) {
            if (chimeAmp > 0.001f) {
                chimeAmp *= chimeDecay;
                chime.amp(chimeAmp);
            } else {
                chime.amp(0);
            }
        }
    }

    void branch(float len) {
        float baseAngle = map(sin(t * breatheRate), -1, 1, 0.05f, angleMax);
        float windWobble = (noise(t, len * 0.01f) - 0.5f) * wobbleAmt;

        int step = (int) map(baseAngle, 0.05f, angleMax, 0, notes.length);
        step = constrain(step, 0, notes.length - 1);
        if (step != lastStep && !muted) {
            chime.freq(notes[step]);
            chimeAmp = chimeVol;
            chime.amp(chimeAmp);
        }
        lastStep = step;

        float shade = constrain(map(len, 9, trunkLen, 0, 1), 0, 1);
        strokeWeight(len * 0.07f);
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
            noStroke();
            float bloom = noise(t * 2, len);
            int bl = palettes[paletteIdx][4];
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

    public void mousePressed() {
        tap();
    }

    void shuffleScene() {
        timeStep = random(0.003f, 0.008f);
        breatheRate = random(0.25f, 0.6f);
        gustRate = random(1.2f, 3.0f);
        wobbleAmt = random(0.2f, 0.5f);
        branchRatio = random(0.70f, 0.735f);   // higher values explode the branch count
        angleMax = random(PI / 3.2f, PI / 1.9f);
        chimeDecay = random(0.94f, 0.975f);
        chimeVol = random(0.2f, 0.3f);
        windVol = random(0.05f, 0.11f);
        filterLow = random(250, 450);
        filterHigh = random(1800, 3000);
        paletteIdx = (int) random(palettes.length);

        // A new minor-pentatonic scale on a random root — anything in the
        // scale still sounds consonant with anything else
        float[] roots = {196.0f, 220.0f, 246.94f, 261.63f, 293.66f};
        float root = roots[(int) random(roots.length)];
        int[] semis = {0, 3, 5, 7, 10, 12, 15};
        for (int i = 0; i < notes.length; i++) {
            notes[i] = root * pow(2, semis[i] / 12.0f);
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
}
