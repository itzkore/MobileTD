@echo off
setlocal
call "%~dp0find-godot4.cmd"
if "%GODOT_EXE%"=="" (
  echo Godot 4 executable not found. Set GODOT4 env var or configure scripts\win\godot-path.txt
  exit /b 1
)
pushd "%~dp0..\..\cybertd"
"%GODOT_EXE%" --headless --path . --import
if errorlevel 1 goto :end
"%GODOT_EXE%" --path .
:end
popd
