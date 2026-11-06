@echo off
setlocal
set PYTHONUTF8=1
where py >nul 2>&1
if errorlevel 1 (
  python "%~dp0local_dev.py" %*
) else (
  py -3 "%~dp0local_dev.py" %*
)
exit /b %errorlevel%
