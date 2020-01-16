@echo off

rem ----------------------------------------------------------------------------
rem
rem run_bench_image.bat: Create a project specific docker image based on Ubuntu.
rem
rem ----------------------------------------------------------------------------

setlocal EnableDelayedExpansion

set REPOSITORY=ora_bench_dev

echo.
echo Skript %0 is now running
echo.
echo You can find the run log in the file run_bench_image.log
echo.
echo Please wait ...
echo.

> run_bench_image.log 2>&1 (

    echo =======================================================================
    echo Start %0
    echo -----------------------------------------------------------------------
    echo Create the docker image %REPOSITORY%
    echo -----------------------------------------------------------------------
    echo:| TIME
    echo =======================================================================

    rem rmdir /Q/S tmp\%REPOSITORY%

    docker stop %REPOSITORY%
    docker rm -f %REPOSITORY%

    docker build -t %REPOSITORY% priv\docker

    docker tag %REPOSITORY% konnexionsgmbh/%REPOSITORY%

    docker push konnexionsgmbh/%REPOSITORY%

    for /F %%I in ('docker images -q -f "dangling=true" -f "label=autodelete=true"') do (docker rmi -f %%I)

    docker create --name %REPOSITORY% -i -v //D/SoftDevelopment/DockerData/%REPOSITORY%:/data konnexionsgmbh/%REPOSITORY%

    echo -----------------------------------------------------------------------
    echo:| TIME
    echo -----------------------------------------------------------------------
    echo End   %0
    echo =======================================================================
)
