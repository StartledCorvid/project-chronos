@echo off

<<<<<<< Updated upstream
set OUTDIR=builds\%1

IF "%1" == "debug" (
	START /D %OUTDIR% %OUTDIR%\Chronos.exe
) ELSE IF "%1" == "release" (
	START /D %OUTDIR% %OUTDIR%\Chronos.exe
) ELSE (
    ECHO Error: Unknown run mode "%1". Use "debug" or "release".
    EXIT /B 1
)
=======
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
>>>>>>> Stashed changes
