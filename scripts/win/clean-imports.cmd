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
REM Delete editor filesystem cache that can retain stale UIDs
if exist .godot\editor\filesystem_cache10 (
  echo Removing .godot\editor\filesystem_cache10...
  del /q .godot\editor\filesystem_cache10
)
if exist .godot\uid_cache.bin (
  echo Removing .godot\uid_cache.bin...
  del /q .godot\uid_cache.bin
)
popd
