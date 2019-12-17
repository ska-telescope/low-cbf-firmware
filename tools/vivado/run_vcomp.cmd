@echo off

REM Run this tool with at least the commandline arguments:
REM   run_vcomp toolset tool version design_name
REM example:
REM   run_vcomp xh_lru_es vivado 2018.1 gemini_xh_lru_test

IF "%1"=="" (
    echo "run_vcomp error: missing argument for toolset"
    exit /b
)

IF "%2"=="" (
    echo "run_vcomp error: missing argument for tool"
    exit /b
)

IF "%3"=="" (
    echo "run_vcomp error: missing argument for version"
    exit /b
)

setlocal

set TOOLSET=%1
set TOOL=%2
set VERSION=%3
set SCRIPT=%4

REM Add Vivado path
IF EXIST "%VIVADO_PATH%\%VERSION%\bin" SET PATH=%PATH%;"%VIVADO_PATH%\%VERSION%\bin"

IF NOT EXIST "%HDL_BUILD_DIR%\%TOOLSET%\%TOOL%\" MD "%HDL_BUILD_DIR%\%TOOLSET%\%TOOL%"
REM Change to build area
pushd %HDL_BUILD_DIR%\%TOOLSET%\%TOOL%\

call vivado.bat -mode tcl -source "%SCRIPT%"

popd