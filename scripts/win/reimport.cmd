@echo off
setlocal EnableExtensions

call "%~dp0find-godot4.cmd"
if errorlevel 1 (
  echo [reimport] Could not find Godot 4 executable.
  echo [reimport] Set the correct path in scripts\win\godot-path.txt or define GODOT4 env var.
  exit /b 1
)

echo [reimport] Using GODOT_EXE=%GODOT_EXE%
pushd "%~dp0..\..\cybertd"
"%GODOT_EXE%" --headless --path . --import
set "ERR=%ERRORLEVEL%"
popd

exit /b %ERR%
