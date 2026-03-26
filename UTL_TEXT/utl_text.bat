@echo off
setlocal

if "%~1"=="" goto :help
if /I "%~1"=="help" goto :help
if /I "%~1"=="--help" goto :help
if /I "%~1"=="-h" goto :help

if /I "%~1"=="install" (
  shift
  call "%~dp0install_scripts\install.bat" %*
  exit /b %errorlevel%
)

if /I "%~1"=="install-client" (
  shift
  call "%~dp0install_scripts\install_client.bat" %*
  exit /b %errorlevel%
)

if /I "%~1"=="uninstall" (
  shift
  call "%~dp0install_scripts\uninstall.bat" %*
  exit /b %errorlevel%
)

echo Unknown command: %~1
echo.
goto :help_error

:help
echo Usage:
echo   utl_text.bat ^<command^>
echo.
echo Commands:
echo   install
echo   install-client
echo   uninstall
echo   help
exit /b 0

:help_error
echo Usage:
echo   utl_text.bat ^<command^>
exit /b 1
