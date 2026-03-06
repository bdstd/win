@echo off
cd /d %~dp0
title License Activator v1.0.2 By bdstd@2025
:begin
set choice=
cls
echo License Activator v1.0.2 By bdstd@2025
echo.
echo Select Your Option:
echo 1. Check License/Hardware ID
echo 2. Check Credentials
echo 3. Activation
echo.
set /p choice=Input Number Option Then Press Enter = 
if %choice%==1 license & pause>nul
if %choice%==2 license -c & pause>nul
if %choice%==3 license -b & pause>nul
goto begin