#!/bin/bash

exec &> >(tee -i run_create_image_ora_bench_dev.log)
sleep .1

# ------------------------------------------------------------------------------
#
# run_create_image_ora_bench_dev.sh: Create a project specific docker image based on Ubuntu.
#
# ------------------------------------------------------------------------------

export REPOSITORY=ora_bench_dev

echo "================================================================================"
echo "Start $0"
echo "--------------------------------------------------------------------------------"
echo "Create the docker image $REPOSITORY"
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "================================================================================"

EXITCODE="0"

docker stop $REPOSITORY
docker rm -f $REPOSITORY

docker build -t $REPOSITORY docker

docker tag $REPOSITORY konnexionsgmbh/$REPOSITORY

docker push konnexionsgmbh/$REPOSITORY

for IMAGE in $(docker images -q -f "dangling=true" -f "label=autodelete=true")
do
    docker rmi -f $IMAGE
done

EXITCODE=$?

echo ""
echo "--------------------------------------------------------------------------------"
date +"DATE TIME : %d.%m.%Y %H:%M:%S"
echo "--------------------------------------------------------------------------------"
echo "End   $0"
echo "================================================================================"

exit $EXITCODE
