@echo off
set JAVA_HOME=C:\Users\dybvig\Coding\Processing\Processing\app\resources\jdk
set ANDROID_HOME=C:\Users\dybvig\Coding\Processing\android-build\sdk
call "%~dp0..\android-build\gradle-8.9\bin\gradle.bat" %*
