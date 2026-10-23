@echo off
setlocal EnableExtensions
cd /d "%~dp0"
title Bo3 Practice Tool Vin
set "ROOT=%~dp0"
set "LOG=%ROOT%vin.log"
set "MODE=%~1"
set "AUTO=%~2"

rem ===========================================================================
rem  Bo3 Practice Tool Vin - the one script for everything:
rem    1  Update the in-game script: compile Mod Source\scripts, install it as
rem       "Practice Tool Vin.gsc", inject it if the game is at the main menu
rem    2  Rebuild the app (BO3 Practice Tool.exe) from Vin Source, then do 1
rem    3  Watch: do 1 every time a script in Mod Source\scripts is saved
rem    5  Make a shareable copy: rebuild everything, then zip the app + in-game script
rem       into "Bo3 Practice Tool Vin (share).zip" for other people
rem    6  Make GitHub release files: rebuild everything, then make "BO3 Practice Tool.zip"
rem       and "Compiler.zip" in the Release folder for a release on
rem       github.com/vince31058/BO3-Practice-Tool (the app's updater downloads these)
rem    4  Rev Practice Tool (recreated source in Rev Source): compile it, check it
rem       against the original v1.3, and inject it if you want
rem  Output of the last run goes to vin.log.
rem  Your original Practice Tool is never touched:
rem  "BO3 Practice Tool (original).exe" always loads the original.
rem ===========================================================================

rem older versions of this setup used separate helper files - remove them
for %%f in ("Auto Build.bat" "Build Vin App.bat" "Dev Build.bat" "Install Mod.bat" "Try Vin.bat" "Restore Original.bat" "vin_build.log" "vin_compile.log" "Mod Source\watch.ps1" "Mod Source\README.txt") do if exist %%f del /q %%f

if /i "%MODE%"=="script" goto script
if /i "%MODE%"=="app" goto app
if /i "%MODE%"=="watch" goto watch
if /i "%MODE%"=="rev" goto rev
if /i "%MODE%"=="share" goto share
if /i "%MODE%"=="release" goto release

echo.
echo  1 = Update the in-game script   (after editing Mod Source\scripts)
echo  2 = Rebuild the app, then the script   (after app changes)
echo  3 = Watch - update the script every time you save
echo  4 = Rev Practice Tool - compile the recreated source (Rev Source)
echo  5 = Make a shareable copy for other people (zip)
echo  6 = Make GitHub release files (for an update on GitHub)
echo.
choice /c 123456 /n /m "Choose 1, 2, 3, 4, 5 or 6: "
if errorlevel 6 goto release
if errorlevel 5 goto share
if errorlevel 4 goto rev
if errorlevel 3 goto watch
if errorlevel 2 goto app
goto script


rem ===========================================================================
:app
echo.
echo === Rebuilding the app ===
set "SRC=%ROOT%Vin Source"
if exist "%SRC%\BO3 Practice Tool.sln" goto app_vs
set "ZIP="
for /f "delims=" %%z in ('dir /b /o-d "%USERPROFILE%\Downloads\Bo3 Practice Tool Vin*.zip" 2^>nul') do if not defined ZIP set "ZIP=%USERPROFILE%\Downloads\%%z"
if not defined ZIP (
    echo  "Vin Source" is missing and "Bo3 Practice Tool Vin.zip" isn't in Downloads.
    goto fail
)
echo  Extracting %ZIP%
set "TMPX=%TEMP%\vin_extract"
if exist "%TMPX%" rmdir /s /q "%TMPX%"
mkdir "%TMPX%"
tar -xf "%ZIP%" -C "%TMPX%"
move "%TMPX%\Bo3 Practice Tool Vin" "%SRC%" >nul
if not exist "%SRC%\BO3 Practice Tool.sln" (
    echo  Couldn't extract the source.
    goto fail
)

:app_vs
set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
set "VSDIR="
if exist "%VSWHERE%" for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -version "[17.0,18.0)" -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VSDIR=%%i"
if exist "%VSWHERE%" if not defined VSDIR for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -prerelease -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VSDIR=%%i"
if not defined VSDIR (
    echo  Visual Studio with "Desktop development with C++" wasn't found.
    goto fail
)
set "MSBUILD=%VSDIR%\MSBuild\Current\Bin\MSBuild.exe"

where git >nul 2>&1 || set "PATH=%PATH%;%VSDIR%\Common7\IDE\CommonExtensions\Microsoft\TeamFoundation\Team Explorer\Git\cmd"
set "VCPKG_DIR=%LOCALAPPDATA%\vin-vcpkg"
if not exist "%VCPKG_DIR%\vcpkg.exe" (
    echo  First run: downloading vcpkg...
    if not exist "%VCPKG_DIR%\.git" git clone --quiet https://github.com/microsoft/vcpkg "%VCPKG_DIR%"
    call "%VCPKG_DIR%\bootstrap-vcpkg.bat" -disableMetrics >nul
)
if not exist "%VCPKG_DIR%\vcpkg.exe" (
    echo  Couldn't set up vcpkg in %VCPKG_DIR%.
    goto fail
)
"%VCPKG_DIR%\vcpkg.exe" integrate install >nul

echo  Building (a minute or two)...
"%MSBUILD%" "%SRC%\BO3 Practice Tool.sln" /m /nologo /v:minimal /p:Configuration=Release /p:Platform=x64 > "%LOG%" 2>&1
if errorlevel 1 (
    echo  Build FAILED:
    findstr /i /c:" error " "%LOG%"
    goto fail
)

:app_wait_closed
tasklist /fi "imagename eq BO3 Practice Tool.exe" 2>nul | find /i "BO3 Practice Tool.exe" >nul
if not errorlevel 1 (
    echo  Close the Practice Tool app, then press a key...
    pause >nul
    goto app_wait_closed
)
if not exist "%ROOT%BO3 Practice Tool (original).exe" copy /y "%ROOT%BO3 Practice Tool.exe" "%ROOT%BO3 Practice Tool (original).exe" >nul
copy /y "%SRC%\x64\Release\BO3 Practice Tool.exe" "%ROOT%BO3 Practice Tool.exe" >nul
for %%f in ("%SRC%\x64\Release\*.dll") do copy /y "%%f" "%ROOT%" >nul
echo  App updated.
rem continue with the in-game script


rem ===========================================================================
:script
echo.
echo === Updating the in-game script ===
for /f "usebackq delims=" %%p in (`powershell -NoProfile -Command "(Get-Content -Raw 'settings.json' | ConvertFrom-Json).'Steam Path'"`) do set "BO3=%%p"
if not defined BO3 (
    echo  Couldn't find Black Ops 3 from the "Steam Path" in settings.json.
    goto fail
)
if not "%BO3:~-1%"=="\" set "BO3=%BO3%\"
set "DEST=%BO3%Practice Tool\Compiler"
if not exist "%DEST%" mkdir "%DEST%"

taskkill /im DebugCompiler.exe /f >nul 2>&1
if exist "Mod Source\compiled.gsic" del /q "Mod Source\compiled.gsic"
if exist "%LOG%" del /q "%LOG%"
rem The Practice Tool's compiler only has "--build": compile the scripts folder, inject
rem into the game, then wait for a key (a key would undo the inject). It runs
rem minimized; this watches its output and closes it once it's done.
start "Vin compiler" /min /d "%ROOT%Mod Source" cmd /c ""%ROOT%Mod Source\Compiler\DebugCompiler.exe" --build > "%LOG%" 2>&1"
echo  Compiling...
set /a WAITED=0
:script_wait
ping -n 2 127.0.0.1 >nul
set /a WAITED+=1
tasklist /fi "imagename eq DebugCompiler.exe" 2>nul | find /i "DebugCompiler.exe" >nul
if errorlevel 1 goto script_compiled
findstr /c:"parsetree" "%LOG%" >nul 2>&1
if not errorlevel 1 goto script_stop
if %WAITED% lss 120 goto script_wait
echo  The compiler didn't finish within 2 minutes - stopping it.
:script_stop
taskkill /im DebugCompiler.exe /f >nul 2>&1
:script_compiled

if not exist "Mod Source\compiled.gsic" (
    echo  Compile FAILED:
    if exist "%LOG%" type "%LOG%"
    goto fail
)
if not exist "%DEST%\DebugCompiler.exe" xcopy "Mod Source\Compiler\*" "%DEST%\" /y /q >nul
copy /y "Mod Source\compiled.gsic" "%DEST%\Practice Tool Vin.gsc" >nul
if errorlevel 1 (
    echo  Couldn't write to "%DEST%". Close anything using it and try again.
    goto fail
)
rem the compiler's leftovers aren't needed
del /q "Mod Source\compiled.gsic" "Mod Source\compiled.omap" "Mod Source\hashes.txt" >nul 2>&1

findstr /c:"]: Injected" "%LOG%" >nul 2>&1
if not errorlevel 1 (
    echo  Done - injected. Load a game ^(or quit to the main menu and reload^) to see it.
    goto done
)
tasklist /fi "imagename eq BlackOps3.exe" 2>nul | find /i "BlackOps3.exe" >nul
if errorlevel 1 (
    echo  Done - installed. It loads when you toggle the Vin app on.
) else (
    echo  Done - installed. To load it now, be at the main menu and run this again,
    echo  or toggle the Vin app off and on.
)
goto done


rem ===========================================================================
:watch
call :script_once
echo.
echo === Watching Mod Source\scripts - save a script to update it. Close this window to stop. ===
powershell -NoProfile -Command "$last = 0; while ($true) { $t = (Get-ChildItem 'Mod Source\scripts' -Recurse -Filter *.gsc | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime.Ticks; if ($last -ne 0 -and $t -ne $last) { Start-Sleep -Milliseconds 700; Write-Host ''; Write-Host ('[' + (Get-Date -Format 'HH:mm:ss') + '] Change detected'); & cmd /c 'Vin.bat script auto' }; $last = $t; Start-Sleep -Seconds 2 }"
goto done

:script_once
cmd /c "Vin.bat script auto"
exit /b 0


rem ===========================================================================
:rev
echo.
echo === Rev Practice Tool (recreated source) ===
set "REV=%ROOT%Rev Source"
if not exist "%REV%\scripts\main.gsc" (
    echo  "Rev Source" is missing.
    goto fail
)
pushd "%REV%"
if exist compiled.gsic del /q compiled.gsic
"Compiler\DebugCompiler.exe" --compile --noupdate > "%LOG%" 2>&1
if not exist compiled.gsic (
    popd
    echo  Compile FAILED:
    type "%LOG%"
    goto fail
)
del /q compiled.omap hashes.txt >nul 2>&1
rem the compiler gives every detour a random ID each build, so those 4-byte IDs are
rem the only bytes allowed to differ; everything else must match the original exactly
powershell -NoProfile -Command "$a=[IO.File]::ReadAllBytes('compiled.gsic'); $b=[IO.File]::ReadAllBytes('Compiler\original.gsic'); if($a.Length -ne $b.Length){exit 1}; function ids($x){$s=@{}; $n=[BitConverter]::ToInt32($x,12); for($k=0;$k -lt $n;$k++){$s[[BitConverter]::ToUInt32($x,16+256*$k)]=1}; $s}; $ia=ids $a; $ib=ids $b; for($i=0;$i -lt $a.Length;$i++){ if($a[$i] -ne $b[$i]){ $j=$i-($i%%4); if(-not($ia.ContainsKey([BitConverter]::ToUInt32($a,$j)) -and $ib.ContainsKey([BitConverter]::ToUInt32($b,$j)))){exit 1} } }; exit 0"
if errorlevel 1 (
    echo  Compiled, but it is NOT byte-identical to the original v1.3.
    echo  ^(send me "Rev Source\compiled.gsic" and I'll check what differs^)
) else (
    echo  Compiled - IDENTICAL to the original Rev Practice Tool v1.3 ^(only the random detour IDs differ^).
)
tasklist /fi "imagename eq BlackOps3.exe" 2>nul | find /i "BlackOps3.exe" >nul
if errorlevel 1 (
    echo  Black Ops 3 isn't running - start it and run option 4 again to inject.
    popd
    goto done
)
choice /c yn /n /m "Inject it into Black Ops 3 now? Be at the main menu (Y/N): "
if errorlevel 2 (
    popd
    goto done
)
rem same as Rev's own run.bat; that window has to stay open while you play
start "Rev Practice Tool" /d "%REV%" cmd /c ""Compiler\DebugCompiler.exe" "compiled.gsic" "T7" "scripts/shared/duplicaterender_mgr.gsc" "--inject" "--noupdate" & pause"
popd
echo  Injecting in the "Rev Practice Tool" window - leave it open while you play.
goto done

rem ===========================================================================
:share
echo.
echo === Making a shareable copy ===
echo  Step 1: rebuilding the app and the in-game script...
cmd /c "Vin.bat app auto"
if errorlevel 1 (
    echo  The build failed - nothing was packaged.
    goto fail
)
for /f "usebackq delims=" %%p in (`powershell -NoProfile -Command "(Get-Content -Raw 'settings.json' | ConvertFrom-Json).'Steam Path'"`) do set "BO3=%%p"
if not "%BO3:~-1%"=="\" set "BO3=%BO3%\"
set "GAMECOMP=%BO3%Practice Tool\Compiler"
if not exist "%GAMECOMP%\Practice Tool Vin.gsc" (
    echo  "Practice Tool Vin.gsc" is missing from the game's Practice Tool folder.
    goto fail
)
echo  Step 2: packaging...
set "PKG=%TEMP%\Bo3 Practice Tool Vin"
if exist "%PKG%" rmdir /s /q "%PKG%"
mkdir "%PKG%\Compiler"
copy /y "BO3 Practice Tool.exe" "%PKG%\" >nul
for %%f in (*.dll) do copy /y "%%f" "%PKG%\" >nul
xcopy "Resource Images" "%PKG%\Resource Images\" /e /i /q /y >nul
if exist "Fonts" xcopy "Fonts" "%PKG%\Fonts\" /e /i /q /y >nul
rem the app moves everything in its Compiler folder into the game's Practice Tool folder on first start
for %%f in ("%GAMECOMP%\*") do if /i not "%%~nxf"=="Practice Tool.gsc" copy /y "%%f" "%PKG%\Compiler\" >nul
(
echo Bo3 Practice Tool Vin
echo =====================
echo A build of Joshr520's BO3 Practice Tool with extra practice patches and settings.
echo.
echo Install:
echo  1. Unzip this folder anywhere ^(not inside the Black Ops III folder^).
echo  2. Run "BO3 Practice Tool.exe". The first time, pick your Black Ops III folder when asked.
echo     It installs its in-game script into Black Ops III\Practice Tool by itself.
echo  3. Start Black Ops III, turn the tool on at the main menu, pick your patches, load a map.
echo.
echo If you already use the original Practice Tool, this one uses its own in-game script file
echo ^("Practice Tool Vin.gsc"^), so the original keeps working.
) > "%PKG%\README.txt"
set "ZIP=%ROOT%Bo3 Practice Tool Vin (share).zip"
if exist "%ZIP%" del /q "%ZIP%"
powershell -NoProfile -Command "Compress-Archive -Path '%PKG%' -DestinationPath '%ZIP%'"
rmdir /s /q "%PKG%"
if not exist "%ZIP%" (
    echo  Couldn't create the zip.
    goto fail
)
echo  Done: "Bo3 Practice Tool Vin (share).zip" is in this folder - send that file.
goto done

rem ===========================================================================
:release
echo.
echo === Making GitHub release files ===
echo  Step 1: rebuilding the app and the in-game script...
cmd /c "Vin.bat app auto"
if errorlevel 1 (
    echo  The build failed - nothing was packaged.
    goto fail
)
for /f "usebackq delims=" %%p in (`powershell -NoProfile -Command "(Get-Content -Raw 'settings.json' | ConvertFrom-Json).'Steam Path'"`) do set "BO3=%%p"
if not "%BO3:~-1%"=="\" set "BO3=%BO3%\"
set "GAMECOMP=%BO3%Practice Tool\Compiler"
if not exist "%GAMECOMP%\Practice Tool Vin.gsc" (
    echo  "Practice Tool Vin.gsc" is missing from the game's Practice Tool folder.
    goto fail
)
set "VER="
for /f "usebackq delims=" %%v in (`powershell -NoProfile -Command "if((Get-Content -Raw 'Vin Source\BO3 Practice Tool\BO3 Practice Tool.cpp') -match 'internalVersion = .([0-9.]+).'){$matches[1]}"`) do set "VER=%%v"
echo  Step 2: packaging version %VER%...
set "REL=%ROOT%Release"
if exist "%REL%" rmdir /s /q "%REL%"
set "PKG=%TEMP%\vin_release_tool"
set "PKC=%TEMP%\vin_release_compiler"
if exist "%PKG%" rmdir /s /q "%PKG%"
if exist "%PKC%" rmdir /s /q "%PKC%"
mkdir "%REL%" "%PKG%" "%PKC%\Compiler"
rem the updater extracts these at the top of the zip next to the exe
copy /y "BO3 Practice Tool.exe" "%PKG%\" >nul
for %%f in (*.dll) do copy /y "%%f" "%PKG%\" >nul
xcopy "Resource Images" "%PKG%\Resource Images\" /e /i /q /y >nul
if exist "Fonts" xcopy "Fonts" "%PKG%\Fonts\" /e /i /q /y >nul
for %%f in ("%GAMECOMP%\*") do if /i not "%%~nxf"=="Practice Tool.gsc" copy /y "%%f" "%PKC%\Compiler\" >nul
rem the zips use / in paths and have no folder entries, so the app's updater can unpack them in place
call :zipdir "%PKG%" "%REL%\BO3 Practice Tool.zip"
call :zipdir "%PKC%" "%REL%\Compiler.zip"
rmdir /s /q "%PKG%"
rmdir /s /q "%PKC%"
if not exist "%REL%\Compiler.zip" (
    echo  Couldn't create the zips.
    goto fail
)
echo.
echo  Done. In the Release folder:
echo    BO3 Practice Tool.zip   and   Compiler.zip
echo  On GitHub make a new release with the tag v%VER% and attach both zips.
echo  Next update: raise internalVersion in Vin Source\BO3 Practice Tool\BO3 Practice Tool.cpp first
echo  (e.g. 1.0.1), so people with this version get the update prompt.
goto done

rem ===========================================================================
rem zip everything inside folder %1 into %2 (paths inside the zip start below %1)
:zipdir
powershell -NoProfile -Command "Add-Type -AssemblyName System.IO.Compression.FileSystem; $src=(Resolve-Path -LiteralPath '%~1').Path.TrimEnd('\'); $z=[IO.Compression.ZipFile]::Open('%~2','Create'); Get-ChildItem -LiteralPath $src -Recurse -File | ForEach-Object { [void][IO.Compression.ZipFileExtensions]::CreateEntryFromFile($z, $_.FullName, $_.FullName.Substring($src.Length + 1).Replace('\','/')) }; $z.Dispose()"
exit /b 0

rem ===========================================================================
:fail
echo.
echo  Full output: vin.log
if /i not "%AUTO%"=="auto" pause
exit /b 1

:done
echo.
if /i not "%AUTO%"=="auto" pause
exit /b 0
