@echo off
cls
title CCU Jamu Installer v1.0.13 By bdstd@2026
cd /d %~dp0

if not exist variant.txt exit
if not exist version.txt exit
if not exist variant.sha1 exit

set /p variant=<variant.txt
set /p version=<version.txt
set /p variant_sha1=<variant.sha1

fsutil dirty query %SystemDrive% 2>nul 1>nul 0>nul
if not %ERRORLEVEL%==0 (
	cls
	echo Windows UAC Is Active, Please Run This Script With "Run As Administrator"!
	pause>nul
	exit
)

:check_license
if not exist ..\License.exe exit
cls
echo Checking License...
..\License >nul
..\License >nul
if not %ERRORLEVEL%==1 (
	cls
	..\License -b
	goto check_license
)

set upd_path=%cd%
cd /d ..


:begin_install
set choice=9999
if not "%~1"=="" set "choice=%~1" & goto install
cls
echo %variant% Update %version%
echo.
echo Jamu Mode Options:
echo 1. Apply Jamu
echo 0. Restore Original ^(Unload Jamu^)
echo.
set /p choice=Select Your Option = 
if %choice%==0 goto install
if %choice%==1 goto install
goto begin_install

:install
:optimize_tcp_udp
reg add "HKEY_LOCAL_MACHINE\SYSTEM\ControlSet001\Services\Tcpip\Parameters" /v "TcpTimedWaitDelay" /t REG_DWORD /d "3" /f
netsh int ipv4 set dynamicport tcp start=1025 num=64511
netsh int ipv6 set dynamicport tcp start=1025 num=64511
netsh int ipv4 set dynamicport udp start=1025 num=64511
netsh int ipv6 set dynamicport udp start=1025 num=64511

:preinstall
sc config lwdiskless64 start= disabled
taskkill /f /im lwconsole64*
taskkill /f /im lwdiskless64.exe
taskkill /f /im CCU_OpenTFTPServerSP.exe
taskkill /f /im CCU_DHCP_WatchDog.exe
sc delete CCU_DHCP_WatchDog
taskkill /f /im CCUHelper.exe
taskkill /f /im CCUHelperLauncher.exe
sc delete CCUHelperLauncher
taskkill /f /im ExtF.exe

:wait_kill
timeout /t 1 /nobreak >nul
tasklist | find /i "lwdiskless64.exe" >nul && goto wait_kill
if %choice%==0 goto original
if %choice%==1 goto apply_jamu

:original
move /y client\lwclient64\lwmenu64.exe.disabled client\lwclient64\lwmenu64.exe
del /q lwconsole64.bat
del /q lwconsole64_1.exe
del /q lwconsole64_2.exe
REM del /q License.bat
REM del /q License.exe
del /s /q CCU_OpenTFTPServer
rd /s /q CCU_OpenTFTPServer
xcopy /s /y /f "%upd_path%\original\*.*" "%cd%"
copy /y "%upd_path%\lwserver\CCUHelper\_comp_ori\kcachec64.sys" "%cd%\client\kcachec64.sys"
copy /y "%upd_path%\lwserver\CCUHelper\_ccu_wbcl\kboot64.sys" "%cd%\client\kboot64.sys"

del /q "%cd%\client\Anti_Cheat_*"
del /q "%cd%\client\FACEIT*"
del /q "%cd%\client\vgk.sys"

del /q "%cd%\client\dip_collector.*"
del /q "%cd%\client\disable_game_menu.reg"
del /q "%cd%\client\ksafecenter.reg"
del /q "%cd%\client\kshutdown.reg"
del /q "%cd%\client\switch_khwsdk64.*"

REM Remove Firewall
netsh advfirewall firewall delete rule name="CCU_OpenTFTPServerSP"
netsh advfirewall firewall delete rule name="CCUHelper"
del /q version.txt >nul 2>&1
goto install_done

:apply_jamu
del /s /q CCU_OpenTFTPServer
rd /s /q CCU_OpenTFTPServer
REM move /y client\lwclient64\lwmenu64.exe client\lwclient64\lwmenu64.exe.disabled

rd /s /q CCUHelper\TFTP
rd /s /q CCUHelper\_auto_wbcl
rd /s /q CCUHelper\_ccu_wbcl
del /q CCUHelper\_ccu_wbcl_disabler.bat
del /q CCUHelper\_ccu_wbcl_enabler.bat
del /q CCUHelper\_sb_auto_enroll_disabler.bat
del /q CCUHelper\_sb_auto_enroll_enabler.bat

