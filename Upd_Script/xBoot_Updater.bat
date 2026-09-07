@echo off
cls
title CCBoot Server 20191221 Updater v1.0.5 - By bdstd@2026

set xpath=%cd%
set xurl=https://raw.githubusercontent.com/bdstd/win/main
set xurl_path=xBoot

:check
call :check_unblock "%~0"
call :check_uac
call :check_license
call :prepare_xunrar

:update_info
set local_ver_path=Version.txt

set upd_ver=20260829.002
set upd_hash=2f3fa7ae4b97a666b20a20a97e6e977a5232d464

REM Sample Update No Part
REM set upd_ver=20260908.000
REM set upd_hash=bfdba6b5965b8e1a6453ad7f9abfa19a9030779b

REM Sample Update With Part
REM set upd_part=2
REM set upd_hash1=aebfbf8e8690a081b8f05d263eef2d069f34b4bb
REM set upd_hash2=6914ecfc35a83a07c41d34272eb28db7912fc8d5

:update_version_check
cls
echo Updating CCBoot Server...
echo [+] Online Version = %upd_ver%
set cur_ver=0
if exist "%local_ver_path%" set /p cur_ver=<"%local_ver_path%" >nul
echo [+] Current Version = %cur_ver%
if %cur_ver%==%upd_ver% (
	echo [+] No Update Available!
	goto update_done
) else (
	del /q "%local_ver_path%" >nul 2>&1
)
if defined upd_part echo [+] Update Part = %upd_part% File^(s^)
goto update_begin

:update_begin
if defined upd_part goto update_with_part
goto update_no_part

:update_no_part
md _Temp_Download_ >nul 2>&1
call :download_and_verify "_Temp_Download_\Update_%upd_ver%.rar" "%upd_hash%" "%xurl%/%xurl_path%/Update_%upd_ver%.rar"
echo [+] Extracting...
%xunrar% "_Temp_Download_\Update_%upd_ver%.rar" "%xpath%"  >nul 2>&1 || call :progress_fail "Failed To Extract Update Files!"
goto update_applying

:update_with_part
md _Temp_Download_ >nul 2>&1
for /L %%N in (1,1,%upd_part%) do (
    call :download_and_verify "_Temp_Download_\Update_%upd_ver%.part%%N.rar" "%%upd_hash%%N%%" "%xurl%/%xurl_path%/Update_%upd_ver%.part%%N.rar"
)
echo [+] Extracting...
%xunrar% "_Temp_Download_\Update_%upd_ver%.part1.rar" "%xpath%" >nul 2>&1 || call :progress_fail "Failed To Extract Update Files!"
goto update_applying

:update_applying
rd /s /q "_Temp_Download_"

echo [+] Updating To %upd_ver%...

REM ========================== CCBoot Update Section
:ccboot_kill_process
taskkill /f /im CCBoot.exe >nul 2>&1
taskkill /f /im CCBootHelper.exe >nul 2>&1
 
:ccboot_default_config
if not exist CCBoot.ini copy /y _Temp_Custom_\CCBoot.ini CCBoot.ini >nul 2>&1
 
:ccboot_clean_up
del /s /q _Temp_Custom_ >nul 2>&1
rd /s /q _Temp_Custom_ >nul 2>&1
del /s /q _Temp_Fix_ >nul 2>&1
rd /s /q _Temp_Fix_ >nul 2>&1
 
xcopy /c /e /y /f _Temp_Update_\*.* >nul 2>&1
del /s /q _Temp_Update_ >nul 2>&1
rd /s /q _Temp_Update_ >nul 2>&1
 
:ccboot_register_firewall
echo [+] Registering Firewall...
netsh advfirewall firewall delete rule name="CCBoot" >nul 2>&1
netsh advfirewall firewall delete rule name="CCBootHelper" >nul 2>&1
netsh advfirewall firewall add rule name="CCBoot" program="%cd%\CCBoot.exe" dir=in profile=any action=allow >nul 2>&1
netsh advfirewall firewall add rule name="CCBootHelper" program="%cd%\CCBootHelper\CCBootHelper.exe" dir=in profile=any action=allow >nul 2>&1
 
