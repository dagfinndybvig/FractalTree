# ANDROID.md — Building Processing sketches into APKs

How `FractalTree.apk` was built from the tree sketch, headlessly, without
Android Mode's GUI — and verified running on an emulator. The toolchain is
reusable for other sketches.

**The primary build is the gradle project in `android\`** (below). The
hand-built pipeline in this document is kept for reference only: it is
**frozen** at the `processing.test.treesketch` era (v1.0 / v1.1-alpha) and
does not build the current sources, which moved to the
`io.github.dagfinndybvig.fractaltree` package in v1.2-alpha. Its
`debug.keystore` is still the signing key for the gradle build.

## Gradle pipeline (primary, F-Droid-ready)

`android\` is a standard gradle project (gradle 8.9, AGP 8.5.2, compileSdk
34, targetSdk 34). Since v1.2-alpha the application id is
`io.github.dagfinndybvig.fractaltree` (the old `processing.test.treesketch`
was Processing's export default — changed before F-Droid inclusion froze it).

- `android\app\src\main\java\io\github\dagfinndybvig\fractaltree\` —
  TreeSketch.java (canonical Android sketch source) + MainActivity.java
- `android\app\src\main\res\` — Theme.Tree + launcher icons (legacy
  mipmap PNGs + adaptive icon; regenerate with `tools\make_icons.py`,
  a PIL script whose palette matches the sketch)
- `android\app\src\main\assets\shaders\` — the core GLES shaders
- `android\app\libs\` — processing-core.jar, sound.jar, jsyn-17.1.0.jar
  (prebuilt from LGPL sources; provenance in this file)
- AndroidX comes from Maven (`appcompat:1.6.1`, `activity:1.6.1`) — the
  hand-built 34-jar closure is NOT used by this pipeline.

Build: `cd android && gradlew.bat assembleRelease` with `JAVA_HOME` set to
the bundled JDK and `sdk.dir` in `android\local.properties` (gitignored).
Output: `android\app\build\outputs\apk\release\app-release.apk`, signed
with the same `debug.keystore` as the hand-built pipeline, so its APKs
install over the hand-built ones. Verify in the emulator per AGENTS.md
before shipping.

Gotcha hit in practice: referencing sources/jars OUTSIDE the module via
`sourceSets`/`files()` made AGP 8.5.2 dex the generated R.jar twice —
`Type androidx.tracing.R is defined multiple times` between
`project_dex_archive/.../androidx/tracing/R.dex` and a hash-named jar in
the same directory. A standard in-module layout avoids it.
`android.disableMinifyLocalDependenciesForLibraries` did NOT help.

F-Droid: metadata draft at `fdroid\metadata\processing.test.treesketch.yml`
(copy into a fork of gitlab.com/fdroid/fdroiddata and open an MR). The
prebuilt jars in `app\libs\` are the expected review friction.

## Layout

```
android-build\
├── AndroidMode.zip              Processing/processing-android release (35 MB)
├── AndroidMode\                 extracted; contains processing-core.zip
│   └── templates\AppActivity.java.tmpl   the MainActivity pattern we copied
├── core\
│   ├── processing-core.jar      Processing's Android runtime (jarred by us)
│   └── assets\shaders\          GLES shaders — must ship inside the APK
├── sound\
│   ├── sound.jar                Sound library — has a pure-Java Android
│   │                            output (JSynAndroidAudioDeviceManager)
│   └── jsyn-17.1.0.jar          JSyn engine; no native lib needed on Android
├── androidx\                    AndroidX dependency closure (see below)
│   ├── aars\                    34 downloaded .aar files
│   ├── classes\                 34 classes.jar extracted from the aars
│   ├── res\                     res/ dirs extracted from the aars
│   ├── compiled\                18 aapt2-compiled res .zip files
│   └── x\                       scratch extraction area
├── sdk\
│   ├── cmdline-tools\latest\    sdkmanager
│   ├── platforms\android-33\    android.jar (compile against this)
│   ├── build-tools\33.0.2\      aapt2, d8, zipalign, apksigner
│   ├── platform-tools\          adb
│   └── system-images\...        emulator image (android-33;default;x86_64)
└── project\
    ├── AndroidManifest.xml      package processing.test.treesketch
    ├── TreeSketch.java          the sketch, Java mode, package processing.test.treesketch
    ├── MainActivity.java        thin AppCompatActivity wrapper (required!)
    ├── res\values\styles.xml    Theme.Tree (fullscreen, AppCompat parent)
    ├── gen\                     25 generated library R.java files
    ├── tmpman\                  per-package dummy manifests for R generation
    ├── ids.txt                  stable resource IDs from the final link
    ├── base.apk                 aapt2 output (manifest + compiled res)
    ├── stage\assets\            core shaders, staged for jar packing
    ├── dex\classes.dex          dexed core + sketch + all AndroidX
    ├── debug.keystore           signing key (store/key pass: android)
    └── FractalTree.apk          final signed APK (also copied to workspace root)
