@echo off
call "%~dp0tools\run-python.cmd" export-v3 %*
exit /b %errorlevel%
