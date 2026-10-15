@echo off
if "%~1"=="" (
 echo Drag Godot.exe onto this file, or import project.godot in Godot.
 pause
 exit /b
)
"%~1" --editor --path "%~dp0"
