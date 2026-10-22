package processing.test.treesketch;

import processing.core.*;
import processing.sound.*;

// The tree sketch, Android edition: fullScreen() instead of size(),
// sound via the Sound library's built-in Android audio output.
// mouseX/mouseY follow touch automatically; tap toggles mute.
public class TreeSketch extends PApplet {
    WhiteNoise wind;
    LowPass windFilter;
    SinOsc chime;
    float chimeAmp = 0;
    boolean muted = false;

    float t = 0;
    int lastStep = -1;
    float[] notes = {220.0f, 261.63f, 293.66f, 329.63f, 392.0f, 440.0f, 523.25f};

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
        background(15, 18, 30);
        t += 0.005f;

        // One noise value drives both the sound filter and the branch wobble
        float gust = noise(t * 2, 100);
        windFilter.freq(map(gust, 0, 1, 300, 2500));

        noStroke();
        fill(30, 36, 55);
        rect(0, height - 40, width, 40);

        // Trunk sized to fill the screen: the old 0.72 branching shape grows
        // to 3.5x the trunk length, so trunk = available height / 3.5
        translate(width / 2f, height - 40);
        branch((height - 40) / 3.5f);

        if (!muted) {
            if (chimeAmp > 0.001f) {
                chimeAmp *= 0.96f;
                chime.amp(chimeAmp);
            } else {
                chime.amp(0);
            }
        }
    }

    void branch(float len) {
        float baseAngle = map(sin(t * 0.4f), -1, 1, 0.05f, PI / 2.2f);
        float windWobble = (noise(t, len * 0.01f) - 0.5f) * 0.35f;

        int step = (int) map(baseAngle, 0.05f, PI / 2.2f, 0, notes.length);
        step = constrain(step, 0, notes.length - 1);
        if (step != lastStep && !muted) {
            chime.freq(notes[step]);
            chimeAmp = 0.25f;
            chime.amp(chimeAmp);
        }
        lastStep = step;

        strokeWeight(len * 0.07f);
        stroke(90 + len * 0.2f, 70, 50);
        line(0, 0, 0, -len);
        translate(0, -len);

        if (len > 9) {
            float childLen = len * 0.72f;

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
            fill(255, 140 + bloom * 60, 170, 180);
            ellipse(0, 0, 7 + bloom * 5, 7 + bloom * 5);
        }
    }

    public void mousePressed() {
        muted = !muted;
        if (muted) {
            wind.amp(0);
            chime.amp(0);
            chimeAmp = 0;
        } else {
            wind.amp(0.08f);
        }
    }
}
