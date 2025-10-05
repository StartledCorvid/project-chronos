@echo off
REM Script to run a built version of the project: mode argument (debug or release).

CALL config.bat

set OUTDIR=%BUILD_DIR%\%1

IF "%1" == "debug" (
	START /D %OUTDIR% %OUTDIR%\%APP_NAME%.exe
) ELSE IF "%1" == "release" (
	START /D %OUTDIR% %OUTDIR%\%APP_NAME%.exe
) ELSE (
    ECHO Error: Unknown run mode "%1". Use "debug" or "release".
    EXIT /B 1
)