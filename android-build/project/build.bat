@echo off
setlocal enabledelayedexpansion
rem Rebuild FractalTree.apk after a sketch-only change.
rem Reuses base.apk (aapt2 link output), gen\ R classes, and stage\ assets.
rem NOTE: those intermediates are gitignored — on a fresh clone, run the
rem full pipeline (ANDROID.md steps 1-2) once to generate them.
set ROOT=C:\Users\dybvig\Coding\Processing
set BT=%ROOT%\android-build\sdk\build-tools\33.0.2
set AJ=%ROOT%\android-build\sdk\platforms\android-33\android.jar
set CORE=%ROOT%\android-build\core\processing-core.jar
set JDK=%ROOT%\Processing\app\resources\jdk\bin
set XJARS=
for %%f in (%ROOT%\android-build\androidx\classes\*.jar) do set XJARS=!XJARS! "%%f"

cd /d %ROOT%\android-build\project || exit /b 1

echo == javac ==
"%JDK%\javac.exe" --release 8 -classpath "classes;%AJ%;%CORE%;..\sound\sound.jar;..\sound\jsyn-17.1.0.jar!XJARS!" -d classes TreeSketch.java || exit /b 1

echo == jar sketch ==
"%JDK%\jar.exe" cf sketch.jar -C classes . || exit /b 1

echo == d8 ==
"%JDK%\java.exe" -Xmx2g -cp "%BT%\lib\d8.jar" com.android.tools.r8.D8 --release --lib %AJ% --output dex sketch.jar %CORE% ..\sound\sound.jar ..\sound\jsyn-17.1.0.jar !XJARS! || exit /b 1

echo == pack ==
"%JDK%\jar.exe" -ufM base.apk -C stage assets -C dex classes.dex || exit /b 1

echo == zipalign ==
"%BT%\zipalign.exe" -f 4 base.apk aligned.apk || exit /b 1

echo == sign ==
"%JDK%\java.exe" -cp "%BT%\lib\apksigner.jar" com.android.apksigner.ApkSignerTool sign --ks debug.keystore --ks-key-alias treekey --ks-pass pass:android --key-pass pass:android --out FractalTree.apk aligned.apk || exit /b 1

echo == verify dex at root ==
"%JDK%\jar.exe" -tf FractalTree.apk | findstr /x "classes.dex"
if errorlevel 1 exit /b 1

echo BUILD OK
dir FractalTree.apk
