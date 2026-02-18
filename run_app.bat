@echo off
echo Cleaning up Flutter processes...
taskkill /F /IM dart.exe 2>nul
taskkill /F /IM flutter.exe 2>nul
timeout /t 2 /nobreak >nul

echo.
echo Running Flutter clean...
flutter clean

echo.
echo Getting dependencies...
flutter pub get

echo.
echo Running the app on Chrome...
flutter run -d chrome
