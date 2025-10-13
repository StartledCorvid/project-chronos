@echo off
REM Script to run a built version of the project: mode argument (debug or release).

SET BUILD_MODE=%1
IF NOT "%BUILD_MODE%" == "debug" IF NOT "%BUILD_MODE%" == "release" (
    ECHO Error: Unknown run mode "%BUILD_MODE%". Use "debug" or "release".
    EXIT /B 1
)

CALL config.bat

SET CURRENT_DIR=%~dp0
SET BUILD_DIR=%CURRENT_DIR%%BUILD_DIR_NAME%\%BUILD_MODE%

ECHO Starting application from: %BUILD_DIR%
START "%APP_NAME% - %BUILD_MODE%" /D "%BUILD_DIR%" "%BUILD_DIR%\%APP_NAME%.exe"
