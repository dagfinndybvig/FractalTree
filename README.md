# Processing Workspace

Creative-coding workspace for [Processing](https://processing.org), using a
**portable install** of Processing 4.5.7 (Windows x64). No admin rights were
needed; nothing was installed into Program Files or the registry.

![FractalTree sketch running in the emulator](tree-screen.png)

## Layout

```
C:\Users\dybvig\Coding\Processing\
├── Processing\                  Portable Processing IDE (extracted from the zip)
│   ├── Processing.exe           Launch the IDE
│   └── app\resources\jdk\bin\   Bundled JDK (javac / java) used by the IDE
├── demo\demo.pde                Flow-field particle demo
├── colors\colors.pde            HSB color wheel / ramps / lerpColor demo
├── robot\robot.pde              Robot arm / inverse-kinematics demo
├── tree\tree.pde                Fractal tree with wind + pentatonic chimes
├── FractalTree.apk              Signed APK of the tree sketch (see ANDROID.md)
├── android\                     Gradle project — primary, F-Droid-ready build
├── android-build\               Legacy hand-built pipeline + Android SDK
├── fdroid\                      F-Droid metadata draft
├── tools\                       Helper scripts (launcher-icon generator)
└── README.md / AGENTS.md        Docs for humans and agents
```

## Repository

This workspace is a git repo, pushed to
https://github.com/dagfinndybvig/FractalTree. Tracked: the sketches, docs,
Android build sources, the small build inputs that are painful to recreate
(AndroidX class/res closure, `processing-core.jar`, Sound/JSyn jars, debug
keystore), and the shipped APK. Ignored via `.gitignore`: the portable IDE,
the Android SDK, AndroidMode, AndroidX source aars, and all generated build
intermediates — all re-downloadable or regenerated per `ANDROID.md`. A
fresh clone builds with the gradle project in `android\` (see "Android
build" below) — no legacy-pipeline setup needed.

## Install on Android (FractalTree)

The signed APK ships in this repo and in [Releases](https://github.com/dagfinndybvig/FractalTree/releases)
— always grab the one marked **Latest**. To sideload: copy the APK to the
phone (download link, Drive, etc.), tap it in Files, and allow *this app* to
install unknown apps when Android asks (the permission is per-app, not
global), then tap the APK again. Play Protect may show a warning for
sideloaded apps — expected for anything not from the Play Store. Requires
Android 7.0+ (minSdk 24). Tap the tree to mute.

Note: releases up to 1.1-alpha used a different app id, so they sit
alongside the current app as a separate entry — install 1.2.1-alpha or
newer, then remove the old one.

## Running sketches

- **IDE**: run `Processing\Processing.exe`, open a sketch, press Ctrl+R.
- **Command line**: the portable build does *not* include `processing-java`.
  To run without the IDE, compile a Java-mode class against the core jar:

  ```
  Processing\app\resources\jdk\bin\javac.exe -cp Processing\app\core-4.5.7-*.jar MySketch.java
  Processing\app\resources\jdk\bin\java.exe  -cp Processing\app\core-4.5.7-*.jar;. MySketch
  ```

  The Java-mode class must extend `processing.core.PApplet` and call
  `PApplet.main("ClassName")` from `main`.

## Sketchbook

The IDE's sketchbook is
`C:\Users\dybvig\OneDrive - NTNU\Documents\Processing` — note Documents is
**OneDrive-redirected**, so the plain `C:\Users\dybvig\Documents\Processing`
path is *not* the sketchbook. The authoritative path is `sketchbook.path.four`
in `%APPDATA%\Processing\preferences.txt`. Copies of all sketches live
there too. Three locations: the sketchbook (what the IDE opens), this
directory (baseline/testing copies), and the GitHub repo — keep them in
sync when a sketch changes. The IDE only scans the sketchbook at startup,
so new folders appear in File → Sketchbook after a restart.

## Sound

The **Sound library** (v2.4.0) is installed at
`sketchbook\libraries\sound\` — placed there manually from
https://github.com/processing/processing-sound/releases, since Processing 4
otherwise downloads it on first import. Import with
`import processing.sound.*;`. Note: in Sound 2.x the `Noise` class is
abstract — use `WhiteNoise`, `PinkNoise`, or `BrownNoise`.

## Android notes (tips)

- **Processing for Android** is an official IDE mode: same `setup()`/`draw()`
  code, exported as an APK. We skipped it — the app is built headlessly with
  gradle instead (see below), which is what F-Droid needs.
- **Sideloading**: copy the APK to the phone and tap it in Files; Android
  asks to allow *that specific app* to install unknown apps (per-app, not
  global), then tap the APK again. Play Protect may warn on sideloaded
  APKs — expected and overridable. Wireless ADB
  (Developer options → Wireless debugging → `adb pair`) installs over
  Wi-Fi without a cable.
- **Google Play** (not planned): $25 one-time account, App Bundle (AAB)
  instead of APK, recent target API, and store-listing work (screenshots,
  content rating, privacy policy, Data safety form).
- **Engine choice**: Processing suits sketch-like/artistic 2D apps; libGDX
  is the production-ready Java path if a Play release ever happens.
  p5.js in a mobile browser is the zero-install alternative.

## Android build

The app ships as `FractalTree.apk` (app id
`io.github.dagfinndybvig.fractaltree`, minSdk 24, targetSdk 34, signed
with a local debug key). The primary build is the gradle project in
`android\`:

```
cd android
gradlew.bat assembleRelease
```

with `JAVA_HOME` set to the bundled JDK and `sdk.dir` in
`android\local.properties` (gitignored). On this machine,
`android\gradlebuild.bat assembleRelease` sets both paths for you (it is
machine-specific and not the F-Droid path — their builds use the committed
gradle wrapper). Output:
`android\app\build\outputs\apk\release\app-release.apk` — copy to the
workspace root after emulator verification. The original hand-built
pipeline (`aapt2 link` → `javac --release 8` → `d8` → `zipalign` →
`apksigner`, no gradle) is kept in `android-build\` as frozen reference;
**ANDROID.md** documents both, plus the F-Droid metadata draft in
`fdroid\`.

## Gotchas

- **Sketch folder name must match the `.pde` filename** (`demo\demo.pde`,
  not `mystuff\demo.pde`), or Processing refuses to open it.
- **Reserved words can't be sketch names** — e.g. a sketch cannot be called
  `color`. Use `colors`, `colorwheel`, etc.
- **GUI apps launched from a shell stay attached** to that shell until the
  window closes; a "timeout" while launching `Processing.exe` is usually the
  shell waiting on the GUI, not a failure.
- **The IDE does not hot-reload config or the sketchbook** while running.
- The original portable zip was deleted after extraction. To re-install or
  update, download a portable zip from
  https://github.com/processing/processing4/releases and extract over (or
  beside) `Processing\`.

## License

MIT — see [LICENSE](LICENSE). The bundled dependencies keep their own
licenses: Processing core and the Sound library are LGPL-2.1, JSyn is
LGPL, AndroidX is Apache-2.0.
