@echo off
setlocal
rem Double-click to package every app folder in input\ into a .intunewin file in output\.
rem If an app folder has more than one possible installer, it asks which one to use.
title Packaging apps for Intune
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Build-IntuneWin.ps1" -PromptForSetupFile %*
set "EXIT_CODE=%ERRORLEVEL%"
rem Show the packages when every app was packaged.
if "%EXIT_CODE%"=="0" start "" "%~dp0output"
echo.
pause
exit /b %EXIT_CODE%
