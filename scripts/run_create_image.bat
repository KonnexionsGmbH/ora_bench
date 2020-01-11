@echo off

rem ----------------------------------------------------------------------------
rem
rem run_create_image.bat: Create a specific project based on Ubuntu.
rem
rem ----------------------------------------------------------------------------

setlocal EnableDelayedExpansion

set DOCKER_HUB_PUSH_DEFAULT=no

if "%1"=="" (
    set /P DOCKER_HUB_PUSH="Push image to Docker Hub (yes / no) [default: %DOCKER_HUB_PUSH_DEFAULT%] "
) else (
    set DOCKER_HUB_PUSH=%1
)

set REPOSITORY=ora_bench_dev
if ["%DOCKER_HUB_PUSH%"] EQU [""] (
    set DOCKER_HUB_PUSH=%DOCKER_HUB_PUSH_DEFAULT%
)

echo.
echo Skript %0 is now running
echo.
echo You can find the run log in the file run_create_image.log
echo.
echo Please wait ...
echo.

> run_create_image.log 2>&1 (

    echo =======================================================================
    echo Start %0
    echo -----------------------------------------------------------------------

    echo Create an image for project %REPOSITORY%

    echo -----------------------------------------------------------------------
    echo:| TIME
    echo =======================================================================

    rem rmdir /Q/S tmp\%REPOSITORY%

    copy priv\docker\dockerfile tmp

    docker stop %REPOSITORY%
    docker rm -f %REPOSITORY%
    docker rmi -f %REPOSITORY%

    docker build -t %REPOSITORY% tmp

    docker tag %REPOSITORY% konnexionsgmbh/%REPOSITORY%

    if ["%DOCKER_HUB_PUSH%"] EQU ["yes"]  (
        docker push konnexionsgmbh/%REPOSITORY%
    )

    for /F %%I in ('docker images -q -f "dangling=true" -f "label=autodelete=true"') do (docker rmi -f %%I)

    docker create --name %REPOSITORY% -i -v //D/SoftDevelopment/DockerData/%REPOSITORY%:/data konnexionsgmbh/%REPOSITORY%

    echo -----------------------------------------------------------------------
    echo:| TIME
    echo -----------------------------------------------------------------------
    echo End   %0
    echo =======================================================================
)
