@echo off
setlocal
set "ADB_COMMAND=adb"
where adb >nul 2>nul
if errorlevel 1 (
    if exist "%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe" (
        set "ADB_COMMAND=%LOCALAPPDATA%\Android\Sdk\platform-tools\adb.exe"
    ) else (
        echo ADB was not found. Add Android SDK platform-tools to PATH.
        pause
        exit /b 1
    )
)
"%ADB_COMMAND%" devices
echo.
echo Connect one phone, enable USB debugging and allow this computer on the phone.
"%ADB_COMMAND%" -d reverse tcp:50051 tcp:50051
if errorlevel 1 (
    echo USB connection failed. Check the cable and USB debugging authorization.
    pause
    exit /b 1
)
echo Connected. In the app select USB phone: 127.0.0.1, port 50051.
pause