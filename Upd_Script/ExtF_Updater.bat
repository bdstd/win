@echo off
cls
title ExtF Updater v1.0.7 - By bdstd@2026

set xpath=%cd%
set xurl=https://raw.githubusercontent.com/bdstd/win/main
set xurl_path=ExtF

:check
REM call :check_unblock "%~0"
REM call :check_uac
REM call :check_license
call :prepare_xunrar

:update_info
set local_ver_path=_Tools_\Version.txt

set upd_ver=20260908.000
set upd_hash=bfdba6b5965b8e1a6453ad7f9abfa19a9030779b

REM Sample Update No Part
REM set upd_ver=20260908.000
REM set upd_hash=bfdba6b5965b8e1a6453ad7f9abfa19a9030779b

REM Sample Update With Part
REM set upd_part=2
REM set upd_hash1=aebfbf8e8690a081b8f05d263eef2d069f34b4bb
REM set upd_hash2=6914ecfc35a83a07c41d34272eb28db7912fc8d5

:update_components
cls
echo Updating Components...
md _Tools_\bdstd >nul 2>&1
call :download_and_verify "_Tools_\bdstd\inf2reg.exe" "d6ab9cb5763d530faa1ad21d9d637c47ce0029a7" "%xurl%/inf2reg.exe"
call :download_and_verify "_Tools_\bdstd\mich.exe" "375ddf71cd19374230c2166cf9d195d1b2fce46d" "%xurl%/mich.exe"
call :download_and_verify "_Tools_\bdstd\vhdtools.exe" "e6cbff15074abe2d8d026422332b199a948fa554" "%xurl%/vhdtools.exe"
call :download_and_verify "_Tools_\bdstd\runascurrentuser.exe" "ceb2467bb55635829f0e9c426ecebca157c708de" "%xurl%/runascurrentuser.exe"

md _Tools_\sqlite3 >nul 2>&1
call :download_and_verify "_Tools_\sqlite3\sqlite3.exe" "99a0270bb6303250ae0f9accd707bc0c476094a0" "%xurl%/sqlite3.exe"

md _Tools_\nirsoft >nul 2>&1
call :download_and_verify "_Tools_\nirsoft\AdvancedRun.exe" "996fcf7b6c0a5ed217a46b013c067e0c1fe3eba9" "%xurl%/AdvancedRun.exe"

call :download_and_verify "ExtF.exe" "9f7c37d6a8e627900c871effd12c677475264390" "%xurl%/lua_loader.exe"


:update_version_check
cls
echo Updating ExtF...
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

REM Kill Process
taskkill /f /im CCBootExtF.exe >nul 2>&1
taskkill /f /im Mounted_Image_Tools.exe >nul 2>&1
taskkill /f /im ExtF.exe >nul 2>&1

REM ExtF Delete Old Files
del /q Mounted_Image_Tools.exe >nul 2>&1
del /q CCBootExtF.exe >nul 2>&1

REM Conditional
if exist ..\CCBoot.exe (
	echo [+] Updating CCBootTFTP.bat
	move /y _Temp_Fix_\CCBoot\CCBootTFTP.bat ..\CCBootTFTP.bat >nul 2>&1
)
if exist ..\lwdiskless64.exe (
	echo [+] Updating lwconsole.bat
	move /y _Temp_Fix_\lwserver\lwconsole64.bat ..\lwconsole64.bat >nul 2>&1
	if not exist ccu_lpnp_gpu_custom.txt (
		copy /y _Temp_Custom_\ccu_lpnp_gpu_custom.txt ccu_lpnp_gpu_custom.txt >nul 2>&1
	)
)
if not exist _Mounted_Image_Tools_Custom_\menu.txt (
	md _Mounted_Image_Tools_Custom_ >nul 2>&1
	copy /y _Temp_Custom_\_Mounted_Image_Tools_Custom_\menu.txt _Mounted_Image_Tools_Custom_\menu.txt >nul 2>&1
)

REM Clean Up
rd /s /q _Temp_Beta_ >nul 2>&1
rd /s /q _Temp_Custom_ >nul 2>&1
rd /s /q _Temp_Fix_ >nul 2>&1
del /q ReadMe.txt >nul 2>&1
del /q Changelog.txt >nul 2>&1
xcopy /e /y /f _Temp_Update_\*.* >nul 2>&1
rd /s /q _Temp_Update_ >nul 2>&1
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
set xunrar=_Tools_\bdstd\xUnRAR_v1.0.3.exe
md _Tools_\bdstd >nul 2>&1
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