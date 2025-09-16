@echo off
setlocal EnableExtensions EnableDelayedExpansion

:: If GODOT4 env var is set, prefer it
if not "%GODOT4%"=="" (
  set "GODOT_EXE=%GODOT4%"
  goto :_found
)

:: If a local path file exists, use it (first non-empty line)
set "PATH_FILE=%~dp0godot-path.txt"
if exist "%PATH_FILE%" (
  for /f "usebackq tokens=* delims=" %%L in ("%PATH_FILE%") do (
    if not "%%~L"=="" (
      rem If it's a directory, look for exe within
      if exist "%%~L\" (
        for %%G in ("%%~L\Godot_v4*.exe" "%%~L\Godot*.exe") do (
          if exist "%%~G" (
            set "GODOT_EXE=%%~G"
            goto :_found
          )
        )
      ) else if exist "%%~L" (
        set "GODOT_EXE=%%~L"
        goto :_found
      )
    )
  )
)

:: Try common install locations
set "SEARCH_ROOTS=%LocalAppData%\Programs\Godot;C:\Program Files\Godot;C:\Godot"
for %%R in (%SEARCH_ROOTS%) do (
  if exist "%%~R" (
    for /r "%%~R" %%G in (Godot_v4*.exe) do (
  set "GODOT_EXE=%%~G"
  goto :_found
    )
  )
)

:: Also try common portable root folders like C:\Godot_v4.4.1-*
for /d %%D in ("C:\Godot*") do (
  if exist "%%~D" (
    for %%G in ("%%~D\Godot_v4*.exe") do (
      if exist "%%~G" (
        set "GODOT_EXE=%%~G"
        goto :_found
      )
    )
  )
)

:: Try on PATH (winget installs usually alias godot4)
where godot4 >nul 2>nul
if %errorlevel%==0 (
  for /f "usebackq delims=" %%G in (`where godot4`) do (
    set "GODOT_EXE=%%~G"
    goto :_found
  )
)

:: Fallback: try generic godot
where godot >nul 2>nul
if %errorlevel%==0 (
  for /f "usebackq delims=" %%G in (`where godot`) do (
    set "GODOT_EXE=%%~G"
    goto :_found
  )
)

:: Not found
set "GODOT_EXE="
endlocal & set "GODOT_EXE="
exit /b 1

:_found
set "__FOUND__=!GODOT_EXE!"
endlocal & set "GODOT_EXE=%__FOUND__%" & set "__FOUND__="
exit /b 0
