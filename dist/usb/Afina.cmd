@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File "%~dp0Afina.ps1" %*
if errorlevel 1 pause
