@echo off
REM Odin build script: mode argument (debug or release).

CALL config.bat

IF NOT EXIST %BUILD_DIR% mkdir %BUILD_DIR%
SET OUTDIR=%BUILD_DIR%\%1

IF "%1" == "debug" (

    IF NOT EXIST %OUTDIR% MKDIR %OUTDIR% 
    odin build %SRC_DIR% -out:%OUTDIR%\%APP_NAME%.exe -build-mode:exe -subsystem:console %BUILD_FLAGS% -debug

) ELSE IF "%1" == "release" (

    IF NOT EXIST %OUTDIR% MKDIR %OUTDIR% 
    odin build %SRC_DIR% -out:%OUTDIR%\%APP_NAME%.exe -build-mode:exe -subsystem:window %BUILD_FLAGS%

) ELSE (

    ECHO Error: Unknown build mode "%1". Use "debug" or "release".
    EXIT /B 1

)

IF %ERRORLEVEL% NEQ 0 (
    ECHO.
    ECHO Odin build failed.
    EXIT /B %ERRORLEVEL%
)

ECHO.
ECHO Build successful!

ECHO Copying resource files to %OUTDIR%\%RES_DIR%\...
IF NOT EXIST %OUTDIR% MKDIR %OUTDIR%\%RES_DIR%\
XCOPY %RES_DIR% %OUTDIR%\%RES_DIR%\ /E /Y /S /Q

ECHO.
ECHO Done.