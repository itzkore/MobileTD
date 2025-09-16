@echo off
setlocal

REM Ensure output directory exists
if not exist "cybertd\build\Android" mkdir "cybertd\build\Android"

REM Export APK using preset name
call "%~dp0find-godot4.cmd" || (
  echo Could not find Godot 4 executable. Configure GODOT4 env var or scripts\win\godot-path.txt.
  exit /b 1
)

set PROJECT_DIR=%~dp0..\..
pushd "%PROJECT_DIR%" >nul

REM Make sure Android export templates are installed
"%GODOT_EXE%" --headless --path cybertd --check-export-templates
if errorlevel 1 (
  echo Android export templates are missing. Install them in Godot: Editor > Manage Export Templates.
  popd
  exit /b 1
)

REM Export APK using preset name from export_presets.cfg (name="Android")
"%GODOT_EXE%" --headless --path cybertd --export-debug "Android" "cybertd\build\Android\debug.apk"
set ERR=%ERRORLEVEL%
popd >nul
exit /b %ERR%
