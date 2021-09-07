@echo off

set "CURRENT_PATH=%~dp0"
set "CURRENT_VERSION=%~1"
if [%CURRENT_VERSION%] == [] (
    set CURRENT_VERSION=0.0.0000
)

echo Preparing dist directory.
IF NOT EXIST "%CURRENT_PATH%\dist" MD "%CURRENT_PATH%\dist"
del /Q /F /S "%CURRENT_PATH%\dist\*.*"

echo Generating documentation html file.
pip install docutils
start /wait /b rst2html.py "%CURRENT_PATH%/Readme.rst" "%CURRENT_PATH%\dist\readme.html"

if not "%errorlevel%" == "0" (
    echo Failed to generate documentation!
    goto error_exit
)

echo Preparing configuration files.
echo %CURRENT_VERSION% > %CURRENT_PATH%\package\version

rem This file is created by the script to avoid read-only flag impacting cleanup.
echo include readme.txt > %CURRENT_PATH%\package\MANIFEST.in
echo include version >> %CURRENT_PATH%\package\MANIFEST.in
echo include cfrpos/features/*.feature >> %CURRENT_PATH%\package\MANIFEST.in
echo include cfrpos/features/*/*.feature >> %CURRENT_PATH%\package\MANIFEST.in
echo include cfrpos/testSuites/*.txt >> %CURRENT_PATH%\package\MANIFEST.in

echo Creating python package from pcspos.
cd %CURRENT_PATH%\package
python setup.py sdist --formats=zip "--dist-dir=%CURRENT_PATH%\dist"

if not "%errorlevel%" == "0" (
    echo Failed to package pcspos!
    goto error_exit
)

cd %CURRENT_PATH%

echo Packaging bdd tests to zip archive.
python "%CURRENT_PATH%\package_additional_data.py"

if not "%errorlevel%" == "0" (
     echo Failed to package bdd tests!
     goto error_exit
)

echo POS BDD solution has been built successfully.

goto exit

:error_exit
echo Building POS BDD scripts failed!
exit /b 1

:exit
