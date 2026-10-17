@echo off
if not defined JWT_SECRET (
    if not exist "%~dp0.local\jwt-secret.txt" (
        echo JWT_SECRET is missing. See README.md.
        pause
        exit /b 1
    )
    set /p JWT_SECRET=<"%~dp0.local\jwt-secret.txt"
)
set "SURREAL_NAMESPACE=romance_club"
set "SURREAL_DATABASE=main"
set "GRPC_BIND=0.0.0.0:50051"
cd /d "%~dp0server"
target\debug\romance_club_server.exe
pause