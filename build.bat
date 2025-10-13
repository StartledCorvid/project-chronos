@echo off
REM Odin build script: mode argument (debug or release).

SET BUILD_MODE=%1
IF NOT "%BUILD_MODE%" == "debug" IF NOT "%BUILD_MODE%" == "release" (
    ECHO Error: Unknown run mode "%BUILD_MODE%". Use "debug" or "release".
    EXIT /B 1
)

CALL config.bat

SET CURRENT_DIR=%~dp0

SET BUILD_ROOT=%CURRENT_DIR%%BUILD_DIR_NAME%
IF NOT EXIST "%BUILD_ROOT%" mkdir "%BUILD_ROOT%"

SET BUILD_DIR=%BUILD_ROOT%\%BUILD_MODE%
IF NOT EXIST "%BUILD_DIR%" MKDIR "%BUILD_DIR%"

SET DEBUG_FLAG=""
IF "%BUILD_MODE%" == "debug" SET DEBUG_FLAG="-debug"

CALL "%CURRENT_DIR%%GEN_SCRIPT%" %BUILD_MODE%
odin build "%CURRENT_DIR%%SRC_DIR%" -out:"%BUILD_DIR%\%APP_NAME%.exe" -build-mode:exe -subsystem:console %BUILD_FLAGS% %DEBUG_FLAG%

IF %ERRORLEVEL% NEQ 0 (
    ECHO.
    ECHO "Odin build failed."
    EXIT /B %ERRORLEVEL%
)

ECHO.
ECHO Build successful!
ECHO Copying resource files to %BUILD_DIR%\%RES_DIR%...

IF NOT EXIST "%BUILD_DIR%\%RES_DIR%" MKDIR "%BUILD_DIR%\%RES_DIR%"
XCOPY "%CURRENT_DIR%\%RES_DIR%" "%BUILD_DIR%\%RES_DIR%" /E /Y /S /Q

ECHO.
ECHO Done.
