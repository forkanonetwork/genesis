#!/bin/bash
source common_vars.sh

docker container stop ${CONTAINER_NAME}
docker container rm ${CONTAINER_NAME}

docker run --user ${DOCKER_USER} -d --restart unless-stopped \
--name=${CONTAINER_NAME} ${VOLUME_INIT} ${VOLUME_DATA} \
-p ${PORT}:${PORT} \
-it forkano/forkano_node:latest bash -c ' cd ~/git/forkano-babbage/node-mainnet ; ./node-spo4.sh '