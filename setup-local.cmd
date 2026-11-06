@echo off
call "%~dp0tools\run-python.cmd" init %*
exit /b %errorlevel%
