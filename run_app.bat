@echo off
setlocal enabledelayedexpansion

:menu
cls
echo ==========================================
echo    LibraFlow Launch Manager
echo ==========================================
echo 1. Run on Chrome (Debug Mode)
echo 2. Run on Chrome (Release Mode - Faster/Stable)
echo 3. Run on Microsoft Edge (Debug Mode)
echo 4. Run on Microsoft Edge (Release Mode)
echo 5. Run on Connected Phone (Auto-detect)
echo 6. List Connected Devices
echo 7. Exit
echo ==========================================
set /p choice="Enter your choice (1-7): "

if "%choice%"=="1" goto chrome_debug
if "%choice%"=="2" goto chrome_release
if "%choice%"=="3" goto edge_debug
if "%choice%"=="4" goto edge_release
if "%choice%"=="5" goto phone_run
if "%choice%"=="6" goto list_devices
if "%choice%"=="7" goto exit

:chrome_debug
echo Launching on Chrome (Debug)...
flutter run -d chrome --web-hostname 127.0.0.1 --web-port 8080
pause
goto menu

:chrome_release
echo Launching on Chrome (Release)...
flutter run -d chrome --release
pause
goto menu

:edge_debug
echo Launching on Edge (Debug)...
flutter run -d edge --web-hostname 127.0.0.1 --web-port 8081
pause
goto menu

:edge_release
echo Launching on Edge (Release)...
flutter run -d edge --release
pause
goto menu

:phone_run
echo Attempting to run on your phone...
echo (Make sure USB Debugging is enabled)
flutter run
pause
goto menu

:list_devices
echo Checking for connected devices...
flutter devices
pause
goto menu

:exit
echo Goodbye!
exit
