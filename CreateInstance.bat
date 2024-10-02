@echo off
net session >nul 2>&1
IF %ERRORLEVEL% EQU 0 (
  echo Running as admin
) else (
    echo Failure: Current permissions inadequate.
    pause
    exit
)

set /P name="Enter your alt name (don't use spaces): "
if "%name%" == "" (
    echo Failure: Please enter a name
    pause
    exit
)

cd /d %~dp0
net user %name% %name% /add
mklink /d ro_win_%name%_Data ro_win_Data
copy ro_win.exe ro_win_%name%.exe

ECHO cd /d %~dp0 > %name%.bat
ECHO runas /savecred /user:%name% ro_win_%name%.exe >> %name%.bat
echo Done! you can now close this window if you don't see any errors
pause