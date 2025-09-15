@echo off
setlocal

:: If GODOT4 env var is set, prefer it
if not "%GODOT4%"=="" (
  set "GODOT_EXE=%GODOT4%"
  goto :eof
)

:: If a local path file exists, use it (first non-empty line)
set "PATH_FILE=%~dp0godot-path.txt"
if exist "%PATH_FILE%" (
  for /f "usebackq tokens=* delims=" %%L in ("%PATH_FILE%") do (
    if not "%%~L"=="" (
      set "GODOT_EXE=%%~L"
      goto :eof
    )
  )
)

:: Try common install locations
set "SEARCH_ROOTS=%LocalAppData%\Programs\Godot;C:\Program Files\Godot;C:\Godot"
for %%R in (%SEARCH_ROOTS%) do (
  if exist "%%~R" (
    for /r "%%~R" %%G in (Godot_v4*.exe) do (
      set "GODOT_EXE=%%~G"
      goto :eof
    )
  )
)

:: Try on PATH (winget installs usually alias godot4)
where godot4 >nul 2>nul
if %errorlevel%==0 (
  for /f "usebackq delims=" %%G in (`where godot4`) do (
    set "GODOT_EXE=%%~G"
    goto :eof
  )
)

:: Fallback: try generic godot
where godot >nul 2>nul
if %errorlevel%==0 (
  for /f "usebackq delims=" %%G in (`where godot`) do (
    set "GODOT_EXE=%%~G"
    goto :eof
  )
)

:: Not found
set "GODOT_EXE="
exit /b 1
