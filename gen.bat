@echo off

SET BUILD_MODE=%1
IF NOT "%BUILD_MODE%" == "debug" IF NOT "%BUILD_MODE%" == "release" (
    ECHO Error: Unknown run mode "%BUILD_MODE%". Use "debug" or "release".
    EXIT /B 1
)

CALL config.bat

SET CURRENT_DIR=%~dp0

IF "%GEN_DIR%" == "" (
    ECHO No code gen directory provided. Skipping.
    EXIT /B 0
)

IF NOT EXIST "%CURRENT_DIR%%GEN_DIR%" (
    ECHO No code gen directory "%GEN_DIR%" detected. Skipping.
    EXIT /B 0
)

ECHO Generating code. . .

SET DEBUG_FLAG=""
IF "%BUILD_MODE%" == "debug" SET DEBUG_FLAG="-debug"

odin run "%CURRENT_DIR%%GEN_DIR%" %DEBUG_FLAG%

IF %ERRORLEVEL% NEQ 0 (
    ECHO.
    ECHO Odin build failed for gen.
    EXIT /B %ERRORLEVEL%
)

ECHO . . . Done generating code.