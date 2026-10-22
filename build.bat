@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title BO3 Practice Tool - Build

rem ---------------------------------------------------------------------------
rem  One-click build: compiles the GSC mod, builds the .exe, and puts a
rem  ready-to-run copy in  dist\BO3 Practice Tool\
rem
rem  Needs (one-time installs):
rem    - Visual Studio 2022 (Community is fine) with "Desktop development with C++"
rem      (that workload includes vcpkg; the first build downloads the libraries)
rem ---------------------------------------------------------------------------

echo.
echo [1/4] Compiling the GSC mod...
pushd "GSC\Practice Tool - Release Version"
if exist compiled.gsic del /q compiled.gsic
rem --noupdate keeps the bundled custom compiler (the public update lacks the Practice Tool's natives)
"..\..\Compiler\DebugCompiler.exe" --compile --noupdate
if errorlevel 1 goto gsc_failed
if not exist compiled.gsic goto gsc_failed
copy /y compiled.gsic "..\..\Compiler\Practice Tool.gsc" >nul
popd
echo       OK - Compiler\Practice Tool.gsc updated

echo.
echo [2/4] Finding Visual Studio...
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
if not exist "%VSWHERE%" goto no_vs
set "VSDIR="
rem prefer VS 2022 (this project uses its v143 toolset), then anything newer
for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -version "[17.0,18.0)" -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VSDIR=%%i"
if not defined VSDIR for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -prerelease -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VSDIR=%%i"
if not defined VSDIR goto no_vs
set "MSBUILD=%VSDIR%\MSBuild\Current\Bin\MSBuild.exe"
if not exist "%MSBUILD%" goto no_vs
echo       %VSDIR%

echo.
echo [3/4] Setting up vcpkg (libraries download on the first build only)...
set "VCPKG="
if defined VCPKG_ROOT if exist "%VCPKG_ROOT%\vcpkg.exe" set "VCPKG=%VCPKG_ROOT%\vcpkg.exe"
if not defined VCPKG if exist "%VSDIR%\VC\vcpkg\vcpkg.exe" set "VCPKG=%VSDIR%\VC\vcpkg\vcpkg.exe"
if not defined VCPKG goto no_vcpkg
"%VCPKG%" integrate install >nul
if errorlevel 1 goto no_vcpkg

echo.
echo [4/4] Building BO3 Practice Tool.exe (Release x64)...
"%MSBUILD%" "BO3 Practice Tool.sln" /m /nologo /v:minimal /p:Configuration=Release /p:Platform=x64
if errorlevel 1 goto build_failed

set "OUT=dist\BO3 Practice Tool"
if exist "%OUT%" rmdir /s /q "%OUT%"
robocopy "x64\Release" "%OUT%" /e /xf *.pdb *.iobj *.ipdb *.lib *.exp *.ilk /njh /njs /nfl /ndl >nul
if errorlevel 8 goto build_failed
rem make sure the freshly compiled mod is in the package even if the post-build copy was skipped
copy /y "Compiler\Practice Tool.gsc" "%OUT%\Compiler\Practice Tool.gsc" >nul

echo.
echo ===========================================================================
echo  Build finished:  %CD%\%OUT%\BO3 Practice Tool.exe
echo ===========================================================================
start "" explorer "%CD%\%OUT%"
choice /m "Launch the Practice Tool now"
if errorlevel 2 goto end
start "" "%CD%\%OUT%\BO3 Practice Tool.exe"
goto end

:gsc_failed
popd
echo.
echo GSC compile FAILED. The error above names the file and line.
goto fail

:no_vs
echo.
echo Visual Studio 2022 with "Desktop development with C++" was not found.
echo Install it from https://visualstudio.microsoft.com/ (Community is free), then run this again.
goto fail

:no_vcpkg
echo.
echo vcpkg was not found. In the Visual Studio Installer, modify your install and make sure
echo "vcpkg package manager" is ticked (it's part of "Desktop development with C++").
goto fail

:build_failed
echo.
echo The .exe build FAILED. Scroll up for the first error.
goto fail

:fail
echo.
pause
exit /b 1

:end
endlocal
