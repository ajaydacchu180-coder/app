@echo off
set FLUTTER_BIN="c:\Users\SURAJ\B2 Spice A_D Lite download starting..._files\Downloads\flutter\bin\flutter.bat"

echo Found Flutter at: %FLUTTER_BIN%
echo.
echo ====================================================
echo  Fixing Windows Database Support (sqflite_common_ffi)
echo ====================================================
echo.

echo Fetching dependencies...
call %FLUTTER_BIN% pub get

echo.
echo ====================================================
echo  Starting Enterprise Attendance App...
echo ====================================================
echo.

call %FLUTTER_BIN% run -d windows
if %errorlevel% neq 0 (
    echo.
    echo Application exited with error code %errorlevel%
    pause
)
