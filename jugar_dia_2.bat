@echo off
cd /d "%~dp0"
set "APPDATA=%~dp0build\qa-profile"
if not exist "build\qa-profile" mkdir "build\qa-profile"
if not exist "build\qa" mkdir "build\qa"
if not exist "build\tools\Godot_v4.7.2-stable_win64.exe" (
  echo Abre scenes/dias/dia_2/dia_2.tscn en Godot 4.7.2 y pulsa F6.
  pause
  exit /b 1
)
start "" "build\tools\Godot_v4.7.2-stable_win64.exe" --path . --log-file "%~dp0build\qa\dia2-local.log" "res://scenes/dias/dia_2/dia_2.tscn"
