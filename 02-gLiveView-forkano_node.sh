#!/bin/bash 
source common_vars.sh

docker exec --user ${DOCKER_USER} -it ${CONTAINER_NAME} /home/forkano/git/forkano-babbage/node-mainnet/node-spo4/extra/gLiveView.sh