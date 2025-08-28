@echo off
REM Odin build script: mode argument (debug or release).

IF NOT EXIST builds mkdir builds
set OUTDIR=builds\%1

IF "%1" == "debug" (
    IF NOT EXIST %OUTDIR% MKDIR %OUTDIR% 
    odin build src -debug -out:%OUTDIR%\Chronos.exe -build-mode:exe -show-timings -subsystem:console -strict-style -vet-unused -vet-style -vet-semicolon
) ELSE IF "%1" == "release" (
    IF NOT EXIST %OUTDIR% MKDIR %OUTDIR% 
    odin build src -out:%OUTDIR%\Chronos.exe -build-mode:exe -show-timings -subsystem:window -strict-style -vet-unused -vet-style -vet-semicolon
) ELSE (
    ECHO Error: Unknown build mode "%1". Use "debug" or "release".
    EXIT /B 1
)

REM Copy bin contents to output directory.
ECHO Copying binary files to %OUTDIR%...
XCOPY bin %OUTDIR%\ /E /Y

ECHO Copying resource files to %OUTDIR%\res\...
IF NOT EXIST %OUTDIR% MKDIR %OUTDIR%\res\
XCOPY res %OUTDIR%\res\ /E /Y /S /Q