```

## Versions that matter

- Processing Android core: from `processing/processing-android` release
  `latest` (Oct 2025). Its `version.properties` says `android-platform = 33`.
- Platform: `platforms;android-33`. Build-tools: `33.0.2`.
  (The mode's `android-toolslib = 30.3.0` no longer exists in Google's
  repository — use 33.0.2.)
- JDK: Processing's bundled JDK works for everything
  (`Processing\app\resources\jdk`). Set `JAVA_HOME` to it for sdkmanager.
- AndroidX: 34 artifacts (appcompat 1.6.0, **activity 1.6.1** — see gotchas —
  fragment, core, lifecycle, emoji2, etc.). Full list in `androidx\aars\`.
- Sound: `sound.jar` + `jsyn-17.1.0.jar` from the desktop Sound library.
  `sound.jar` contains `JSynAndroidAudioDeviceManager`, which plays through
  Android's AudioTrack in pure Java — no native `.so` needed. Just add both
  jars to the javac classpath and the d8 input list. Only WhiteNoise /
  SinOsc / LowPass class APIs were tested; the mp3/ogg SPI jars are not
  included (add jlayer/jorbis/tritonus/vorbisspi if you need file playback).

## Architecture: the sketch is NOT the activity

In the modern Processing Android core, `PApplet` implements `ActivityAPI`
and is **not** an Activity. Launching a sketch class directly from the
manifest throws `ClassCastException`. Instead:

- `MainActivity` extends `AppCompatActivity`, creates the sketch, wraps it
  in a `PFragment`, and calls `fragment.setView(frame, this)`. Copy the
  pattern from `AndroidMode\templates\AppActivity.java.tmpl`.
- The manifest's launcher activity is `.MainActivity`, not the sketch.
- This drags in the full AndroidX appcompat dependency closure — all 34
  jars must be on the javac classpath and dexed into the APK.
- The app theme must be an AppCompat theme. We define `Theme.Tree` in
  `project\res\values\styles.xml` (parent `Theme.AppCompat.Light.NoActionBar`,
  `windowFullscreen=true`) because appcompat 1.6.0 lacks the fullscreen
  variant the mode's template references.

## Rebuild pipeline

The legacy pipeline below is frozen reference material (see top). For all
current work, sketch-only changes are just: edit
`android\app\src\main\java\...\TreeSketch.java`, run
`android\gradlew.bat assembleRelease`, verify in the emulator.

Run from `android-build\project\`, with `BT` = build-tools dir, `AJ` =
`android.jar`, `CORE` = `processing-core.jar`, JDK = bundled JDK,
`XJARS` = all 34 `androidx\classes\*.jar`, `XRES` = all 18
`androidx\compiled\*.zip`:

```bat
:: 1. Link manifest + all compiled resources (project res + AndroidX res)
aapt2 link -I %AJ% --manifest AndroidManifest.xml -o base.apk ^
  --auto-add-overlay --emit-ids ids.txt %XRES%

:: 2. Generate R.java for every library package (see gotcha below)
::    For each of the 25 packages: write a dummy manifest with that package,
::    sed-replace "processing.test.treesketch:" with "<pkg>:" in ids.txt,
::    then aapt2 link --java gen --stable-ids <that file> %XRES%

:: 3. Compile sketch + wrapper + all generated R classes
javac --release 8 -classpath %AJ%;%CORE%;<34 androidx jars> ^
  -d classes TreeSketch.java MainActivity.java gen\**\*.java
jar cf sketch.jar -C classes .

:: 4. Dex core + sketch + sound + all AndroidX together
java -Xmx2g -cp %BT%\lib\d8.jar com.android.tools.r8.D8 ^
  --release --lib %AJ% --output dex sketch.jar %CORE% ^
  ..\sound\sound.jar ..\sound\jsyn-17.1.0.jar %XJARS%

:: 5. Pack, align, sign
::    stage\assets\ holds the core shaders; -C keeps paths forward-slashed
::    and puts classes.dex at the APK root (both critical — see gotchas)
jar -ufM base.apk -C stage assets -C dex classes.dex
zipalign -f 4 base.apk aligned.apk
java -cp %BT%\lib\apksigner.jar com.android.apksigner.ApkSignerTool sign ^
  --ks debug.keystore --ks-key-alias treekey ^
  --ks-pass pass:android --key-pass pass:android --out FractalTree.apk aligned.apk
