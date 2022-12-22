#!/bin/bash 
source common_vars.sh

docker exec --user ${DOCKER_USER} -it ${CONTAINER_NAME} tail -f /home/${USER}/git/forkano-babbage/node-mainnet/logs/node-spo4.log