@echo off
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%USERPROFILE%\.codex\usage-card-windows\manage.ps1" -Action uninstall
pause
