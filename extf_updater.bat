@echo off
set updater_initialized=1

set online_version=20260724.001
set update_file_hash="786946cc5d748b8b96c89f72130df2b180bc1949"

set update_file_url="https://raw.githubusercontent.com/bdstd/xlua/main/Mounted_Image_Tools/Update_%online_version%.rar?%random%%random%"
set update_file_path="%temp%\Mounted_Image_Tools.rar"
set curr_ver_file_path=_Tools_\version.txt
 
title ExtF Updater v1.0.5 - By bdstd@2026

REM Update Is Preparing
REM if not exist .prepare_update ( cls & echo Preparing Update, Please Try Again Later! & pause>nul & exit )

REM Check
if exist ..\CCBoot.exe (
	if not exist ..\CCBootHelper\CCBootHelper.exe (
		cls
		echo ERROR, This Update Require CCBoot Server 20191221 Update 20260220.003 Or Above!
   		echo Please Update CCBoot Server First!
		pause>nul
		exit 1
	)
)
 
certutil>nul
if not %ERRORLEVEL%==0 (
	cls
	echo [!] CertUtil Command Is Not Supported!
	pause>nul
	exit
)

REM Prepare Folder
md _Tools_\bdstd >nul 2>&1
md _Tools_\nirsoft >nul 2>&1
md _Tools_\sqlite3 >nul 2>&1

REM xUnRAR
set file_name=xUnRAR_v1.0.3.exe
set file_path=_Tools_\bdstd\%file_name%
set file_name_url=%file_name%
set file_hash=0aa8011492dad7b42c6ecbaac1329777e8525dd1
call :download_components
set xunrar=%file_name%

:check_license
cls
echo Checking License...
_Tools_\bdstd\%xunrar% /? 2>&1 | find /i "bdstd@" >nul 2>&1 || (
	cls
	echo License Not Found Or Invalid!
    echo Update Aborted!
	pause>nul
	exit
)

REM ExtF
set file_name=ExtF.exe
set file_path=%file_name%
set file_name_url=lua_loader.exe
set file_hash=9f7c37d6a8e627900c871effd12c677475264390
call :download_components

REM inf2reg
set file_name=inf2reg.exe
set file_path=_Tools_\bdstd\%file_name%
set file_name_url=%file_name%
set file_hash=d6ab9cb5763d530faa1ad21d9d637c47ce0029a7
call :download_components

REM mich
set file_name=mich.exe
set file_path=_Tools_\bdstd\%file_name%
set file_name_url=%file_name%
set file_hash=375ddf71cd19374230c2166cf9d195d1b2fce46d
call :download_components

REM vhdtools
set file_name=vhdtools.exe
set file_path=_Tools_\bdstd\%file_name%
set file_name_url=%file_name%
set file_hash=e6cbff15074abe2d8d026422332b199a948fa554
call :download_components

REM RunAsCurrentUser
set file_name=runascurrentuser.exe
set file_path=_Tools_\bdstd\%file_name%
set file_name_url=%file_name%
set file_hash=ceb2467bb55635829f0e9c426ecebca157c708de
call :download_components

REM AdvancedRun
set file_name=AdvancedRun.exe
set file_path=_Tools_\nirsoft\%file_name%
set file_name_url=%file_name%
set file_hash=996fcf7b6c0a5ed217a46b013c067e0c1fe3eba9
call :download_components

REM sqlite3
set file_name=sqlite3.exe
set file_path=_Tools_\sqlite3\%file_name%
set file_name_url=%file_name%
set file_hash=99a0270bb6303250ae0f9accd707bc0c476094a0
call :download_components

:update_begin
del /q %update_file_path% 2>nul 1>nul
set current_version=0
set /p current_version=<%curr_ver_file_path%
cls
echo Updating...
echo [+] Current Version = %current_version%
echo [+] Online Version = %online_version%
if %current_version%==%online_version% (
	echo [+] Latest Version, No Need Update!
	goto end_online_update_script
)

:download_update
echo [+] Downloading Update File...
echo.
curl -L -H "Cache-Control: no-cache" -o %update_file_path% %update_file_url%
echo.
certutil -hashfile "%update_file_path%" | find /i %update_file_hash% >nul && goto extract_update || (
	echo     The Hash Value In The Update File Is Invalid, Please Try Again Later! ^(3-5 Minutes^)
	goto end_online_update_script
)

:extract_update
echo [+] Extracting Update File...
_Tools_\bdstd\%xunrar% "%update_file_path%" "%cd%" >nul 2>&1 || (
	echo [!] Failed To Extract Update File!
	goto end_online_update_script
)

:updating
echo [+] Updating To %online_version%...

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
del /s /q _Temp_Beta_ >nul 2>&1
rd /s /q _Temp_Beta_ >nul 2>&1
del /s /q _Temp_Custom_ >nul 2>&1
rd /s /q _Temp_Custom_ >nul 2>&1
del /s /q _Temp_Fix_ >nul 2>&1
rd /s /q _Temp_Fix_ >nul 2>&1
del /q ReadMe.txt >nul 2>&1
del /q Changelog.txt >nul 2>&1
 
xcopy /e /y /f _Temp_Update_\*.* >nul 2>&1
del /s /q _Temp_Update_ >nul 2>&1
rd /s /q _Temp_Update_ >nul 2>&1
 
REM Mark Update
echo %online_version%>%curr_ver_file_path%
	
REM TXT
if exist ReadMe.txt start ReadMe.txt
if exist Changelog.txt start Changelog.txt

del /q "%update_file_path%" >nul 2>&1
echo [+] Done!
goto end_online_update_script

:download_components
certutil -hashfile %file_path% | find /i "%file_hash%">nul && exit /b
taskkill /f /im %file_name% >nul 2>&1
del /q "%file_path%" >nul 2>&1
cls
echo Downloading %file_name%...
curl -s -L -H "Cache-Control: no-cache, no-store, must-revalidate" -o "%file_path%" "https://raw.githubusercontent.com/bdstd/win/main/%file_name_url%?%random%%random%"
certutil -hashfile %file_path% | find /i "%file_hash%">nul || echo %file_name% Hash Value Is Invalid, Please Try Again Later! && pause>nul && exit
exit /b

:end_online_update_script
