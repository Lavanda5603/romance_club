@echo off
call "%~dp0tools\run-python.cmd" server %*
exit /b %errorlevel%
