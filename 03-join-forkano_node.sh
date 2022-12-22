#!/bin/bash
source common_vars.sh

docker exec --user ${DOCKER_USER} -it ${CONTAINER_NAME} bash