xcopy /s /y /f "%upd_path%\lwserver\*.*" "%cd%"

REM Set Firewall
netsh advfirewall firewall delete rule name="CCUHelper"
netsh advfirewall firewall add rule name="CCUHelper" program="%cd%\CCUHelper\CCUHelper.exe" dir=in profile=any action=allow

REM Create WatchDog Service
set service_name=CCUHelperLauncher
set service_exe_path=%cd%\CCUHelper\CCUHelperLauncher.exe
sc create %service_name% binPath= "%service_exe_path%" start= auto
sc description %service_name% "Monitor Cloud Update DHCP Service And Launch Helper"
sc start %SERVICE_NAME%

:default_helper_and_extf
md "%cd%\CCUHelper\Device_Instance_Path"
move /y "%cd%\CCUHelper\Device_Instance_Path.disabled" "%cd%\CCUHelper\Device_Instance_Path"
if not exist CCUHelper\.auto_wbcl_pnp_graphic (
	echo.>CCUHelper\.auto_wbcl
)
echo.>CCUHelper\.comp_rec

if exist "%cd%\CCUHelper\.auto_wbcl" (
	copy /y "%cd%\CCUHelper\_auto_wbcl\efibootldr" "%cd%\CCUHelper\TFTP\efibootldr"
	copy /y "%cd%\CCUHelper\_auto_wbcl\iefibootldr" "%cd%\CCUHelper\TFTP\iefibootldr_real"
	copy /y "%cd%\CCUHelper\_auto_wbcl\kboot64.sys" "%cd%\client\kboot64.sys"
) else (
	copy /y "%cd%\CCUHelper\_ccu_wbcl\efibootldr" "%cd%\CCUHelper\TFTP\efibootldr"
	copy /y "%cd%\CCUHelper\_ccu_wbcl\iefibootldr" "%cd%\CCUHelper\TFTP\iefibootldr_real"
	copy /y "%cd%\CCUHelper\_ccu_wbcl\kboot64.sys" "%cd%\client\kboot64.sys"
)
if exist "%cd%\CCUHelper\.auto_wbcl_pnp_graphic" (
	copy /y "%cd%\CCUHelper\_auto_wbcl\efibootldr" "%cd%\CCUHelper\TFTP\efibootldr"
	copy /y "%cd%\CCUHelper\_auto_wbcl\iefibootldr" "%cd%\CCUHelper\TFTP\iefibootldr_real"
	copy /y "%cd%\CCUHelper\_ccu_wbcl\kboot64.sys" "%cd%\client\kboot64.sys"
) else (
	copy /y "%cd%\CCUHelper\_ccu_wbcl\efibootldr" "%cd%\CCUHelper\TFTP\efibootldr"
	copy /y "%cd%\CCUHelper\_ccu_wbcl\iefibootldr" "%cd%\CCUHelper\TFTP\iefibootldr_real"
	copy /y "%cd%\CCUHelper\_ccu_wbcl\kboot64.sys" "%cd%\client\kboot64.sys"
)
if exist "%cd%\CCUHelper\.comp_rec" (
	copy /y "%cd%\CCUHelper\_comp_rec\kcachec64.sys" "%cd%\client\kcachec64.sys"
	copy /y "%cd%\CCUHelper\_comp_rec\switch_khwsdk64.reg" "%cd%\client\switch_khwsdk64.reg"
	copy /y "%cd%\CCUHelper\_comp_rec\switch_khwsdk64.dll" "%cd%\client\switch_khwsdk64.dll"
) else (
	copy /y "%cd%\CCUHelper\_comp_ori\kcachec64.sys" "%cd%\client\kcachec64.sys"
	del /q "%cd%\client\switch_khwsdk64.reg"
	del /q "%cd%\client\switch_khwsdk64.dll"
)

REM Old Flag Files
del /q .ccu_wbcl_enabled
del /q .sb_auto_enroll_enabled
echo %version%>version.txt

:install_done
sc config lwdiskless64 start= auto
net start lwdiskless64
start "" lwconsole64.exe

:done
cls
echo Done...!
if not "%~1"=="" exit
timeout /t 10 >nul
goto begin_install
