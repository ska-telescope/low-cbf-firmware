@echo off


REM General tool and project settings
REM - run_modelsim lru


IF "%1"=="" (
    echo "run_modelsim error: missing argument for toolset"
    exit /b
)

set TOOLSET=%1
for /f "tokens=1,3" %%a in (%RADIOHDL%\tools\hdltool_%TOOLSET%.cfg) do (

  if %%a==tool_version_sim set MODELSIM_VERSION=%%b
)



set MODEL_TECH_DIR=%MODELSIM_PATH%\%MODELSIM_VERSION%\modeltech
set VSIM_DIR=%MODEL_TECH_DIR%\win32pe

echo %VSIM_DIR%

if "%2"=="" (
  %VSIM_DIR%\vsim -do %RADIOHDL%\tools\modelsim\commands.do
) else (
  %VSIM_DIR%\vsim -c -do %2
)
