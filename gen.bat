@echo off

IF "%1" == "debug" (
    odin run gen -debug
) ELSE IF "%1" == "release" (
    odin run gen
) ELSE (
    ECHO Error: Unknown build mode "%1". Use "debug" or "release".
    EXIT /B 1
)

IF %ERRORLEVEL% NEQ 0 (
    ECHO.
    ECHO Odin build failed for gen.
    EXIT /B %ERRORLEVEL%
)