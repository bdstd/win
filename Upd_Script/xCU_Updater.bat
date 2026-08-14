cls
title Cloud Update Jamu Updater v1.0 By bdstd@2026

set xpath=%cd%\_Jamu_CCU_
set xurl=https://raw.githubusercontent.com/bdstd/win/main
set xurl_path=xCU

:check
call :check_unblock "%~0"
call :check_uac
call :check_license
call :prepare_xunrar

:prepare_update
cls
echo Getting Cloud Update Version...
for /f "skip=1 tokens=1" %%A in ('certutil -hashfile "lwconsole64.exe"') do (if not defined variant_sha1 set "variant_sha1=%%A")
if exist "%xpath%\variant.sha1" (
	set /p variant_sha1=<"%xpath%\variant.sha1"
) else (
	rd /s /q "%xpath%" >nul 2>&1
	del /q version.txt >nul 2>&1
)
goto check_variant

:select_variant
set c_variant_by_choice=1
set c_variant=
cls
echo Cloud Update Stable Version:
echo [+] 1001 = 2025 SP43
echo.
echo Cloud Update Beta Version (Not Recommended):
echo [+] 9001 = 2026 SP23
echo.
set /p c_variant=Input Variant Number And Press Enter = 

REM 2025 SP43
if %c_variant%==1001 set variant_sha1=6b976dcdf755f2ae7fe503a5dccf412cdafa57bb

REM 2. 2026 SP23 (Beta)
if %c_variant%==9001 set variant_sha1=12a7001299ecdb31dafe26edd977e8706d9c5fff

:check_variant
REM Stable
if %variant_sha1%==6b976dcdf755f2ae7fe503a5dccf412cdafa57bb (
	set variant=Cloud Update 2025 SP43
	set upd_ver=20260814.000
	set upd_fname=2025_43
	set upd_part=2
	set upd_hash1=aebfbf8e8690a081b8f05d263eef2d069f34b4bb
	set upd_hash2=6914ecfc35a83a07c41d34272eb28db7912fc8d5
	set next_script=Apply_Or_Restore_Jamu.bat
)

REM Beta
if %variant_sha1%==12a7001299ecdb31dafe26edd977e8706d9c5fff (
	set variant=Cloud Update 2026 SP23
	set upd_ver=20260814.000
	set upd_fname=2026_23
	set upd_part=2
	set upd_hash1=fe0376a41fb891435d5fb82a5a4ad80e784fb75f
	set upd_hash2=0b8d1f507f369094bff918076ffacbed68736b8c
	set next_script=Apply_Or_Restore_Jamu.bat
)


if not defined variant (
	cls
	if defined c_variant_by_choice (
		echo This Version Is Not Available Now, Please Try Again Later!
	) else (
		echo Failed To Get Cloud Update Version!
	)
	timeout /t 3 >nul
	goto select_variant
)

:update_version_check
cls
echo Updating...
echo [+] Variant = %variant%
echo [+] Online Version = %upd_ver%
set cur_ver=0
if exist "%xpath%\version.txt" set /p cur_ver=<"%xpath%\version.txt"
echo [+] Current Version = %cur_ver%
if %cur_ver%==%upd_ver% (
	echo [+] No Update Available!
	goto update_done
) else (
	del /q version.txt >nul 2>&1
)
if defined upd_part echo [+] Update Part = %upd_part% File^(s^)
goto update_begin

:update_begin
if defined upd_part goto update_with_part
goto update_no_part

:update_no_part
md _Temp_Update >nul 2>&1
call :download_and_verify "_Temp_Update\%upd_fname%_%upd_ver%.rar" "%%upd_hash%%N%%" "%xurl%/%xurl_path%/%upd_fname%_%upd_ver%.rar"
echo [+] Extracting...
rd /s /q "%xpath%" >nul 2>&1
md "%xpath%" >nul 2>&1
xUnRAR.exe "_Temp_Update\%upd_fname%_%upd_ver%.rar" "%xpath%"  >nul 2>&1 || call :progress_fail "Failed To Extract Update Files!"
goto update_extracted

:update_with_part
md _Temp_Update >nul 2>&1
for /L %%N in (1,1,%upd_part%) do (
    call :download_and_verify "_Temp_Update\%upd_fname%_%upd_ver%.part%%N.rar" "%%upd_hash%%N%%" "%xurl%/%xurl_path%/%upd_fname%_%upd_ver%.part%%N.rar"
)
echo [+] Extracting...
rd /s /q "%xpath%" >nul 2>&1
md "%xpath%" >nul 2>&1
xUnRAR.exe "_Temp_Update\%upd_fname%_%upd_ver%.part1.rar" "%xpath%" >nul 2>&1 || call :progress_fail "Failed To Extract Update Files!"
goto update_extracted

:update_extracted
rd /s /q "_Temp_Update" >nul 2>&1
goto update_done

:update_done
echo %upd_ver%>"%xpath%\version.txt"
echo %variant%>"%xpath%\variant.txt"
echo %variant_sha1%>"%xpath%\variant.sha1"
set run_next_script=0
if exist version.txt (
	type version.txt | find /i "%cur_ver%" >nul || set run_next_script=1
) else (
	set run_next_script=1
)
if %run_next_script%==1 (
	echo [+] Running Updater Script...
	start "" /wait "%xpath%\%next_script%" 1
)
echo [+] Done!
timeout /t 10 >nul
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
cls
echo Updating xUnRAR...
call :download_and_verify "xUnRAR.exe" "0aa8011492dad7b42c6ecbaac1329777e8525dd1" "%xurl%/xUnRAR_v1.0.3.exe"
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
