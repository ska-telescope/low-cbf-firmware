@echo off


REM Run Regression testing
REM - run_regression


set HDL_BUILD_DIR=%RADIOHDL%\build_regression

python %RADIOHDL%\tools\radiohdl\base\modelsim_regression_test_vhdl.py -r -t lru