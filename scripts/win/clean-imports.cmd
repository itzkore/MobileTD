@echo off
setlocal
pushd "%~dp0..\..\cybertd"
REM Delete Godot imported cache (safe to regenerate)
if exist .godot\imported (
  echo Removing .godot\imported cache...
  rmdir /s /q .godot\imported
)
REM Delete per-file .import sidecars under assets
for /r "%cd%\assets" %%F in (*.import) do (
  del /q "%%~F"
)
popd