```

New signing key (only if lost): `keytool -genkeypair -keystore
debug.keystore -alias treekey -storepass android -keypass android -dname
"CN=Tree Debug,O=Processing,C=US" -keyalg RSA -keysize 2048 -validity 10000`.

## Emulator verification

```
emulator -avd testdev -no-window -no-audio -no-boot-anim -gpu swiftshader_indirect
adb install -r project\FractalTree.apk
adb shell am start -n processing.test.treesketch/.MainActivity
adb logcat -d -s AndroidRuntime:E        :: must stay empty
adb shell pidof processing.test.treesketch
adb exec-out screencap -p > screen.png   :: confirm the tree renders
```

Verified 2026-10-21: app installs, launches, renders the animated tree,
and stays alive with an empty error log.

## Gotchas (all hit in practice)

- **`classes.dex` must be at the APK root.** `jar -ufM app.apk dex\classes.dex`
  silently keeps the `dex/` prefix, producing an APK with no root dex —
  the phone reports "package invalid". Always use
  `jar -ufM app.apk -C dex classes.dex` and confirm with `jar -tf`.
- **`aapt2 link -A` on Windows writes backslash entry paths**
  (`assets/shaders\file.glsl`), which Android cannot read. Don't use `-A`;
  stage assets in a folder and add them with
  `jar -ufM app.apk -C stage assets` instead (the jar tool uses `/`).
- **`d8.bat` / `apksigner.bat` are broken on modern JDKs** — they pass
  `-Djava.ext.dirs`, removed after Java 8. Always invoke the jars directly:
  `java -cp %BT%\lib\d8.jar com.android.tools.r8.D8 ...` and
  `java -cp %BT%\lib\apksigner.jar com.android.apksigner.ApkSignerTool ...`.
- **`processing-core.zip` is an exploded class tree**, not a jar. Jar the
  `processing\` folder yourself; keep `assets\` out of the jar.
- **`PApplet` is not an Activity in the modern core** — you need the
  `MainActivity` + `PFragment` wrapper and the whole AndroidX closure
  (see "Architecture" above). Old tutorials that make the sketch class the
  launcher activity are for Processing 3.
- **Library R classes must be generated per package.** AndroidX libraries
  look up their own resources through their own `R` class
  (`androidx.startup.R$string`, `androidx.appcompat.R$attr`, ...). For each
  of the 25 packages, run `aapt2 link` with a dummy manifest using that
  package name. **Critical:** the stable-ids file from step 1 uses the app
  package prefix (`processing.test.treesketch:...`); sed-replace that prefix
  with the library package before each link, or resource IDs mismatch and
  you get `Resources$NotFoundException` at runtime.
- **androidx.activity must be 1.6.1, not 1.2.4.** appcompat 1.6.0 calls
  `ViewTreeOnBackPressedDispatcherOwner`, which only exists in activity
  1.6.x. Mixing versions gives `ClassNotFoundException` /
  `NoSuchFieldError view_tree_on_back_pressed_dispatcher_owner` at launch.
  When upgrading an artifact, re-extract its res/, recompile its res zip,
  re-link base.apk, and regenerate ALL R.java files.
- **androidx.loader is easy to miss.** fragment 1.5.x only touches
  `androidx.loader.app.LoaderManager` when a fragment view is destroyed —
  i.e. on a configuration change (rotation, window resize). A headless
  emulator test that never rotates will pass; the app then crashes on a
  real device the first time the screen rotates. Include
  `androidx/loader/loader/1.1.0` (classes only, no res) in the closure.
- **Desktop-only APIs don't exist in the Android core**: `displayDensity()`
  is absent — size things from `width`/`height` instead.
- **`fullScreen()` goes in `settings()`**; `size()` is ignored on Android.
- **`mouseX`/`mouseY` follow touch** automatically — no code changes needed.
- d8 prints warnings about `android.support.wearable.*` and
  `androidx.versionedparcelable` missing — benign.
- `javac --release 8` is required (not `-source/-target`): the bundled JDK
  is 21 and d8 rejects newer class files without desugaring flags.

## Adapting another sketch

1. Copy the sketch into a `.java` class extending `PApplet` (Java mode —
   `int()` casts become `(int)`, `color` becomes `int`, etc.), in package
   `processing.test.<name>`.
2. `MainActivity.java` needs only the sketch class name changed.
3. Change `android:package`, `android:label` (app name on the phone) in
   `AndroidManifest.xml`. Bump `android:versionCode` for updates.
4. Re-run the pipeline. The R-generation step (step 2) is sketch-independent
   — reuse `tmpman\` and `ids.txt` as-is.

## Status

- **App icon**: done since v1.2-alpha (adaptive icon + legacy mipmaps,
  tree glyph in the sketch's palette).
- **App id**: `io.github.dagfinndybvig.fractaltree` since v1.2-alpha
  (was Processing's export default `processing.test.treesketch`).
- **F-Droid**: metadata draft ready in `fdroid\metadata\`; the submission
  merge request to gitlab.com/fdroid/fdroiddata is the remaining step.
  Expected review topic: the prebuilt jars in `app\libs\` (LGPL,
  provenance documented above).
- **Releases**: GitHub releases are the distribution channel. Convention:
  tag `v<version>`, push the tag, then
  `gh release create <tag> <apk>#FractalTree.apk --latest` — shipped
  versions are full releases (GitHub's "Latest" badge follows the most
  recent non-prerelease). Current: v1.2.1-alpha (versionCode 4).
- **AAB / Play Store**: not planned — distribution is GitHub releases
  and (hopefully) F-Droid.
