@echo off
setlocal

rem Generic Windows performance detector launcher.
rem Pass options through to monitor-windows.ps1.
powershell.exe -NoProfile -File "%~dp0monitor-windows.ps1" %*
exit /b %ERRORLEVEL%
