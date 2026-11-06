@echo off
call "%~dp0tools\run-python.cmd" db %*
exit /b %errorlevel%
