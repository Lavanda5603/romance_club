@echo off
rem Запускаю существующую БД только для этого компьютера и эмулятора.
cd /d "%~dp0"
surreal start --user root --pass root --bind 127.0.0.1:8000 surrealkv://database
pause