:ccboot_optimize_tcp_udp
echo [+] Optimizing TCP/UDP...
reg add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\Tcpip\Parameters" /v "TcpTimedWaitDelay" /t REG_DWORD /d "3" /f >nul 2>&1
netsh int ipv4 set dynamicport tcp start=1025 num=64511 >nul 2>&1
netsh int ipv6 set dynamicport tcp start=1025 num=64511 >nul 2>&1
netsh int ipv4 set dynamicport udp start=1025 num=64511 >nul 2>&1
netsh int ipv6 set dynamicport udp start=1025 num=64511 >nul 2>&1
 
:ccboot_begin
sc query CCBoot | find /i "ccboot" >nul || ( start "" _install_or_repair.bat & goto update_done )

:start_ccboot
net start CCBoot >nul 2>&1
if exist CCBootUI.exe (
	start "" CCBootUI.exe -mini
) else (
	start "" CCBoot.exe -mini
)
if exist CCBootUI_Set_Shortcut_And_Startup.bat (
	start CCBootUI_Set_Shortcut_And_Startup.bat
)
REM ========================== End Of CCBoot Update Section

goto update_done

:update_done
echo %upd_ver%>"%local_ver_path%"
echo [+] Done!
timeout /t 5 >nul
goto exit_script

:check_unblock
dir /r "%~1" | find /i "Zone.Identifier" >nul && (
    cls
    echo Please Unblock "z_Update.bat" In Its Properties
    pause>nul
    goto exit_script
)
exit /b

:check_uac
cls
echo Checking UAC...
fsutil dirty query %SystemDrive% >nul 2>&1 || (
	call :download_and_verify Disable_Full_UAC.reg f1e5d78780364a2ac06a215137051084fe7123fa https://raw.githubusercontent.com/bdstd/win/main/Disable_Full_UAC.reg
	cls
	echo Windows UAC Is Active!
	echo.
	echo Please Import "%cd%\Disable_Full_UAC.reg" And Reboot This PC!
	REM echo Please Set Or Run z_Update.bat As Administrator!
	pause>nul
	goto exit_script
)
exit /b

:check_license
cls
echo Checking License...
call :download_and_verify "License.exe" "bd0f31c3760ff95fb6d32181299c2986665f42b8" "%xurl%/Lic/License_v1.0.4.exe"
call :download_and_verify "License.bat" "84db19699bdcf83c0d9936bb9611eb2aa5664e8e" "%xurl%/Lic/License_v1.0.4.bat"
license.exe | find /i ": Registered" >nul && exit /b
cls
echo Starting Activation...
license.exe -b
license.exe | find /i ": Registered" >nul && exit /b
call :progress_fail "License Not Found In This PC!"

:prepare_xunrar
del /q xUnRAR_v1.0.3.exe
set xunrar=xUnRAR.exe
cls
echo Updating xUnRAR...
call :download_and_verify "%xunrar%" "0aa8011492dad7b42c6ecbaac1329777e8525dd1" "%xurl%/xUnRAR_v1.0.3.exe"
exit /b

:download_and_verify
REM 1=file_path, 2=hash, 3=url
echo [+] Downloading "%~1"...
certutil -hashfile "%~1" | find /i "%~2">nul && echo     No Update! && exit /b
curl -s -L -H "Cache-Control: no-cache, no-store, must-revalidate" -o "%~1" "%~3"
certutil -hashfile "%~1" | find /i "%~2">nul && echo     Downloaded! || echo     SHA-1 Value Is Invalid, Please Try Again Later! && pause>nul && exit
exit /b

:progress_fail
cls
echo %~1
timeout /t 5 >nul
goto exit_script

:exit_script
exit