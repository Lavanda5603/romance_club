@echo off
set "SURREAL_NAMESPACE=romance_club"
set "SURREAL_DATABASE=main"
set "GRPC_BIND=0.0.0.0:50051"
cd /d "%~dp0server"
target\debug\romance_club_server.exe
pause