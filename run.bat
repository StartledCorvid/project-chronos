@echo off

set OUTDIR=builds\%1

IF "%1" == "debug" (
	START /D %OUTDIR% %OUTDIR%\Chronos.exe
) ELSE IF "%1" == "release" (
	START /D %OUTDIR% %OUTDIR%\Chronos.exe
) ELSE (
    ECHO Error: Unknown run mode "%1". Use "debug" or "release".
    EXIT /B 1
)