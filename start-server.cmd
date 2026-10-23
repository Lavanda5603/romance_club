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
if not defined GRPC_BIND set "GRPC_BIND=127.0.0.1:50051"
cd /d "%~dp0server"
cargo run --locked
set "SERVER_EXIT=%ERRORLEVEL%"
pause
exit /b %SERVER_EXIT%