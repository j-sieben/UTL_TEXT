@echo off
cls
set /p InstallUser=Enter owner schema for UTL_TEXT:

set "PWD=powershell.exe -Command " ^
$inputPass = read-host 'Enter password for %InstallUser%' -AsSecureString ; ^
$BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($inputPass); ^
[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)""
for /f "tokens=*" %%a in ('%PWD%') do set PWD=%%a

set /p SID=Enter service name for the database or PDB:

set /p RemoteUser=Enter schema to grant access to UTL_TEXT:

set "RemotePWD=powershell.exe -Command " ^
$inputPass = read-host 'Enter password for %RemoteUser%' -AsSecureString ; ^
$BSTR=[System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($inputPass); ^
[System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)""
for /f "tokens=*" %%a in ('%RemotePWD%') do set RemotePWD=%%a

set nls_lang=GERMAN_GERMANY.AL32UTF8

echo @tools/check_client_user.sql %RemoteUser% | sqlplus %RemoteUser%/%RemotePWD%@%SID% 

echo @install_scripts/grant_client_access.sql %InstallUser% %RemoteUser% | sqlplus %InstallUser%/%PWD%@%SID% 

echo @install_scripts/create_client_synonyms.sql  %InstallUser% %RemoteUser% | sqlplus %RemoteUser%/%RemotePWD%@%SID% 

pause
