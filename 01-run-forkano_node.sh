#!/bin/bash
source common_vars.sh

docker container stop ${CONTAINER_NAME}
docker container rm ${CONTAINER_NAME}

docker run --user ${DOCKER_USER} \
--name=${CONTAINER_NAME} ${VOLUME_INIT} ${VOLUME_DATA} \
-p ${PORT}:${PORT} \
-it forkano/forkano_node:latest