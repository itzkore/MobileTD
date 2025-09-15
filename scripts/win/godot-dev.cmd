@echo off
setlocal
call "%~dp0find-godot4.cmd"
if "%GODOT_EXE%"=="" (
  echo Godot 4 executable not found. Set GODOT4 env var to the full path to Godot_v4.x-stable_win64.exe
  exit /b 1
)

pushd "%~dp0..\..\cybertd"
"%GODOT_EXE%" --headless --import
if errorlevel 1 goto :end
"%GODOT_EXE%" --path .
:end
popd
